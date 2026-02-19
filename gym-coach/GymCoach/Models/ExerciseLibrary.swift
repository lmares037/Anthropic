import Foundation
import SwiftData

/// Pre-loaded exercise database with accurate muscle activation profiles.
/// Primary muscles: 100% activation. Secondary muscles: 50-75% based on EMG data.
struct ExerciseLibrary {

    /// Seeds the database with all pre-loaded exercises if not already present.
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let exercises = calisthenicsExercises + machineExercises + freeWeightExercises + cableExercises
        for exercise in exercises {
            context.insert(exercise)
        }
        try? context.save()
    }

    // MARK: - Calisthenics / Bodyweight

    static var calisthenicsExercises: [Exercise] {
        [
            Exercise(
                name: "Push-Up",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.chest],
                secondaryMuscles: [
                    MuscleActivation(muscle: .triceps, activationPercent: 0.6),
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5),
                    MuscleActivation(muscle: .abdominals, activationPercent: 0.5)
                ],
                instructions: "Hands shoulder-width apart. Lower chest to floor, push back up."
            ),
            Exercise(
                name: "Diamond Push-Up",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.triceps, .chest],
                secondaryMuscles: [
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5)
                ],
                instructions: "Hands together forming a diamond. Lower and press back up."
            ),
            Exercise(
                name: "Wide Push-Up",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.chest],
                secondaryMuscles: [
                    MuscleActivation(muscle: .triceps, activationPercent: 0.5),
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.6)
                ],
                instructions: "Hands wider than shoulder width. Focus on chest stretch at the bottom."
            ),
            Exercise(
                name: "Decline Push-Up",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.chest, .shoulders],
                secondaryMuscles: [
                    MuscleActivation(muscle: .triceps, activationPercent: 0.6)
                ],
                instructions: "Feet elevated on bench. Emphasizes upper chest and front delts."
            ),
            Exercise(
                name: "Pike Push-Up",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.shoulders],
                secondaryMuscles: [
                    MuscleActivation(muscle: .triceps, activationPercent: 0.65),
                    MuscleActivation(muscle: .chest, activationPercent: 0.5)
                ],
                instructions: "Hips high in inverted V position. Lower head toward ground."
            ),
            Exercise(
                name: "Pull-Up",
                category: .calisthenics, equipment: .pullUpBar,
                primaryMuscles: [.back],
                secondaryMuscles: [
                    MuscleActivation(muscle: .biceps, activationPercent: 0.7),
                    MuscleActivation(muscle: .forearms, activationPercent: 0.6),
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5)
                ],
                instructions: "Overhand grip, pull chin over bar. Control the descent."
            ),
            Exercise(
                name: "Chin-Up",
                category: .calisthenics, equipment: .pullUpBar,
                primaryMuscles: [.back, .biceps],
                secondaryMuscles: [
                    MuscleActivation(muscle: .forearms, activationPercent: 0.6),
                    MuscleActivation(muscle: .abdominals, activationPercent: 0.5)
                ],
                instructions: "Underhand grip, pull chin over bar. Great for biceps emphasis."
            ),
            Exercise(
                name: "Neutral Grip Pull-Up",
                category: .calisthenics, equipment: .pullUpBar,
                primaryMuscles: [.back],
                secondaryMuscles: [
                    MuscleActivation(muscle: .biceps, activationPercent: 0.65),
                    MuscleActivation(muscle: .forearms, activationPercent: 0.6)
                ],
                instructions: "Palms facing each other. Easier on shoulders than standard pull-ups."
            ),
            Exercise(
                name: "Dip",
                category: .calisthenics, equipment: .dipStation,
                primaryMuscles: [.chest, .triceps],
                secondaryMuscles: [
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.6)
                ],
                instructions: "Lean slightly forward for chest emphasis. Lower until elbows at 90°."
            ),
            Exercise(
                name: "Tricep Dip (Bench)",
                category: .calisthenics, equipment: .bench,
                primaryMuscles: [.triceps],
                secondaryMuscles: [
                    MuscleActivation(muscle: .chest, activationPercent: 0.5),
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5)
                ],
                instructions: "Hands on bench behind you. Lower body by bending elbows."
            ),
            Exercise(
                name: "Bodyweight Squat",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.quadriceps, .glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.5),
                    MuscleActivation(muscle: .calves, activationPercent: 0.5),
                    MuscleActivation(muscle: .abdominals, activationPercent: 0.5)
                ],
                instructions: "Feet shoulder-width apart. Squat until thighs parallel to floor."
            ),
            Exercise(
                name: "Bulgarian Split Squat",
                category: .calisthenics, equipment: .bench,
                primaryMuscles: [.quadriceps, .glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.6),
                    MuscleActivation(muscle: .adductorsAbductors, activationPercent: 0.5),
                    MuscleActivation(muscle: .calves, activationPercent: 0.5)
                ],
                instructions: "Rear foot elevated on bench. Lower until front thigh is parallel."
            ),
            Exercise(
                name: "Pistol Squat",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.quadriceps, .glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.6),
                    MuscleActivation(muscle: .calves, activationPercent: 0.6),
                    MuscleActivation(muscle: .abdominals, activationPercent: 0.5)
                ],
                instructions: "Single leg squat with other leg extended forward."
            ),
            Exercise(
                name: "Lunge",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.quadriceps, .glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.6),
                    MuscleActivation(muscle: .calves, activationPercent: 0.5),
                    MuscleActivation(muscle: .adductorsAbductors, activationPercent: 0.5)
                ],
                instructions: "Step forward, lower back knee toward ground. Alternate legs."
            ),
            Exercise(
                name: "Glute Bridge",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.65),
                    MuscleActivation(muscle: .lowerBack, activationPercent: 0.5)
                ],
                instructions: "Lie on back, feet flat. Drive hips up, squeeze glutes at top."
            ),
            Exercise(
                name: "Single Leg Glute Bridge",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.7),
                    MuscleActivation(muscle: .abdominals, activationPercent: 0.5)
                ],
                instructions: "One leg extended. Drive hips up with planted foot."
            ),
            Exercise(
                name: "Calf Raise (Bodyweight)",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.calves],
                secondaryMuscles: [],
                instructions: "Stand on edge of step. Rise up on toes, lower below step level."
            ),
            Exercise(
                name: "Plank",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.abdominals],
                secondaryMuscles: [
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5),
                    MuscleActivation(muscle: .lowerBack, activationPercent: 0.5),
                    MuscleActivation(muscle: .glutes, activationPercent: 0.5)
                ],
                instructions: "Forearms on ground, body straight. Hold position."
            ),
            Exercise(
                name: "Hanging Leg Raise",
                category: .calisthenics, equipment: .pullUpBar,
                primaryMuscles: [.abdominals],
                secondaryMuscles: [
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5)
                ],
                instructions: "Hang from bar. Raise legs to parallel or higher. Control the descent."
            ),
            Exercise(
                name: "Mountain Climber",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.abdominals],
                secondaryMuscles: [
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5),
                    MuscleActivation(muscle: .quadriceps, activationPercent: 0.5)
                ],
                instructions: "Plank position. Drive knees alternately toward chest."
            ),
            Exercise(
                name: "Superman",
                category: .calisthenics, equipment: .none,
                primaryMuscles: [.lowerBack],
                secondaryMuscles: [
                    MuscleActivation(muscle: .glutes, activationPercent: 0.6),
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.5)
                ],
                instructions: "Lie face down. Lift arms and legs simultaneously. Hold briefly."
            ),
            Exercise(
                name: "Inverted Row",
                category: .calisthenics, equipment: .other,
                primaryMuscles: [.back],
                secondaryMuscles: [
                    MuscleActivation(muscle: .biceps, activationPercent: 0.65),
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5),
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5)
                ],
                instructions: "Hang under a bar at waist height. Pull chest to bar."
            ),
        ]
    }

    // MARK: - Gym Machines

    static var machineExercises: [Exercise] {
        [
            Exercise(
                name: "Chest Press Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.chest],
                secondaryMuscles: [
                    MuscleActivation(muscle: .triceps, activationPercent: 0.6),
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5)
                ],
                instructions: "Sit with back flat. Press handles forward. Control the return."
            ),
            Exercise(
                name: "Pec Deck / Fly Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.chest],
                secondaryMuscles: [
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5)
                ],
                instructions: "Arms at chest height. Bring pads together in front of chest."
            ),
            Exercise(
                name: "Lat Pulldown",
                category: .machine, equipment: .cable,
                primaryMuscles: [.back],
                secondaryMuscles: [
                    MuscleActivation(muscle: .biceps, activationPercent: 0.65),
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5),
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5)
                ],
                instructions: "Wide grip, pull bar to upper chest. Squeeze shoulder blades."
            ),
            Exercise(
                name: "Seated Row Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.back],
                secondaryMuscles: [
                    MuscleActivation(muscle: .biceps, activationPercent: 0.6),
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5),
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5)
                ],
                instructions: "Chest against pad. Pull handles toward torso. Squeeze back."
            ),
            Exercise(
                name: "Shoulder Press Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.shoulders],
                secondaryMuscles: [
                    MuscleActivation(muscle: .triceps, activationPercent: 0.6)
                ],
                instructions: "Sit upright. Press handles overhead. Lower with control."
            ),
            Exercise(
                name: "Lateral Raise Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.shoulders],
                secondaryMuscles: [],
                instructions: "Arms against pads. Raise outward to shoulder height."
            ),
            Exercise(
                name: "Rear Delt Fly Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.shoulders],
                secondaryMuscles: [
                    MuscleActivation(muscle: .back, activationPercent: 0.5)
                ],
                instructions: "Face the pad. Pull handles outward in reverse fly motion."
            ),
            Exercise(
                name: "Bicep Curl Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.biceps],
                secondaryMuscles: [
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5)
                ],
                instructions: "Arms on pad. Curl handles toward shoulders."
            ),
            Exercise(
                name: "Tricep Extension Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.triceps],
                secondaryMuscles: [],
                instructions: "Arms on pad. Press handles down to full extension."
            ),
            Exercise(
                name: "Leg Press",
                category: .machine, equipment: .machine,
                primaryMuscles: [.quadriceps, .glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.5),
                    MuscleActivation(muscle: .calves, activationPercent: 0.5)
                ],
                instructions: "Feet shoulder-width on platform. Press away, don't lock knees."
            ),
            Exercise(
                name: "Hack Squat Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.quadriceps],
                secondaryMuscles: [
                    MuscleActivation(muscle: .glutes, activationPercent: 0.65),
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.5)
                ],
                instructions: "Shoulders under pads. Squat down and press back up."
            ),
            Exercise(
                name: "Leg Extension",
                category: .machine, equipment: .machine,
                primaryMuscles: [.quadriceps],
                secondaryMuscles: [],
                instructions: "Sit with back against pad. Extend legs to straight. Lower slowly."
            ),
            Exercise(
                name: "Leg Curl (Lying)",
                category: .machine, equipment: .machine,
                primaryMuscles: [.hamstrings],
                secondaryMuscles: [
                    MuscleActivation(muscle: .calves, activationPercent: 0.5)
                ],
                instructions: "Lie face down. Curl pad toward glutes. Lower with control."
            ),
            Exercise(
                name: "Leg Curl (Seated)",
                category: .machine, equipment: .machine,
                primaryMuscles: [.hamstrings],
                secondaryMuscles: [
                    MuscleActivation(muscle: .calves, activationPercent: 0.5)
                ],
                instructions: "Sit with legs over pad. Curl down and back. Control the release."
            ),
            Exercise(
                name: "Hip Abductor Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.adductorsAbductors],
                secondaryMuscles: [
                    MuscleActivation(muscle: .glutes, activationPercent: 0.6)
                ],
                instructions: "Sit with legs inside pads. Push knees outward."
            ),
            Exercise(
                name: "Hip Adductor Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.adductorsAbductors],
                secondaryMuscles: [],
                instructions: "Sit with legs outside pads. Squeeze knees together."
            ),
            Exercise(
                name: "Calf Raise Machine (Seated)",
                category: .machine, equipment: .machine,
                primaryMuscles: [.calves],
                secondaryMuscles: [],
                instructions: "Knees under pads. Rise up on toes. Full stretch at bottom."
            ),
            Exercise(
                name: "Calf Raise Machine (Standing)",
                category: .machine, equipment: .machine,
                primaryMuscles: [.calves],
                secondaryMuscles: [],
                instructions: "Shoulders under pads. Rise up on toes. Full ROM."
            ),
            Exercise(
                name: "Smith Machine Squat",
                category: .machine, equipment: .machine,
                primaryMuscles: [.quadriceps, .glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.5),
                    MuscleActivation(muscle: .calves, activationPercent: 0.5),
                    MuscleActivation(muscle: .abdominals, activationPercent: 0.5)
                ],
                instructions: "Bar on upper back. Feet slightly forward. Squat to parallel."
            ),
            Exercise(
                name: "Ab Crunch Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.abdominals],
                secondaryMuscles: [],
                instructions: "Grip handles. Crunch forward, contracting abs. Return slowly."
            ),
            Exercise(
                name: "Back Extension Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.lowerBack],
                secondaryMuscles: [
                    MuscleActivation(muscle: .glutes, activationPercent: 0.6),
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.5)
                ],
                instructions: "Lean forward against pad. Extend back to straight position."
            ),
            Exercise(
                name: "Assisted Pull-Up Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.back],
                secondaryMuscles: [
                    MuscleActivation(muscle: .biceps, activationPercent: 0.65),
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5)
                ],
                instructions: "Knees on pad. Pull up with assistance. Great for building to full pull-ups."
            ),
            Exercise(
                name: "Assisted Dip Machine",
                category: .machine, equipment: .machine,
                primaryMuscles: [.chest, .triceps],
                secondaryMuscles: [
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.55)
                ],
                instructions: "Knees on pad. Dip down with assistance. Control the movement."
            ),
        ]
    }

    // MARK: - Free Weights

    static var freeWeightExercises: [Exercise] {
        [
            Exercise(
                name: "Barbell Bench Press",
                category: .freeWeight, equipment: .barbell,
                primaryMuscles: [.chest],
                secondaryMuscles: [
                    MuscleActivation(muscle: .triceps, activationPercent: 0.6),
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.55)
                ],
                instructions: "Flat bench. Lower bar to mid-chest. Press up to lockout."
            ),
            Exercise(
                name: "Incline Barbell Bench Press",
                category: .freeWeight, equipment: .barbell,
                primaryMuscles: [.chest, .shoulders],
                secondaryMuscles: [
                    MuscleActivation(muscle: .triceps, activationPercent: 0.6)
                ],
                instructions: "Bench at 30-45°. Lower bar to upper chest. Press up."
            ),
            Exercise(
                name: "Dumbbell Bench Press",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.chest],
                secondaryMuscles: [
                    MuscleActivation(muscle: .triceps, activationPercent: 0.55),
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5)
                ],
                instructions: "Flat bench, dumbbell in each hand. Press up and together."
            ),
            Exercise(
                name: "Dumbbell Fly",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.chest],
                secondaryMuscles: [
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5)
                ],
                instructions: "Arms extended, slight elbow bend. Lower out wide, squeeze together."
            ),
            Exercise(
                name: "Barbell Row",
                category: .freeWeight, equipment: .barbell,
                primaryMuscles: [.back],
                secondaryMuscles: [
                    MuscleActivation(muscle: .biceps, activationPercent: 0.65),
                    MuscleActivation(muscle: .forearms, activationPercent: 0.55),
                    MuscleActivation(muscle: .lowerBack, activationPercent: 0.5)
                ],
                instructions: "Hinge at hips. Pull bar to lower chest. Squeeze back at top."
            ),
            Exercise(
                name: "Dumbbell Row",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.back],
                secondaryMuscles: [
                    MuscleActivation(muscle: .biceps, activationPercent: 0.6),
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5)
                ],
                instructions: "One hand on bench. Row dumbbell to hip. Squeeze lat at top."
            ),
            Exercise(
                name: "Overhead Press (Barbell)",
                category: .freeWeight, equipment: .barbell,
                primaryMuscles: [.shoulders],
                secondaryMuscles: [
                    MuscleActivation(muscle: .triceps, activationPercent: 0.65),
                    MuscleActivation(muscle: .abdominals, activationPercent: 0.5)
                ],
                instructions: "Bar at collarbone. Press overhead to lockout. Keep core tight."
            ),
            Exercise(
                name: "Dumbbell Lateral Raise",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.shoulders],
                secondaryMuscles: [],
                instructions: "Arms at sides. Raise dumbbells out to shoulder height. Lower slowly."
            ),
            Exercise(
                name: "Dumbbell Front Raise",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.shoulders],
                secondaryMuscles: [
                    MuscleActivation(muscle: .chest, activationPercent: 0.5)
                ],
                instructions: "Arms in front of thighs. Raise dumbbells to shoulder height."
            ),
            Exercise(
                name: "Barbell Curl",
                category: .freeWeight, equipment: .barbell,
                primaryMuscles: [.biceps],
                secondaryMuscles: [
                    MuscleActivation(muscle: .forearms, activationPercent: 0.55)
                ],
                instructions: "Arms at sides. Curl bar to shoulders. Lower with control."
            ),
            Exercise(
                name: "Dumbbell Curl",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.biceps],
                secondaryMuscles: [
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5)
                ],
                instructions: "Curl dumbbells alternating or together. Full range of motion."
            ),
            Exercise(
                name: "Hammer Curl",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.biceps],
                secondaryMuscles: [
                    MuscleActivation(muscle: .forearms, activationPercent: 0.65)
                ],
                instructions: "Neutral grip (palms facing in). Curl up. Great for brachialis."
            ),
            Exercise(
                name: "Skull Crusher",
                category: .freeWeight, equipment: .barbell,
                primaryMuscles: [.triceps],
                secondaryMuscles: [],
                instructions: "Lie flat. Lower bar to forehead by bending elbows. Extend back up."
            ),
            Exercise(
                name: "Overhead Tricep Extension",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.triceps],
                secondaryMuscles: [],
                instructions: "Hold dumbbell overhead with both hands. Lower behind head. Extend."
            ),
            Exercise(
                name: "Barbell Squat",
                category: .freeWeight, equipment: .barbell,
                primaryMuscles: [.quadriceps, .glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.55),
                    MuscleActivation(muscle: .lowerBack, activationPercent: 0.5),
                    MuscleActivation(muscle: .abdominals, activationPercent: 0.55),
                    MuscleActivation(muscle: .calves, activationPercent: 0.5)
                ],
                instructions: "Bar on upper back. Squat to parallel or below. Drive through heels."
            ),
            Exercise(
                name: "Romanian Deadlift",
                category: .freeWeight, equipment: .barbell,
                primaryMuscles: [.hamstrings, .glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .lowerBack, activationPercent: 0.65),
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5)
                ],
                instructions: "Slight knee bend. Hinge at hips lowering bar along legs. Feel hamstring stretch."
            ),
            Exercise(
                name: "Deadlift",
                category: .freeWeight, equipment: .barbell,
                primaryMuscles: [.back, .hamstrings, .glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .quadriceps, activationPercent: 0.55),
                    MuscleActivation(muscle: .lowerBack, activationPercent: 0.7),
                    MuscleActivation(muscle: .forearms, activationPercent: 0.6),
                    MuscleActivation(muscle: .abdominals, activationPercent: 0.5)
                ],
                instructions: "Bar over mid-foot. Hinge and grip. Drive through floor to lockout."
            ),
            Exercise(
                name: "Goblet Squat",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.quadriceps, .glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .abdominals, activationPercent: 0.5),
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5)
                ],
                instructions: "Hold dumbbell at chest. Squat deep. Keep torso upright."
            ),
            Exercise(
                name: "Dumbbell Lunge",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.quadriceps, .glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.55),
                    MuscleActivation(muscle: .calves, activationPercent: 0.5)
                ],
                instructions: "Dumbbells at sides. Step forward and lower. Alternate legs."
            ),
            Exercise(
                name: "Wrist Curl",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.forearms],
                secondaryMuscles: [],
                instructions: "Forearms on thighs, palms up. Curl wrists up and lower."
            ),
            Exercise(
                name: "Farmer's Walk",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.forearms],
                secondaryMuscles: [
                    MuscleActivation(muscle: .abdominals, activationPercent: 0.55),
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5),
                    MuscleActivation(muscle: .calves, activationPercent: 0.5)
                ],
                instructions: "Heavy dumbbells at sides. Walk with upright posture. Grip hard."
            ),
            Exercise(
                name: "Hip Thrust (Barbell)",
                category: .freeWeight, equipment: .barbell,
                primaryMuscles: [.glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.6),
                    MuscleActivation(muscle: .abdominals, activationPercent: 0.5)
                ],
                instructions: "Upper back on bench. Bar on hips. Drive hips up. Squeeze at top."
            ),
            Exercise(
                name: "Shrug",
                category: .freeWeight, equipment: .dumbbell,
                primaryMuscles: [.back],
                secondaryMuscles: [
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5)
                ],
                instructions: "Dumbbells at sides. Shrug shoulders up toward ears. Hold briefly."
            ),
        ]
    }

    // MARK: - Cable Exercises

    static var cableExercises: [Exercise] {
        [
            Exercise(
                name: "Cable Fly",
                category: .cable, equipment: .cable,
                primaryMuscles: [.chest],
                secondaryMuscles: [
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5)
                ],
                instructions: "Cables at shoulder height. Bring handles together in front of chest."
            ),
            Exercise(
                name: "Cable Row (Seated)",
                category: .cable, equipment: .cable,
                primaryMuscles: [.back],
                secondaryMuscles: [
                    MuscleActivation(muscle: .biceps, activationPercent: 0.6),
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5)
                ],
                instructions: "Sit at cable station. Pull handle to stomach. Squeeze back."
            ),
            Exercise(
                name: "Face Pull",
                category: .cable, equipment: .cable,
                primaryMuscles: [.shoulders],
                secondaryMuscles: [
                    MuscleActivation(muscle: .back, activationPercent: 0.5)
                ],
                instructions: "Rope attachment at face height. Pull to face, externally rotating."
            ),
            Exercise(
                name: "Cable Lateral Raise",
                category: .cable, equipment: .cable,
                primaryMuscles: [.shoulders],
                secondaryMuscles: [],
                instructions: "Low cable, cross-body. Raise arm to shoulder height."
            ),
            Exercise(
                name: "Cable Bicep Curl",
                category: .cable, equipment: .cable,
                primaryMuscles: [.biceps],
                secondaryMuscles: [
                    MuscleActivation(muscle: .forearms, activationPercent: 0.5)
                ],
                instructions: "Low cable. Curl handle up. Constant tension throughout."
            ),
            Exercise(
                name: "Tricep Pushdown",
                category: .cable, equipment: .cable,
                primaryMuscles: [.triceps],
                secondaryMuscles: [],
                instructions: "High cable, rope or bar. Push down to full extension. Elbows locked at sides."
            ),
            Exercise(
                name: "Cable Overhead Tricep Extension",
                category: .cable, equipment: .cable,
                primaryMuscles: [.triceps],
                secondaryMuscles: [],
                instructions: "Low cable, rope attachment. Face away. Extend arms overhead."
            ),
            Exercise(
                name: "Cable Crunch",
                category: .cable, equipment: .cable,
                primaryMuscles: [.abdominals],
                secondaryMuscles: [],
                instructions: "Kneel facing high cable. Crunch down, contracting abs."
            ),
            Exercise(
                name: "Cable Woodchop",
                category: .cable, equipment: .cable,
                primaryMuscles: [.abdominals],
                secondaryMuscles: [
                    MuscleActivation(muscle: .shoulders, activationPercent: 0.5)
                ],
                instructions: "Cable high or low. Rotate torso pulling cable diagonally across body."
            ),
            Exercise(
                name: "Cable Pull-Through",
                category: .cable, equipment: .cable,
                primaryMuscles: [.glutes, .hamstrings],
                secondaryMuscles: [
                    MuscleActivation(muscle: .lowerBack, activationPercent: 0.55)
                ],
                instructions: "Low cable between legs. Hinge at hips. Drive hips forward."
            ),
            Exercise(
                name: "Cable Kickback",
                category: .cable, equipment: .cable,
                primaryMuscles: [.glutes],
                secondaryMuscles: [
                    MuscleActivation(muscle: .hamstrings, activationPercent: 0.5)
                ],
                instructions: "Ankle strap on low cable. Kick leg back. Squeeze glute at top."
            ),
        ]
    }
}
