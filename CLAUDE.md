# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Juan Tracker is a Flutter Android-first application for personal nutrition and workout tracking. It features food logging, weight tracking, workout sessions with voice input, OCR import for routines, and visual analytics.

## Tech Stack

- **Flutter**: 3.10.7
- **State Management**: Riverpod 3 (`flutter_riverpod: ^3.0.0`)
- **Database**: Drift (SQLite) with code generation
- **UI**: Material Design with Google Fonts (Montserrat)
- **Key Libraries**: ML Kit (OCR), speech_to_text, fl_chart, table_calendar, flutter_local_notifications

## Project Structure

```
lib/
├── main.dart              # App entry point
├── app.dart               # Root widget (JuanTrackerApp)
├── core/                  # Shared infrastructure
│   ├── design_system/     # Theme, colors, typography
│   ├── local_db/          # Seed data
│   ├── models/            # Shared data models
│   ├── navigation/        # Routing
│   ├── providers/         # Core Riverpod providers
│   ├── repositories/      # Data access layer
│   ├── services/          # Service interfaces & stubs
│   └── widgets/           # Reusable UI components
├── diet/                  # Nutrition tracking module
│   ├── models/            # Food, diary, weighin models
│   ├── providers/         # Diet-specific providers
│   ├── repositories/      # Drift repositories
│   ├── screens/           # Diet UI screens
│   └── services/          # OCR, food APIs, calculations
├── training/              # Workout tracking module
│   ├── database/          # Drift database & tables
│   ├── models/            # Exercise, session models
│   ├── providers/         # Training providers
│   ├── repositories/      # Training data access
│   ├── screens/           # Training UI screens
│   └── widgets/           # Training-specific widgets
└── features/              # Feature screens (home, diary, summary, etc.)
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
- Entry point: `main.dart` → `app.dart` → `EntryScreen` → `HomeScreen`
- Providers are in `*/providers/` directories
- Screens/UI in `*/screens/` or `*/presentation/` directories
- Database tables defined in `training/database/database.dart`

### Testing
- Tests mirror source structure in `test/` directory
- Run `flutter test` to execute all tests
- Widget and unit tests supported

### PR Checklist
1. `flutter analyze` - no errors
2. `flutter test` - all tests pass
3. `dart format lib/ test/` - code formatted
4. `dart run build_runner build --delete-conflicting-outputs` - if schema changed

## Important Notes

- Android is the primary target platform
- Web support is available but secondary
- Camera/microphone permissions needed for OCR and voice features
- Local notifications require Android service configuration
