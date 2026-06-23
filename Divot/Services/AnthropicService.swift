import Foundation

enum AnthropicError: LocalizedError {
    case missingKey
    case http(Int, String)
    case network(String)
    case badResponse
    case empty

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "No Anthropic API key saved. Add one to generate a prep."
        case .http(let code, let body):
            switch code {
            case 401: return "API key was rejected (401). Double-check the key."
            case 429: return "Rate limited (429). Wait a moment and try again."
            case 529: return "Anthropic is overloaded (529). Try again shortly."
            default:  return "Anthropic API error \(code): \(body)"
            }
        case .network(let m): return "Network error: \(m)"
        case .badResponse:    return "Couldn't read the model's response."
        case .empty:          return "The model returned no advisories — try again."
        }
    }
}

/// Calls the Anthropic Messages API to turn a pre-round brief into three
/// concrete advisories. The API key is the user's own, read from the
/// Keychain by the caller and passed in here.
enum AnthropicService {
    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    static let apiVersion = "2023-06-01"
    static let defaultModel = "claude-sonnet-4-6"

    private static let system = """
    You are a seasoned golf caddie and coach preparing a player for an \
    upcoming round. You are given: the course, the player's scoring history \
    at that course, their last few rounds anywhere (current form), and the \
    specific coaching principles they have personally adopted. Produce \
    EXACTLY three concrete advisories for the upcoming round. Each must be \
    actionable on the course — a club choice, a target or miss to favor, a \
    tempo or setup cue, or a scoring strategy — grounded in the data you \
    were given and consistent with the player's adopted teachings. Reference \
    specifics from their history where relevant (a trouble hole, a stat \
    trend, conditions). Avoid generic platitudes. Respond ONLY with a JSON \
    array of exactly three objects, each with keys "title" (4–7 words) and \
    "detail" (2–3 sentences). No markdown, no text outside the JSON array.
    """

    static func generatePrep(brief: String,
                             apiKey: String,
                             model: String = defaultModel) async throws -> [PrepAdvisory] {
        guard !apiKey.isEmpty else { throw AnthropicError.missingKey }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.timeoutInterval = 60

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": system,
            "messages": [["role": "user", "content": brief]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let data: Data
        let resp: URLResponse
        do {
            (data, resp) = try await URLSession.shared.data(for: req)
        } catch {
            throw AnthropicError.network(error.localizedDescription)
        }

        guard let http = resp as? HTTPURLResponse else { throw AnthropicError.badResponse }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AnthropicError.http(http.statusCode, String(body.prefix(300)))
        }

        // Anthropic response shape: { content: [ { type: "text", text: "..." } ] }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = obj["content"] as? [[String: Any]] else {
            throw AnthropicError.badResponse
        }
        let text = content.compactMap { $0["text"] as? String }.joined()
        let advisories = parseAdvisories(text)
        guard !advisories.isEmpty else { throw AnthropicError.empty }
        return advisories
    }

    /// Pull the JSON array out of the model's text, tolerant of stray code
    /// fences or leading prose.
    static func parseAdvisories(_ text: String) -> [PrepAdvisory] {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.contains("```") {
            s = s.replacingOccurrences(of: "```json", with: "")
                 .replacingOccurrences(of: "```", with: "")
                 .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let start = s.firstIndex(of: "["), let end = s.lastIndex(of: "]"), start < end {
            s = String(s[start...end])
        }
        guard let data = s.data(using: .utf8),
              let arr = try? JSONDecoder().decode([PrepAdvisory].self, from: data) else {
            return []
        }
        return Array(arr.prefix(3))
    }
}
