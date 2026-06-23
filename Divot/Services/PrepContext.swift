import Foundation

/// Builds the plain-text brief sent to the model: course history, recent
/// form, and the player's adopted coaching principles. All assembled
/// locally from SwiftData — the AI only ever sees this digest.
enum PrepContext {
    static func brief(course: Course,
                      courseRounds: [Round],   // eligible rounds at this course, newest first
                      recentRounds: [Round]) -> String {  // last 3 anywhere, newest first
        var out = ""
        let par = course.computedPar > 0 ? course.computedPar : course.totalPar
        out += "UPCOMING ROUND — COURSE: \(course.name)"
        if par > 0 { out += " (par \(par))" }
        out += "\n"
        out += "Player: ~14 handicap, ~100–105 mph driver swing, tends to push/miss right, "
        out += "forged-iron player, short game is the scoring engine.\n\n"

        out += "=== HISTORY AT \(course.name.uppercased()) ===\n"
        if courseRounds.isEmpty {
            out += "No prior rounds logged at this course — this would be a first.\n"
        } else {
            for r in courseRounds.prefix(6) { out += roundLine(r) + "\n" }
        }

        out += "\n=== RECENT FORM (last 3 rounds, any course) ===\n"
        if recentRounds.isEmpty {
            out += "No recent rounds logged.\n"
        } else {
            for r in recentRounds.prefix(3) { out += roundLine(r, includeCourse: true) + "\n" }
        }

        out += "\n=== PLAYER'S ADOPTED COACHING PRINCIPLES ===\n"
        for advisor in Advisors.playbookAdvisors {
            for t in Advisors.selectedTeachings(for: advisor) {
                out += "- \(advisor.name) — \(t.title): \(t.summary)\n"
            }
        }

        out += "\nUsing all of the above, give exactly three advisories for the "
        out += "upcoming round at \(course.name)."
        return out
    }

    private static func roundLine(_ r: Round, includeCourse: Bool = false) -> String {
        let when = r.date.formatted(.dateTime.month(.abbreviated).day().year())
        var parts: [String] = []
        if includeCourse { parts.append(r.courseName) }
        parts.append(when)
        parts.append("\(r.roundType.shortBadge) \(r.totalScore) (\(r.scoreToPar.toParText))")
        if r.fairwayAttempts > 0 { parts.append("FIR \(Int(r.fairwayPercentage))%") }
        if !r.holes.isEmpty { parts.append("GIR \(Int(r.girPercentage))%") }
        if r.totalPutts > 0 { parts.append("\(r.totalPutts) putts") }
        if r.weatherHighF > 0 || r.weatherWindMph > 0 {
            parts.append("wx ~\(Int(r.weatherHighF))°F wind \(Int(r.weatherWindMph))mph")
        }
        var line = "• " + parts.joined(separator: " · ")

        let trouble = r.sortedHoles
            .filter { $0.score > 0 && ($0.score - $0.par) >= 2 }
            .sorted { ($0.score - $0.par) > ($1.score - $1.par) }
            .prefix(3)
        if !trouble.isEmpty {
            let list = trouble.map { "#\($0.number) (par \($0.par), made \($0.score))" }
                .joined(separator: ", ")
            line += "\n    trouble holes: \(list)"
        }
        if !r.notes.isEmpty {
            line += "\n    note: \(r.notes.prefix(180))"
        }
        return line
    }
}
