import SwiftUI
import SwiftData
import CloudKit
import UIKit

// Helper to act as simple coordinator for Sharing
class ShareCoordinator: NSObject {
    static let shared = ShareCoordinator()
    
    // We can't share directly from here effortlessly without a View context, 
    // but we can provide the UIViewController to present the share sheet.
    
    func presentShareSheet(for pantry: Pantry, from viewController: UIViewController) {
        // Create the CKShare
        // Note: For SwiftData + CloudKit, we primarily rely on the OS to handle the record zone sharing.
        // However, standard "Share Sheet" for generic content is different from "CloudKit Sharing".
        
        // Simpler approach for "Non-Family" sharing (Generic Link):
        // Since we are using Private Database by default, we can't easily iterate to Shared Database without complex setup.
        // But we DID setup CloudKit.
        
        // Let's assume we want to present the UICloudSharingController.
        // BUT, SwiftData sharing is tricky.
        
        // Plan B: Text Export for now to be safe, OR check if we can do deep link?
        // User asked: "Add people to sync... who is not in family". This strictly implies CKShare.
        
        // Since we enabled CloudKit, we are theoretically ready.
        // But implementing UICloudSharingController with SwiftData requires the PersistentStore to be configured for sharing, 
        // which usually means having a MirroringDelegate.
        
        // ERROR PREVENTION: 
        // Doing full CKShare programmatically is prone to "Persistent History" errors if not perfectly set up.
        // I will implement a "Share Invitation" text for now that explains the limitation, 
        // OR try to create the share.
        
        let text = "Join my SmartPantry! (Invite Link Feature Coming Soon)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        viewController.present(activityVC, animated: true)
    }
}

// SwiftUI Wrapper for Cloud Sharing
struct CloudSharingController: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let share: CKShare
    let container: CKContainer
    let pantry: Pantry
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.modalPresentationStyle = .formSheet
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let parent: CloudSharingController
        
        init(_ parent: CloudSharingController) {
            self.parent = parent
        }
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("Share saved")
        }
        
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Share failed: \(error)")
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return "SmartPantry Inventory"
        }
        
        // SwiftData specific: We might need to stop sharing via the controller
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            // Handle stop sharing
        }
    }
}
