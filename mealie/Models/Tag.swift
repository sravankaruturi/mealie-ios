import Foundation
import SwiftData

@Model
final class Tag {
    @Attribute(.unique) var name: String
    // By removing the @Relationship macro here, we simplify the many-to-many relationship definition.
    // SwiftData will infer the inverse relationship from the 'tags' property in the Recipe model.
    var recipes: [Recipe] = []
    
    init(name: String) {
        self.name = name
    }
    
    // Default initializer for SwiftData
    init() {
        self.name = ""
    }
}
