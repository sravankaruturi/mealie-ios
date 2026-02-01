import Foundation
import os

struct AppLogger {

    // MARK: - Categories

    enum Category: String {
        case network = "Network"
        case auth = "Auth"
        case sync = "Sync"
        case recipes = "Recipes"
        case ui = "UI"
        case general = "General"
    }

    // MARK: - Private Loggers

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.sravan.mealie-ios"

    private static let loggers: [Category: Logger] = {
        var map = [Category: Logger]()
        for category in [Category.network, .auth, .sync, .recipes, .ui, .general] {
            map[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
        return map
    }()

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
    static func info(_ category: Category, _ message: String) {
        logger(for: category).info("\(message, privacy: .public)")
    }

    /// Warning-level logging — recoverable issues, fallback behavior.
    static func warning(_ category: Category, _ message: String) {
        logger(for: category).warning("\(message, privacy: .public)")
    }

    /// Error-level logging — failures, exceptions, data loss risks.
    static func error(_ category: Category, _ message: String) {
        logger(for: category).error("\(message, privacy: .public)")
    }

    // MARK: - Backward Compatibility

    /// Legacy warning method — prefer `warning(_ category:, _ message:)` instead.
    static func warning(_ message: String) {
        warning(.general, message)
    }

    // MARK: - Specialized Helpers

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
