import Foundation

struct GolfQuote: Hashable, Identifiable {
    let text: String
    let author: String
    var id: String { "\(author)::\(text)" }
}

enum GolfQuotes {
    /// Curated quotes from famous golfers — rotate daily.
    static let all: [GolfQuote] = [
        .init(text: "The more I practice, the luckier I get.",
              author: "Gary Player"),
        .init(text: "Success in this game depends less on strength of body than on strength of mind and character.",
              author: "Arnold Palmer"),
        .init(text: "Don't be too proud to take lessons. I'm not.",
              author: "Jack Nicklaus"),
        .init(text: "Confidence is the most important single factor in this game, and no matter how great your natural talent, there is only one way to obtain and sustain it: work.",
              author: "Jack Nicklaus"),
        .init(text: "Golf is a game of inches. The most important are the six between your ears.",
              author: "Arnold Palmer"),
        .init(text: "Forget your opponents; always play against par.",
              author: "Sam Snead"),
        .init(text: "The only way to become a good player is to play with better players.",
              author: "Sam Snead"),
        .init(text: "Play the ball where it lies.",
              author: "Bobby Jones"),
        .init(text: "Golf is deceptively simple and endlessly complicated.",
              author: "Arnold Palmer"),
        .init(text: "Golf is a compromise between what your ego wants you to do, what experience tells you to do, and what your nerves let you do.",
              author: "Bruce Crampton"),
        .init(text: "I never hit a shot, even in practice, without having a very sharp, in-focus picture of it in my head.",
              author: "Jack Nicklaus"),
        .init(text: "Every day I try to tell myself this is going to be fun today.",
              author: "Fred Couples"),
        .init(text: "The harder I work, the luckier I get.",
              author: "Gary Player"),
        .init(text: "I was three over. One over a house, one over a patio and one over a swimming pool.",
              author: "Lee Trevino"),
        .init(text: "You swing your best when you have the fewest things to think about.",
              author: "Bobby Jones"),
        .init(text: "Pressure is nothing more than the shadow of great opportunity.",
              author: "Michael Johnson"),
        .init(text: "The most important shot in golf is the next one.",
              author: "Ben Hogan"),
        .init(text: "If you don't think you can make the putt, you'll never make it.",
              author: "Jack Nicklaus"),
        .init(text: "As you walk down the fairway of life you must smell the roses, for you only get to play one round.",
              author: "Ben Hogan"),
        .init(text: "Putts get real difficult the day they hand out the money.",
              author: "Lee Trevino"),
        .init(text: "Golf is about how well you accept, respond to, and score with your misses much more so than it is a game of your perfect shots.",
              author: "Dr. Bob Rotella"),
        .init(text: "Nobody ever remembers who finished second but the guy who finished second.",
              author: "Bobby Unser"),
        .init(text: "Never say never, because limits, like fears, are often just an illusion.",
              author: "Tiger Woods"),
        .init(text: "No matter how good you get, you can always get better — and that's the exciting part.",
              author: "Tiger Woods"),
        .init(text: "You have to have the confidence to believe that you can pull off any shot at any time.",
              author: "Tiger Woods"),
        .init(text: "Of all the hazards, fear is the worst.",
              author: "Sam Snead"),
        .init(text: "A bad attitude is worse than a bad swing.",
              author: "Payne Stewart"),
        .init(text: "Every shot counts. The three-foot putt is as important as the 300-yard drive.",
              author: "Henry Cotton")
    ]

    /// Deterministic daily quote — flips at local midnight.
    static var today: GolfQuote {
        let cal = Calendar.current
        let day = cal.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let year = cal.component(.year, from: Date())
        // Mix day and year so the same day-of-year doesn't repeat identically.
        let seed = (day + year) % all.count
        return all[seed]
    }
}
