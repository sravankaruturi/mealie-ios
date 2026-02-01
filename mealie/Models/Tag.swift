import Foundation
import SwiftData

/// A tag used to categorize recipes, stored in SwiftData with a unique name.
@Model
final class Tag {
    @Attribute(.unique) var name: String
    // By removing the @Relationship macro here, we simplify the many-to-many relationship definition.
    // SwiftData will infer the inverse relationship from the 'tags' property in the Recipe model.
    var recipes: [Recipe] = []
    
    /// Creates a tag with the given name.
    init(name: String) {
        self.name = name
    }
    
    /// Default initializer required by SwiftData.
    init() {
        self.name = ""
    }
}
