import AVFoundation
import UIKit
import MLKitVision
import MLKitBarcodeScanning

protocol CameraManagerDelegate: AnyObject {
    func didDetect(code: String)
}

class CameraManager: NSObject {
    weak var delegate: CameraManagerDelegate?
    var onStatusChange: ((String) -> Void)?
    
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.smartpantry.cameraQueue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isProcessing = false
    
    override init() {
        super.init()
    }
    
    private func log(_ message: String) {
        print("📸 CameraManager: \(message)")
        DispatchQueue.main.async {
            self.onStatusChange?(message)
        }
    }
    
    func checkPermissions() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        log("Permission status: \(status.rawValue)")
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            log("Requesting permission...")
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            log("Permission granted: \(granted)")
            return granted
        default:
            log("Permission denied or restricted")
            return false
        }
    }
    
    func setupSession() {
        log("Setting up session...")
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            
            // Add Input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                self.log("❌ No video device found")
                self.session.commitConfiguration()
                return
            }
            
            // Configure Auto Focus
            do {
                try videoDevice.lockForConfiguration()
                if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                    videoDevice.focusMode = .continuousAutoFocus
                }
                videoDevice.unlockForConfiguration()
            } catch {
                self.log("⚠️ Could not lock device: \(error.localizedDescription)")
            }
            
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoDeviceInput) else {
                self.log("❌ Could not add video input")
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(videoDeviceInput)
            
            // Add Output
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
                
                self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.smartpantry.videoQueue"))
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.log("✅ Video Output Added")
            } else {
                self.log("❌ Could not add video output")
            }
            
            self.session.commitConfiguration()
            self.log("Session configuration committed")
        }
    }
    
    func startSession() {
        log("Starting session...")
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                self.log("Session is running")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // FIX: Remove manual 'isProcessing' check to allow MLKit to handle throughput or handle it thread-safely
        // if needed. For now, trusting MLKit async processing.
        
        let visionImage = VisionImage(buffer: sampleBuffer)
        var deviceOrientation: UIDeviceOrientation = .unknown
        
        // Sync access to MainActor property
        DispatchQueue.main.sync {
            deviceOrientation = UIDevice.current.orientation
        }
        visionImage.orientation = imageOrientation(deviceOrientation: deviceOrientation, cameraPosition: .back)
        
        let barcodeOptions = BarcodeScannerOptions(formats: .all)
        let barcodeScanner = BarcodeScanner.barcodeScanner(options: barcodeOptions)
        
        barcodeScanner.process(visionImage) { [weak self] barcodes, error in
            guard let self = self else { return }
            
            if error != nil {
                return
            }
            
            guard let barcodes = barcodes, !barcodes.isEmpty else { return }
            
            if let barcode = barcodes.first, let rawValue = barcode.rawValue {
                // Dispatch to Main Actor for UI updates (delegate)
                DispatchQueue.main.async {
                    // Vibrate
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    self.delegate?.didDetect(code: rawValue)
                }
            }
        }
    }
    
    private nonisolated func imageOrientation(deviceOrientation: UIDeviceOrientation, cameraPosition: AVCaptureDevice.Position) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return cameraPosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return cameraPosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return cameraPosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return cameraPosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .right
        @unknown default:
            return .right
        }
    }
}
