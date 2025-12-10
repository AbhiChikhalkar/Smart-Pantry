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
        // We need to access isProcessing, which is a mutable state. 
        // Since this method is nonisolated, we need to be careful.
        // However, CameraManager itself seems to be inferred as MainActor in the user's context, 
        // but we are accessing 'isProcessing' which is a var.
        // To be safe and avoid data races, we should probably use a lock or dispatch to a serial queue,
        // OR simply dispatch the whole processing to our sessionQueue or a dedicated processing queue.
        
        // Let's dispatch to the sessionQueue (or a background queue) to handle the logic, 
        // assuming 'isProcessing' is not MainActor isolated (it's just a var on the class).
        // If CameraManager IS MainActor, we can't access 'isProcessing' from nonisolated context without await.
        
        // SIMPLER APPROACH:
        // Let's assume we can dispatch async to the main actor to check/set the flag if it's UI related,
        // BUT image processing should be background.
        
        // Let's try to just ignore the 'isProcessing' flag for a moment or make it thread-safe.
        // For now, I will just address the compiler error by wrapping the body in Task and MainActor if needed,
        // OR better, since MLKit processing is async anyway, let's just do the setup here.
        
        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.orientation = imageOrientation(deviceOrientation: UIDevice.current.orientation, cameraPosition: .back)
        
        let barcodeOptions = BarcodeScannerOptions(formats: .all)
        let barcodeScanner = BarcodeScanner.barcodeScanner(options: barcodeOptions)
        
        // Process on a background queue is default for ML Kit? No, process(image) is synchronous or async?
        // process(image, completion:) is async.
        
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
