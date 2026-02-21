# Gym Coach

A body recomposition workout tracker for iOS. Tracks weekly effective sets per muscle group using fractional activation — primary muscles count at 100%, secondary muscles at 50-75% based on EMG activation data.

Built for a 33-year-old male (185 lbs, 5'10", 19.5% BF) targeting a lean physique with visible muscle.

## Features

- **Weekly Volume Dashboard** — Visual progress rings for all 13 muscle groups with 12-20 set hypertrophy targets
- **Fractional Set Tracking** — Exercises contribute 100% to primary muscles, 50-75% to secondary muscles
- **70+ Pre-loaded Exercises** — Calisthenics, gym machines, free weights, and cables with accurate muscle activation profiles
- **Custom Exercise Creator** — Add any exercise with manual muscle selection or ExerciseDB API auto-detection
- **Smart Exercise List** — Recently used exercises appear first for quick logging
- **+/- Set Counter** — Tap-friendly stepper with haptic feedback for adjusting sets during workouts
- **Exercise Library** — Filterable by category, equipment, and muscle group with detailed activation breakdowns
- **Body Composition Profile** — Tracks weight, body fat %, lean mass, and fat mass

## Muscle Groups Tracked

Chest, Back, Shoulders, Biceps, Triceps, Forearms, Core (Abs), Lower Back, Glutes, Quads, Hamstrings, Calves, Adductors/Abductors

## Tech Stack

- **SwiftUI** — Declarative UI with dark minimal design
- **SwiftData** — Native persistence (requires iOS 17+)
- **ExerciseDB API** — Optional muscle lookup for custom exercises (RapidAPI)

## Project Structure

```
GymCoach/
├── GymCoachApp.swift              # App entry point
├── Models/
│   ├── MuscleGroup.swift          # 13 muscle groups with colors, icons, categories
│   ├── Exercise.swift             # Exercise model with muscle activation profiles
│   ├── WorkoutLog.swift           # Workout session and entry models
│   └── ExerciseLibrary.swift      # 70+ pre-loaded exercises with activation %
├── ViewModels/
│   └── WorkoutViewModel.swift     # Weekly set calculations, workout CRUD
├── Views/
│   ├── MainTabView.swift          # Tab bar (Dashboard, Workout, Library, Profile)
│   ├── Dashboard/
│   │   └── DashboardView.swift    # Weekly volume grid with progress rings
│   ├── Workout/
│   │   ├── WorkoutView.swift      # Active workout with exercise entries
│   │   ├── AddExerciseSheet.swift # Search, filter, select exercises
│   │   └── AddCustomExerciseView.swift  # Create custom exercises + API lookup
│   ├── Library/
│   │   └── ExerciseLibraryView.swift    # Browse all exercises with detail sheets
│   ├── Profile/
│   │   └── ProfileView.swift      # Body stats, composition, all-time stats
│   └── Components/
│       ├── ProgressRing.swift     # Circular + bar progress indicators
│       ├── SetCounter.swift       # +/- stepper with haptics
│       └── MuscleTagView.swift    # Colored muscle tags + flow layout
├── Services/
│   └── ExerciseAPIService.swift   # ExerciseDB API integration
└── Theme/
    └── AppTheme.swift             # Colors, spacing, typography, card modifiers
```

## Setup

1. Clone the repo
2. Open `GymCoach.xcodeproj` in Xcode 15+
3. Select a simulator and hit **Cmd+R**

### Optional: ExerciseDB API

To enable auto-detection of muscles when adding custom exercises:

1. Sign up at [RapidAPI](https://rapidapi.com/justin-WFnsXH_t6/api/exercisedb) (free tier)
2. Copy your API key
3. Paste it in `GymCoach/Services/ExerciseAPIService.swift` replacing `YOUR_RAPIDAPI_KEY`

## License

MIT
