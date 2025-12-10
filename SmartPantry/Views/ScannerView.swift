import SwiftUI
import AVFoundation

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: ScannerView
        
        init(_ parent: ScannerView) {
            self.parent = parent
        }
        
        func didDetect(code: String) {
            parent.scannedCode = code
            parent.dismiss()
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didDetect(code: String)
}

class ScannerViewController: UIViewController, CameraManagerDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    
    private let cameraManager = CameraManager()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        cameraManager.delegate = self
        
        // Setup Status Label
        setupStatusLabel()
        
        // Hook up logging
        cameraManager.onStatusChange = { [weak self] status in
            self?.statusLabel.text = status
            print("Scanner Status: \(status)")
        }
        
        setupPreviewLayer()
        setupOverlay()
        
        Task {
            if await cameraManager.checkPermissions() {
                cameraManager.setupSession()
                cameraManager.startSession()
            } else {
                cameraManager.onStatusChange?("❌ Camera Permission Denied")
            }
        }
    }
    
    private func setupStatusLabel() {
        statusLabel.textColor = .yellow
        statusLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "Initializing..."
        view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        view.bringSubviewToFront(statusLabel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraManager.stopSession()
    }
    
    private func setupPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: cameraManager.session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        self.previewLayer = layer
    }
    
    private func setupOverlay() {
        let overlayView = UIView()
        overlayView.layer.borderColor = UIColor.green.cgColor
        overlayView.layer.borderWidth = 2
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            overlayView.widthAnchor.constraint(equalToConstant: 250),
            overlayView.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        let label = UILabel()
        label.text = "Align barcode within frame"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: overlayView.bottomAnchor, constant: 20),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func didDetect(code: String) {
        // Stop session immediately to prevent multiple scans
        cameraManager.stopSession()
        
        DispatchQueue.main.async {
            self.delegate?.didDetect(code: code)
        }
    }
}
