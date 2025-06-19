//
//  mealieApp.swift
//  mealie
//
//  Created by Sravan Karuturi on 6/14/25.
//

import SwiftUI
import SwiftData

@main
struct mealieApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Recipe.self,
            Ingredient.self,
            Instruction.self,
            Tag.self,
            MealPlanEntry.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
