import Foundation
import os

/// Centralized logging wrapper around `os.Logger`, providing categorized, leveled logging
/// that integrates with Console.app. Debug-level logs are compiled out in release builds.
struct AppLogger {

    // MARK: - Categories

    /// Log categories corresponding to app subsystems, each backed by its own `os.Logger` instance.
    enum Category: String {
        case network = "Network"
        case auth = "Auth"
        case sync = "Sync"
        case recipes = "Recipes"
        case ui = "UI"
        case general = "General"
    }

    // MARK: - Private Loggers

    /// The app's bundle identifier used as the `os.Logger` subsystem.
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.sravan.mealie-ios"

    /// Pre-built logger instances keyed by category for efficient lookup.
    private static let loggers: [Category: Logger] = {
        var map = [Category: Logger]()
        for category in [Category.network, .auth, .sync, .recipes, .ui, .general] {
            map[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
        return map
    }()

    /// Returns the `os.Logger` instance for the given category.
    private static func logger(for category: Category) -> Logger {
        loggers[category]!
    }

    // MARK: - Log Levels

    /// Debug-level logging — only active in DEBUG builds.
    /// Use for verbose development info (parameter dumps, function tracing).
    static func debug(_ category: Category, _ message: String) {
        #if DEBUG
        logger(for: category).debug("\(message, privacy: .public)")
        #endif
    }

    /// Info-level logging — status updates, sync stats, successful operations.
    /// Messages are redacted by default on real devices; use Console with a debug profile to view.
    static func info(_ category: Category, _ message: String) {
        logger(for: category).info("\(message, privacy: .private)")
    }

    /// Warning-level logging — recoverable issues, fallback behavior.
    /// Messages are redacted by default on real devices; use Console with a debug profile to view.
    static func warning(_ category: Category, _ message: String) {
        logger(for: category).warning("\(message, privacy: .private)")
    }

    /// Error-level logging — failures, exceptions, data loss risks.
    /// Messages are redacted by default on real devices; use Console with a debug profile to view.
    static func error(_ category: Category, _ message: String) {
        logger(for: category).error("\(message, privacy: .private)")
    }

    // MARK: - Backward Compatibility

    /// Legacy warning method — prefer `warning(_ category:, _ message:)` instead.
    static func warning(_ message: String) {
        warning(.general, message)
    }

    // MARK: - Specialized Helpers

    /// Logs a detailed summary of recipes (names, ingredient/instruction counts). Debug builds only.
    #if DEBUG
    static func logRecipes(_ recipes: [Recipe], context: String) {
        let logger = logger(for: .recipes)
        logger.debug("LOG: \(context, privacy: .public)")
        logger.debug("    Total Recipes: \(recipes.count, privacy: .public)")
        for recipe in recipes {
            logger.debug("    - '\(recipe.name ?? "Untitled", privacy: .public)': \(recipe.ingredients.count) ingredients, \(recipe.instructions.count) instructions.")
        }
    }
    #endif
}
