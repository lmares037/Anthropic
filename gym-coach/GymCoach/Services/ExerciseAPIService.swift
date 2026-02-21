import Foundation

/// Service for looking up exercise muscle data from the ExerciseDB API (RapidAPI).
/// Used when users add custom exercises to auto-detect targeted muscles.
actor ExerciseAPIService {
    static let shared = ExerciseAPIService()

    // MARK: - Configuration

    /// Users should replace this with their own RapidAPI key.
    /// Get one free at: https://rapidapi.com/justin-WFnsXH_t6/api/exercisedb
    private let apiKey = "f008b2770cmshc05c8f700bba8a3p1abac2jsn42ad21555926"
    private let baseURL = "https://exercisedb.p.rapidapi.com"
    private let host = "exercisedb.p.rapidapi.com"

    // MARK: - API Models

    struct ExerciseResult: Codable {
        let id: String
        let name: String
        let target: String
        let bodyPart: String
        let equipment: String
        let secondaryMuscles: [String]
        let instructions: [String]
    }

    // MARK: - Search

    /// Search for exercises by name and return matching results.
    func searchExercise(name: String) async throws -> [ExerciseResult] {
        let query = name.lowercased()
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name

        guard let url = URL(string: "\(baseURL)/exercises/name/\(query)?limit=5") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 403 {
                throw APIError.invalidAPIKey
            }
            throw APIError.serverError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode([ExerciseResult].self, from: data)
    }

    // MARK: - Muscle Mapping

    /// Maps ExerciseDB muscle names to our MuscleGroup enum.
    static func mapToMuscleGroup(_ apiMuscle: String) -> MuscleGroup? {
        let name = apiMuscle.lowercased().trimmingCharacters(in: .whitespaces)

        switch name {
        // Chest
        case "pectorals", "chest":
            return .chest

        // Back
        case "lats", "latissimus dorsi", "upper back", "traps", "trapezius",
             "rhomboids", "back":
            return .back

        // Shoulders
        case "delts", "deltoids", "anterior deltoids", "lateral deltoids",
             "posterior deltoids", "shoulders", "serratus anterior",
             "levator scapulae":
            return .shoulders

        // Biceps
        case "biceps", "biceps brachii", "brachialis":
            return .biceps

        // Triceps
        case "triceps", "triceps brachii":
            return .triceps

        // Forearms
        case "forearms", "wrist flexors", "wrist extensors",
             "brachioradialis":
            return .forearms

        // Core
        case "abs", "abdominals", "rectus abdominis", "obliques",
             "transverse abdominis":
            return .abdominals

        // Lower Back
        case "spine", "erector spinae", "lower back", "spinal erectors":
            return .lowerBack

        // Glutes
        case "glutes", "gluteus maximus", "gluteus medius",
             "gluteus minimus":
            return .glutes

        // Quads
        case "quads", "quadriceps", "vastus lateralis", "vastus medialis",
             "rectus femoris":
            return .quadriceps

        // Hamstrings
        case "hamstrings", "biceps femoris", "semitendinosus",
             "semimembranosus":
            return .hamstrings

        // Calves
        case "calves", "gastrocnemius", "soleus":
            return .calves

        // Adductors/Abductors
        case "adductors", "abductors", "hip flexors", "tensor fasciae latae",
             "hip adductors", "hip abductors":
            return .adductorsAbductors

        default:
            return nil
        }
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidAPIKey
    case serverError(Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidAPIKey:
            return "Invalid API key. Add your RapidAPI key in ExerciseAPIService.swift"
        case .serverError(let code):
            return "Server error (code \(code))"
        case .decodingError:
            return "Failed to parse response"
        }
    }
}
