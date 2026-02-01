# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Juan Tracker is a Flutter Android-first application for personal nutrition and workout tracking. It features food logging, weight tracking with trend analysis, workout sessions with voice input, OCR import for routines, and visual analytics. Uses an adaptive coach system based on TDEE calculations.

## Tech Stack

- **Flutter**: 3.10.7
- **State Management**: Riverpod 3 (`flutter_riverpod: ^3.0.0`)
- **Database**: Drift (SQLite) with code generation - Schema v11
- **UI**: Material Design with Google Fonts (Montserrat)
- **Navigation**: GoRouter (`go_router: ^14.6.3`)
- **HTTP**: Dio + http for Open Food Facts API
- **Key Libraries**: ML Kit (OCR), speech_to_text, fl_chart, table_calendar, flutter_local_notifications, mobile_scanner

## Project Structure

```
lib/
├── main.dart              # App entry point, initializes SharedPreferences
├── app.dart               # MaterialApp.router with DatabaseLoadingScreen
├── core/                  # Shared infrastructure
│   ├── design_system/     # Theme, colors (AppColors), typography (AppTypography)
│   ├── router/            # GoRouter configuration (main router)
│   ├── navigation/        # Legacy router (unused)
│   ├── providers/         # Core providers (database, diary, training, etc.)
│   ├── repositories/      # Data access interfaces & implementations
│   ├── services/          # Service interfaces & stubs
│   ├── models/            # Shared data models
│   ├── widgets/           # Reusable UI components (AppCard, AppButton, etc.)
│   ├── onboarding/        # SplashWrapper, OnboardingScreen
│   └── local_db/seeds/    # Seed data
├── diet/                  # Nutrition data layer
│   ├── models/            # Food, diary, weighin models
│   ├── providers/         # Diet-specific providers (FoodSearchNotifier, etc.)
│   ├── repositories/      # Drift repositories (AlimentoRepository, etc.)
│   ├── screens/coach/     # Adaptive coach UI
│   └── services/          # WeightTrendCalculator, AdaptiveCoachService, OCR
├── training/              # Workout tracking module
│   ├── database/          # AppDatabase (Drift) - ALL tables defined here
│   ├── models/            # Exercise, session models
│   ├── providers/         # Training providers
│   ├── screens/           # Training UI screens
│   ├── services/          # TimerAudioService, NativeBeepService
│   └── widgets/           # Training-specific widgets
└── features/              # Feature presentation layer
    ├── diary/presentation/    # DiaryScreen
    ├── foods/                 # FoodSearchUnifiedScreen, providers
    ├── home/presentation/     # EntryScreen, HomeScreen, TodayScreen
    ├── training/presentation/ # HistoryScreen, TrainingLibraryScreen
    └── weight/presentation/   # WeightScreen
```

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run on Android (primary target)
flutter run -d android

# Run on web (local development)
flutter run -d chrome

# Run tests
flutter test

# Analyze code (must pass before PR)
flutter analyze

# Format code
dart format lib/ test/

# Generate Drift code (after modifying tables/models)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation
dart run build_runner watch --delete-conflicting-outputs

# Build web release
flutter build web --release
```

## Development Guidelines

### Code Style
- **Language**: Code in English, UI strings and domain comments in Spanish
- **Linting**: Uses `flutter_lints` - run `flutter analyze` before commits
- **Formatting**: Use `dart format lib/ test/` before commits

### Architecture
- Feature-based organization with `core/`, `diet/`, `training/`, and `features/` modules
- Riverpod providers for state management (use `flutter_riverpod` patterns)
- Drift for SQLite persistence - requires code generation after schema changes
- Repository pattern for data access

### Key Patterns
- Entry point: `main.dart` → `app.dart` (DatabaseLoadingScreen) → `EntryScreen` → `HomeScreen`
- Navigation: Use GoRouter extensions (`context.goToNutrition()`, `context.goToTraining()`)
- Providers are in `*/providers/` directories
- Screens/UI in `*/screens/` or `*/presentation/` directories
- Database tables defined in `training/database/database.dart` (Schema v11)
- Timer audio: Use `TimerAudioService` → `NativeBeepService` (not just_audio)

### Testing
- Tests mirror source structure in `test/` directory
- Run `flutter test` to execute all tests
- 33+ test files covering services, repositories, UI, and providers
- Widget and unit tests supported

### PR Checklist
1. `flutter analyze` - no errors
2. `flutter test` - all tests pass
3. `dart format lib/ test/` - code formatted
4. `dart run build_runner build --delete-conflicting-outputs` - if schema changed

## Known Pitfalls

1. **FTS5 sync**: After inserting foods, call `rebuildFtsIndex()` or `insertFoodFts()` manually
2. **Timer audio**: Use `TimerAudioService` (delegates to `NativeBeepService`), NOT just_audio
3. **BuildContext async**: Always check `context.mounted` after `await`
4. **Drift codegen**: Run `dart run build_runner build` after modifying tables
5. **GoRouter vs Navigator**: Use `context.goTo*()` extensions, not `Navigator.push()`
6. **Duplicate providers**: Two `food_search_provider.dart` exist - use `diet/providers/`

## Important Notes

- Android is the primary target platform
- Web support is available but secondary
- Camera/microphone permissions needed for OCR and voice features
- Local notifications require Android service configuration
- Foods database (~600k products) loads on first launch via `DatabaseLoadingScreen`
