//
//  Item.swift
//  mealie
//
//  Created by Sravan Karuturi on 6/14/25.
//

import Foundation
import SwiftData

/// Default Xcode template model; retained for SwiftData schema compatibility.
@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
