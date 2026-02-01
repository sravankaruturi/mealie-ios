//
//  mealieApp.swift
//  mealie
//
//  Created by Sravan Karuturi on 6/14/25.
//

import SwiftUI
import SwiftData

/// The main entry point for the Gourmet (Mealie) iOS application.
@main
struct mealieApp: App {

    /// The shared SwiftData model container for persistent recipe storage.
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
            AppLogger.error(.general, "Failed to create ModelContainer: \(error)")
            
            // Try to delete the app's data directory to clear corrupted data
            do {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
                
                if let documentsPath = documentsPath {
                    try? FileManager.default.removeItem(at: documentsPath)
                    AppLogger.warning(.general, "Deleted documents directory")
                }
                
                if let libraryPath = libraryPath {
                    try? FileManager.default.removeItem(at: libraryPath)
                    AppLogger.warning(.general, "Deleted library directory")
                }
                
                // Try to create the container again
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                AppLogger.error(.general, "Failed to recreate ModelContainer: \(error)")
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
    
    @State private var appState = AppState()
    
    var body: some Scene {
        
        WindowGroup {
            ContentView(mealieAPIService: appState.mealieAPIService, authState: appState.authState)
                .environment(appState.authState)
        }
        .modelContainer(sharedModelContainer)
    }
}

/// Observable root state object that owns the app's service and authentication dependencies.
@Observable
final class AppState {

    /// The API service used for all Mealie server communication.
    let mealieAPIService: MealieAPIServiceProtocol
    /// The service responsible for authenticating the user.
    let authService: AuthenticationServiceProtocol
    /// The observable authentication state shared across the app.
    let authState: AuthenticationState

    /// Initializes the service graph with default concrete implementations.
    init() {
        self.mealieAPIService = MealieAPIService(serverURL: nil)
        self.authService = AuthenticationService(mealieAPIService: mealieAPIService)
        self.authState = AuthenticationState(authService: authService)
    }

}
