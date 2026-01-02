import Foundation
import SwiftData

@Model
final class Pantry {
    var title: String = "My Pantry"
    var ownerName: String = ""
    var createdDate: Date = Date()
    
    // Relationship to items. CloudKit requires relationships to be optional.
    @Relationship(deleteRule: .cascade, inverse: \Item.pantry)
    var items: [Item]? = []
    
    init(title: String = "My Pantry") {
        self.title = title
        self.createdDate = Date()
    }
}
