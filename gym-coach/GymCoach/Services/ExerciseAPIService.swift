import Foundation

/// Service for looking up exercise muscle data from the ExerciseDB API (RapidAPI).
///
/// **API-saving strategy:** On first use, fetches ALL ~1300 exercises in a single API call
/// and caches them locally as a JSON file. All subsequent searches are performed against the
/// local cache with zero API calls. The cache can be refreshed manually if needed.
actor ExerciseAPIService {
    static let shared = ExerciseAPIService()

    // MARK: - Configuration

    /// Users should replace this with their own RapidAPI key.
    /// Get one free at: https://rapidapi.com/justin-WFnsXH_t6/api/exercisedb
    private let apiKey = "f008b2770cmshc05c8f700bba8a3p1abac2jsn42ad21555926"
    private let baseURL = "https://exercisedb.p.rapidapi.com"
    private let host = "exercisedb.p.rapidapi.com"

    /// In-memory cache of all exercises (loaded from disk or API)
    private var cachedExercises: [ExerciseResult] = []

    /// Whether the cache has been loaded this session
    private var cacheLoaded = false

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

    // MARK: - Local Cache

    private var cacheFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("exercisedb_cache.json")
    }

    /// Loads cached exercises from disk into memory.
    private func loadCacheFromDisk() -> [ExerciseResult]? {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else { return nil }
        guard let data = try? Data(contentsOf: cacheFileURL) else { return nil }
        return try? JSONDecoder().decode([ExerciseResult].self, from: data)
    }

    /// Saves exercises to disk cache.
    private func saveCacheToDisk(_ exercises: [ExerciseResult]) {
        guard let data = try? JSONEncoder().encode(exercises) else { return }
        try? data.write(to: cacheFileURL)
    }

    /// Returns the number of cached exercises, or nil if no cache exists.
    var cacheCount: Int? {
        if !cachedExercises.isEmpty { return cachedExercises.count }
        return loadCacheFromDisk()?.count
    }

    /// Whether a local cache file exists on disk.
    var hasCacheOnDisk: Bool {
        FileManager.default.fileExists(atPath: cacheFileURL.path)
    }

    // MARK: - Ensure Cache

    /// Makes sure exercises are loaded — from disk if available, otherwise fetches from API (1 call).
    func ensureCache() async throws {
        if cacheLoaded && !cachedExercises.isEmpty { return }

        // Try disk first
        if let diskCache = loadCacheFromDisk(), !diskCache.isEmpty {
            cachedExercises = diskCache
            cacheLoaded = true
            return
        }

        // No local cache — fetch everything from the API (1 API call)
        try await refreshCache()
    }

    /// Fetches ALL exercises from the API and saves to local cache. Costs 1 API call.
    func refreshCache() async throws {
        guard let url = URL(string: "\(baseURL)/exercises?limit=1400&offset=0") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 30 // Larger payload needs more time

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

        // Decode — try array first, then wrapped formats
        var exercises: [ExerciseResult] = []

        if let decoded = try? JSONDecoder().decode([ExerciseResult].self, from: data) {
            exercises = decoded
        } else if let wrapper = try? JSONDecoder().decode(WrappedResponse.self, from: data) {
            exercises = wrapper.exercises ?? wrapper.data ?? []
        } else {
            let responseString = String(data: data, encoding: .utf8) ?? "binary data"
            throw APIError.decodingError(responseString.prefix(500).description)
        }

        guard !exercises.isEmpty else {
            throw APIError.decodingError("API returned 0 exercises")
        }

        cachedExercises = exercises
        cacheLoaded = true
        saveCacheToDisk(exercises)
    }

    // MARK: - Local Search (no API call)

    /// Searches the local cache by keyword. No API call.
    /// Call `ensureCache()` first to make sure data is loaded.
    func searchLocal(keyword: String) -> [ExerciseResult] {
        let query = keyword.lowercased().trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }

        let words = query.split(separator: " ").map(String.init)

        return cachedExercises.filter { exercise in
            let name = exercise.exerciseName.lowercased()
            let target = exercise.primaryTarget?.lowercased() ?? ""
            let bodyPart = (exercise.bodyPart ?? exercise.bodyParts?.first ?? "").lowercased()
            let equip = (exercise.equipment ?? exercise.equipments?.first ?? "").lowercased()
            let searchable = "\(name) \(target) \(bodyPart) \(equip)"

            // Every word in the query must match somewhere
            return words.allSatisfy { searchable.contains($0) }
        }
    }

    // MARK: - Legacy search (kept for backward compat but now uses cache)

    /// Search for exercises by name. Uses local cache (0 API calls after initial fetch).
    func searchExercise(name: String) async throws -> [ExerciseResult] {
        try await ensureCache()
        let results = searchLocal(keyword: name)
        return Array(results.prefix(15))
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
