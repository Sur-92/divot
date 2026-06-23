import Foundation
import SwiftData

/// A pre-round prep: three AI-generated advisories for an upcoming round at a
/// chosen course, synthesized from the player's history there, recent form,
/// and adopted playbook teachings. Generated once and saved; lives alongside
/// practice sessions on the Practice page.
@Model
final class PrepPlan {
    var date: Date                    // when generated
    var courseName: String
    var modelUsed: String = ""
    /// JSON array of {title, detail} — exactly three advisories.
    var advisoriesJSON: String = ""
    /// The context brief sent to the model, kept for transparency.
    var brief: String = ""
    var idempotencyKey: String = ""
    var isArchived: Bool = false

    init(date: Date = .now,
         courseName: String = "",
         modelUsed: String = "",
         advisoriesJSON: String = "",
         brief: String = "") {
        self.date = date
        self.courseName = courseName
        self.modelUsed = modelUsed
        self.advisoriesJSON = advisoriesJSON
        self.brief = brief
        self.idempotencyKey = UUID().uuidString
    }

    var advisories: [PrepAdvisory] {
        guard let data = advisoriesJSON.data(using: .utf8), !data.isEmpty,
              let v = try? JSONDecoder().decode([PrepAdvisory].self, from: data)
        else { return [] }
        return v
    }
}

/// One advisory — a title + a couple sentences of specific guidance.
struct PrepAdvisory: Codable, Identifiable {
    let title: String
    let detail: String
    var id: String { title }
}
