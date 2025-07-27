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
    
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Recipe.self,
            Ingredient.self,
            Instruction.self,
            Tag.self,
            MealPlanEntry.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema, 
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, try to delete the app data and recreate
            print("Failed to create ModelContainer: \(error)")
            
            // Try to delete the app's data directory to clear corrupted data
            do {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
                
                if let documentsPath = documentsPath {
                    try? FileManager.default.removeItem(at: documentsPath)
                    print("Deleted documents directory")
                }
                
                if let libraryPath = libraryPath {
                    try? FileManager.default.removeItem(at: libraryPath)
                    print("Deleted library directory")
                }
                
                // Try to create the container again
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                print("Failed to recreate ModelContainer: \(error)")
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
    
    private var mealieAPIService = MealieAPIService(serverURL: nil)
    private var authState: AuthenticationState
    
    init() {
        self.authState = AuthenticationState(mealieAPIService: mealieAPIService)
    }

    var body: some Scene {
        
        WindowGroup {
            ContentView(mealieAPIService: self.mealieAPIService, authState: authState)
        }
        .modelContainer(sharedModelContainer)
    }
}
