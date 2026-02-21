import Foundation

/// Service for looking up exercise muscle data from the ExerciseDB API (RapidAPI).
/// Used when users add custom exercises to auto-detect targeted muscles.
/// Supports both v1 and v2 API response formats.
actor ExerciseAPIService {
    static let shared = ExerciseAPIService()

    // MARK: - Configuration

    /// Users should replace this with their own RapidAPI key.
    /// Get one free at: https://rapidapi.com/justin-WFnsXH_t6/api/exercisedb
    private let apiKey = "f008b2770cmshc05c8f700bba8a3p1abac2jsn42ad21555926"
    private let baseURL = "https://exercisedb.p.rapidapi.com"
    private let host = "exercisedb.p.rapidapi.com"

    // MARK: - API Models

    /// Unified exercise result that handles both v1 and v2 response formats.
    struct ExerciseResult: Codable {
        // v1 fields
        let id: String?
        let name: String?
        let target: String?
        let bodyPart: String?
        let equipment: String?
        let secondaryMuscles: [String]?
        let instructions: [String]?

        // v2 fields (ExerciseDB API may return these instead)
        let exerciseId: String?
        let targetMuscles: [String]?
        let bodyParts: [String]?
        let equipments: [String]?

        /// The primary target muscle (handles both v1 single string and v2 array)
        var primaryTarget: String? {
            target ?? targetMuscles?.first
        }

        /// All secondary muscles (handles both formats)
        var allSecondaryMuscles: [String] {
            secondaryMuscles ?? []
        }

        /// Exercise name from either format
        var exerciseName: String {
            name ?? "Unknown"
        }

        /// Exercise ID from either format
        var exerciseID: String {
            id ?? exerciseId ?? ""
        }
    }

    // MARK: - Search

    /// Search for exercises by name and return matching results.
    func searchExercise(name: String) async throws -> [ExerciseResult] {
        let query = name.lowercased()
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name

        guard let url = URL(string: "\(baseURL)/exercises/name/\(query)?limit=5&offset=0") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401, 403:
            throw APIError.invalidAPIKey
        case 429:
            throw APIError.rateLimited
        default:
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw APIError.serverError(httpResponse.statusCode, body)
        }

        // Try decoding as array of exercises
        do {
            let results = try JSONDecoder().decode([ExerciseResult].self, from: data)
            return results
        } catch {
            // The API might wrap results in an object — try alternate formats
            // Some API versions return { "exercises": [...] } or { "data": [...] }
            if let wrapper = try? JSONDecoder().decode(WrappedResponse.self, from: data) {
                return wrapper.exercises ?? wrapper.data ?? []
            }
            let responseString = String(data: data, encoding: .utf8) ?? "binary data"
            throw APIError.decodingError(responseString.prefix(500).description)
        }
    }

    /// Wrapper for APIs that nest results in an object
    private struct WrappedResponse: Codable {
        let exercises: [ExerciseResult]?
        let data: [ExerciseResult]?
    }

    // MARK: - Muscle Mapping

    /// Maps ExerciseDB muscle names to our MuscleGroup enum.
    static func mapToMuscleGroup(_ apiMuscle: String) -> MuscleGroup? {
        let name = apiMuscle.lowercased().trimmingCharacters(in: .whitespaces)

        switch name {
        // Chest
        case "pectorals", "chest", "pectoralis major sternal head",
             "pectoralis major clavicular head":
            return .chest

        // Back
        case "lats", "latissimus dorsi", "upper back", "traps", "trapezius",
             "rhomboids", "back", "infraspinatus", "teres major",
             "teres minor", "middle back", "lower back":
            // Note: "lower back" also maps here for cases where the API uses it as a back variant
            // The dedicated lower back case below handles the specific erector spinae terms
            return .back

        // Shoulders
        case "delts", "deltoids", "anterior deltoids", "lateral deltoids",
             "posterior deltoids", "shoulders", "serratus anterior",
             "levator scapulae", "front deltoids", "rear deltoids",
             "rotator cuff":
            return .shoulders

        // Biceps
        case "biceps", "biceps brachii", "brachialis":
            return .biceps

        // Triceps
        case "triceps", "triceps brachii":
            return .triceps

        // Forearms
        case "forearms", "wrist flexors", "wrist extensors",
             "brachioradialis", "grip":
            return .forearms

        // Core
        case "abs", "abdominals", "rectus abdominis", "obliques",
             "transverse abdominis", "core":
            return .abdominals

        // Lower Back
        case "spine", "erector spinae", "spinal erectors",
             "lower back erectors":
            return .lowerBack

        // Glutes
        case "glutes", "gluteus maximus", "gluteus medius",
             "gluteus minimus", "gluteals":
            return .glutes

        // Quads
        case "quads", "quadriceps", "vastus lateralis", "vastus medialis",
             "rectus femoris", "vastus intermedius":
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
             "hip adductors", "hip abductors", "inner thighs", "outer thighs":
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
    case rateLimited
    case serverError(Int, String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidAPIKey:
            return "Invalid or expired API key. Check your RapidAPI key in ExerciseAPIService.swift and ensure you're subscribed to the ExerciseDB API."
        case .rateLimited:
            return "Rate limit exceeded. Wait a moment and try again."
        case .serverError(let code, let body):
            return "Server error (\(code)): \(body.prefix(200))"
        case .decodingError(let raw):
            return "Unexpected response format: \(raw.prefix(200))"
        }
    }
}
