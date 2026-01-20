# Gourmet - Mealie for iOS

A native iOS companion app for your self-hosted [Mealie](https://mealie.io/) server.

[![Download on the App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/us/app/gourmet-for-mealie/id6749816018)

## About the Project

Mealie is a self-hosted recipe manager web app. Gourmet (Mealie for iOS) makes it easy to browse and cook with the recipes from your Mealie instance, right from your iPhone.

## Features

- **Recipe Library** - Browse and search your entire recipe collection
- **Detailed Views** - View ingredients, instructions, cook times, and nutrition info
- **Import Recipes** - Add recipes from URLs with automatic parsing
- **Manual Entry** - Create and edit recipes directly on your phone
- **Favorites** - Mark recipes as favorites for quick access
- **Offline Support** - Recipes are cached locally for offline viewing
- **Secure** - Credentials stored securely in iOS Keychain

## Requirements

- iOS 18.5+
- A running Mealie server instance

## Getting Started

1. Download from the [App Store](https://apps.apple.com/us/app/gourmet-for-mealie/id6749816018)
2. Enter your Mealie server URL (e.g., `https://mealie.example.com`)
3. Log in with your Mealie credentials
4. Start cooking!

## Development

Built with modern Apple frameworks:
- **SwiftUI** - Declarative UI
- **SwiftData** - Local persistence
- **OpenAPI** - Auto-generated API client

### Building from Source

1. Clone the repository
2. Open `mealIO.xcodeproj` in Xcode
3. Build and run on simulator or device

See [Roadmap.md](Roadmap.md) for planned improvements and contribution opportunities.