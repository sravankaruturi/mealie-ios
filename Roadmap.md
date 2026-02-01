# Gourmet (Mealie iOS) - Roadmap

A comprehensive list of planned improvements and features for the app.

---

## High Priority - Stability & Security

- [x] **H1: Fix Silent Failures** - Replace `try?` with proper error handling to prevent data loss without user awareness
  - `RecipeCardView.swift` (lines 90, 123)
  - `RecipeListView.swift` (line 163)
  - `EditRecipeViewModel.swift` (line 327)

- [x] **H2: Remove Force Unwraps** - Replace `!` with safe optional handling to prevent crashes
  - `MealieAPIService.swift` (lines 48, 59, 109)
  - `RecipeListView.swift` (line 179)

- [x] **H3: Secure Server URL Storage** - Move server URL from UserDefaults to Keychain (currently stored unencrypted)
  - `KeychainService.swift`

- [x] **H4: Token Refresh Logic** - Handle expired tokens gracefully instead of forcing logout
  - `AuthenticationMiddleware` - detects 401 and posts notification
  - `AuthenticationState.swift` - handles session expiration

- [x] **H5: Add Logout Confirmation** - Prevent accidental logouts with a confirmation dialog
  - `ProfileView.swift`

---

## Medium Priority - Architecture & Performance

- [x] **M1: Fix N+1 Query Problem** - Make `fetchAllRecipesOptimized()` the default; current implementation makes N+1 API calls
  - `MealieAPIService.swift`
  - `RecipesViewModel.swift`

- [x] **M2: Replace Print Statements with Proper Logging** - Replace 129 `print()` calls with structured logging using os.Logger
  - All service and view model files

- [ ] **M3: Offline Support** - Implement offline-first architecture with local mutation queue and background sync
  - New: `SyncManager.swift`
  - `RecipesViewModel.swift`
  - `MealPlanViewModel.swift`

- [x] **M4: Consolidate Date Parsing** - Unify multiple overlapping date parsing methods into a single utility
  - `MealieAPIService.swift` (lines 207-238)
  - `DateParser.swift`

- [ ] **M5: Extract Reusable Components** - Create shared views for duplicated rendering logic
  - New: `IngredientListView.swift`
  - New: `InstructionListView.swift`
  - `RecipeDetailView.swift`
  - `RecipeCardView.swift`

---

## Features - New Functionality

- [ ] **F1: Complete Meal Planning** - Full calendar UI with add/edit/delete entries, week/month views
  - `MealPlanView.swift`
  - `MealPlanViewModel.swift`

- [ ] **F2: Recipe Filtering** - Filter by tags, ingredients, cook time; add sorting options
  - `RecipeListView.swift`
  - `RecipesViewModel.swift`

- [ ] **F3: Recipe Scaling** - Adjust serving size and auto-scale ingredient quantities
  - `RecipeDetailView.swift`

- [ ] **F4: Nutrition Display** - Show calories and macros (data model exists, needs UI)
  - New: `NutritionView.swift`
  - `RecipeDetailView.swift`

- [ ] **F5: Shopping List** - Generate shopping lists from recipes with check-off functionality
  - New: `ShoppingListView.swift`
  - New: `ShoppingListViewModel.swift`
  - New: `ShoppingItem.swift` model

- [ ] **F6: Empty States** - Helpful messages and guidance when lists are empty
  - `RecipeListView.swift`
  - `MealPlanView.swift`

---

## Polish - UX & Accessibility

- [ ] **P1: Loading State Indicators** - Add spinners/progress indicators to async operations
  - `RecipeListView.swift` (sync button)
  - `RecipeCardView.swift` (favorite toggle)
  - `EditRecipeViewModel.swift` (save operations)

- [ ] **P2: Better Error Messages** - Replace generic errors with actionable, user-friendly guidance
  - `MealieAPIServiceProtocol.swift`
  - All views displaying errors

- [ ] **P3: VoiceOver Support** - Add accessibility labels and hints to all interactive elements
  - `RecipeCardView.swift`
  - `RecipeListView.swift`
  - `RecipeDetailView.swift`
  - All button and image elements

- [ ] **P4: Haptic Feedback** - Add tactile feedback for user actions (favorites, saves, deletes)
  - `RecipeCardView.swift`
  - `EditRecipeViewModel.swift`

- [ ] **P5: Keyboard Flow** - Proper return key behavior, focus ordering, and dismissal in forms
  - `LoginView.swift`
  - `ImportRecipeFromURLView.swift`
  - All form views

---

## Testing - Quality Assurance

- [ ] **T1: Service Tests** - Add comprehensive unit tests for API and authentication services
  - New: `MealieAPIServiceTests.swift`
  - New: `AuthenticationServiceTests.swift`
  - New: `KeychainServiceTests.swift`

- [ ] **T2: ViewModel Tests** - Add unit tests for all view models
  - New: `RecipesViewModelTests.swift`
  - New: `EditRecipeViewModelTests.swift`
  - New: `MealPlanViewModelTests.swift`
  - New: `AuthenticationStateTests.swift`

- [ ] **T3: Error Path Tests** - Test network failures, authentication errors, and data corruption scenarios
  - Extend existing test files

- [ ] **T4: Comprehensive Mocks** - Expand mock data factory with edge cases and various recipe types
  - `MockMealieAPIService.swift`
  - New: `MockDataFactory.swift`

---

## Legend

| Priority | Description |
|----------|-------------|
| **H** | High - Security & stability issues that could cause crashes or data loss |
| **M** | Medium - Architecture and performance improvements |
| **F** | Feature - New functionality |
| **P** | Polish - UX and accessibility enhancements |
| **T** | Testing - Quality assurance improvements |

---

Last updated: January 2026
