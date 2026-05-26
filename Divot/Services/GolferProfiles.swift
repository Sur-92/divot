import Foundation

/// Short, respectful biographical card for the people quoted in
/// `GolfQuotes`. Used by the hover-popover on the round-screen quote.
/// Every entry speaks well of the person.
struct GolferProfile {
    let name: String
    let tagline: String          // one-line headline shown under the name
    let bio: String              // ~80–150 words, in our own factual words
    let photoAssetName: String   // matches an image file at
                                 // <container>/Documents/GolferPhotos/<name>.jpg
    let wikipediaURL: String?    // optional reference link
}

enum GolferProfiles {
    static let byName: [String: GolferProfile] = [

        "Gary Player": .init(
            name: "Gary Player",
            tagline: "9-time major champion · Career Grand Slam",
            bio: "South African legend known as the Black Knight. Gary Player won nine major championships and is one of only five players in history to complete the Career Grand Slam. A relentless fitness pioneer when nobody else trained — and one of the most-traveled ambassadors the game has ever known. The line about practice and luck is his philosophy in five words.",
            photoAssetName: "GaryPlayer",
            wikipediaURL: "https://en.wikipedia.org/wiki/Gary_Player"),

        "Arnold Palmer": .init(
            name: "Arnold Palmer",
            tagline: "“The King” · 7 majors · 62 PGA Tour wins",
            bio: "Arnold Palmer brought golf to the television age. Seven majors, 62 PGA Tour wins, and a charisma that built “Arnie's Army” into a movement. As gracious and generous off the course as he was bold on it — he helped found the modern senior tour, a children's hospital, and a brand of decency that still defines the sport.",
            photoAssetName: "ArnoldPalmer",
            wikipediaURL: "https://en.wikipedia.org/wiki/Arnold_Palmer"),

        "Jack Nicklaus": .init(
            name: "Jack Nicklaus",
            tagline: "“The Golden Bear” · 18 professional majors",
            bio: "The standard against which modern major-championship golf is still measured. Eighteen professional majors, an unmatched gift for steady, club-by-club thinking under pressure, and an extraordinary second career as a course architect. Generous mentor and elder statesman of the game; his books and instruction have shaped generations.",
            photoAssetName: "JackNicklaus",
            wikipediaURL: "https://en.wikipedia.org/wiki/Jack_Nicklaus"),

        "Sam Snead": .init(
            name: "Sam Snead",
            tagline: "Slammin' Sammy · 82 PGA Tour wins · 7 majors",
            bio: "Eighty-two PGA Tour wins — a record that stood for over half a century — and arguably the most beautiful, repeatable swing the game has ever seen. Seven majors. A natural athlete who stayed competitive into his seventies; the quintessential Virginia gentleman who could outdrive anyone and out-think most.",
            photoAssetName: "SamSnead",
            wikipediaURL: "https://en.wikipedia.org/wiki/Sam_Snead"),

        "Bobby Jones": .init(
            name: "Bobby Jones",
            tagline: "Amateur Grand Slam, 1930 · co-founded The Masters",
            bio: "An amateur his entire career, Bobby Jones won the “Impregnable Quadrilateral” in 1930 — the U.S. Open, the Open Championship, the U.S. Amateur and the British Amateur in a single season, still the only Grand Slam of its kind. Lawyer, scholar, gentleman; co-founder of Augusta National and The Masters. The embodiment of sportsmanship.",
            photoAssetName: "BobbyJones",
            wikipediaURL: "https://en.wikipedia.org/wiki/Bobby_Jones_(golfer)"),

        "Bruce Crampton": .init(
            name: "Bruce Crampton",
            tagline: "Australian standout · 14 PGA Tour wins",
            bio: "Tough, intelligent Australian competitor — 14 PGA Tour victories and a four-time major runner-up during Jack Nicklaus's prime. Later one of the most successful seniors of his era, with 20 Champions Tour wins including two senior majors. A class act on two continents.",
            photoAssetName: "BruceCrampton",
            wikipediaURL: "https://en.wikipedia.org/wiki/Bruce_Crampton"),

        "Fred Couples": .init(
            name: "Fred Couples",
            tagline: "“Boom Boom” · 1992 Masters champion",
            bio: "One of the most beloved players in modern golf, Fred Couples plays the game with an effortless, easy-going rhythm that belies tournament-tough nerves. Masters champion in 1992, multiple-time Presidents Cup captain, and a Champions Tour star — admired by peers and fans for his temperament as much as his swing.",
            photoAssetName: "FredCouples",
            wikipediaURL: "https://en.wikipedia.org/wiki/Fred_Couples"),

        "Lee Trevino": .init(
            name: "Lee Trevino",
            tagline: "“The Merry Mex” · 6 majors · self-taught great",
            bio: "Six majors, including a single-month sweep of the 1971 U.S. Open, Open Championship and Canadian Open. Self-taught, working-class, gloriously funny on the course — he turned shotmaking and storytelling into the same art form. One of the great minds of the game and a beloved ambassador for it.",
            photoAssetName: "LeeTrevino",
            wikipediaURL: "https://en.wikipedia.org/wiki/Lee_Trevino"),

        "Michael Johnson": .init(
            name: "Michael Johnson",
            tagline: "Olympic sprinter · 4 gold medals · 200 m / 400 m legend",
            bio: "Not a golfer, but one of the most composed competitors in all of sport. Four Olympic gold medals, world records in the 200 m and 400 m, and the unforgettable Atlanta '96 sprint double. His line about pressure being the shadow of great opportunity has been quoted in every sport since.",
            photoAssetName: "MichaelJohnson",
            wikipediaURL: "https://en.wikipedia.org/wiki/Michael_Johnson_(sprinter)"),

        "Ben Hogan": .init(
            name: "Ben Hogan",
            tagline: "“The Hawk” · 9 majors · the ball-striker's ball-striker",
            bio: "Nine majors and a reverence-inducing devotion to ball-striking that produced the modern fundamentals. After a near-fatal car accident in 1949, Hogan came back the next year to win the U.S. Open — one of sport's most extraordinary returns. His book “Five Lessons” remains a foundational text on the golf swing.",
            photoAssetName: "BenHogan",
            wikipediaURL: "https://en.wikipedia.org/wiki/Ben_Hogan"),

        "Dr. Bob Rotella": .init(
            name: "Dr. Bob Rotella",
            tagline: "Sport psychologist · coach to dozens of major winners",
            bio: "The most influential sport psychologist in modern golf. Dr. Bob Rotella has worked with Pádraig Harrington, Tom Kite, Davis Love III, Rory McIlroy and many more, and his books — “Golf Is Not a Game of Perfect,” “Putting Out of Your Mind” — are still standard reading. Generous teacher, careful listener, and a quietly transformative figure in the mental game.",
            photoAssetName: "BobRotella",
            wikipediaURL: "https://en.wikipedia.org/wiki/Bob_Rotella"),

        "Bobby Unser": .init(
            name: "Bobby Unser",
            tagline: "Three-time Indianapolis 500 winner",
            bio: "Not a golfer — an American open-wheel legend. Bobby Unser won the Indianapolis 500 three times (1968, 1975, 1981) and the Pikes Peak Hill Climb a record 10 times. Famously sharp-tongued, fearless and quotable; the line about second place is pure Unser.",
            photoAssetName: "BobbyUnser",
            wikipediaURL: "https://en.wikipedia.org/wiki/Bobby_Unser"),

        "Tiger Woods": .init(
            name: "Tiger Woods",
            tagline: "15 majors · 82 PGA Tour wins · generational figure",
            bio: "Fifteen majors and 82 PGA Tour wins, tied with Sam Snead for the all-time lead. The most dominant peak the modern game has known, and the figure most responsible for golf's reach, athleticism and prize purses today. His 2019 Masters win after multiple back surgeries is one of sport's great second acts.",
            photoAssetName: "TigerWoods",
            wikipediaURL: "https://en.wikipedia.org/wiki/Tiger_Woods"),

        "Payne Stewart": .init(
            name: "Payne Stewart",
            tagline: "3 majors · class act in the plus-fours",
            bio: "Three majors — the 1989 PGA Championship and the 1991 and 1999 U.S. Opens — and one of the most recognisable players of his era in his signature plus-fours and tam o'shanter. Beloved teammate and family man, remembered as much for his sportsmanship (the gracious moment with Phil Mickelson after the '99 U.S. Open) as his game. Lost far too young in 1999.",
            photoAssetName: "PayneStewart",
            wikipediaURL: "https://en.wikipedia.org/wiki/Payne_Stewart"),

        "Henry Cotton": .init(
            name: "Henry Cotton",
            tagline: "3-time Open champion · Britain's pre-war great",
            bio: "Three Open Championships (1934, 1937, 1948) and the dominant British professional of the 1930s. Sir Henry Cotton helped raise the standing of the professional golfer in Britain through his playing, his teaching and his prolific writing — a foundational figure in twentieth-century British golf.",
            photoAssetName: "HenryCotton",
            wikipediaURL: "https://en.wikipedia.org/wiki/Henry_Cotton_(golfer)"),
    ]
}
