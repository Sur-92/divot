import Foundation

/// Curated, read-only roster of golf teachers — the people whose books,
/// lessons, and coaching shaped how the modern game is played. Each
/// advisor has a short bio and a handful of "key teachings" written as
/// actionable advice you can take to the range tomorrow.
///
/// All static — no SwiftData persistence. Edit the dictionary below to
/// add or refine entries.
struct Advisor {
    let name: String
    let era: String                  // "1912–1997" or "b. 1940"
    let specialty: Specialty
    let tagline: String              // single-line headline under the name
    let bio: String                  // 2–3 sentences
    let teachings: [Teaching]        // 3–5 key actionable lessons
    let books: [String]              // notable works
    let photoAssetName: String       // matches GolferPhotos/<name>.{jpg,jpeg,png}
    let wikipediaURL: String?
}

struct Teaching {
    let title: String
    let summary: String              // 2–4 sentences, plain "do-this-now" voice
}

enum Specialty: String, CaseIterable {
    case ballStriking = "Ball-Striking"
    case shortGame    = "Short Game"
    case putting      = "Putting"
    case mental       = "Mental Game"
    case strategy     = "Course Management"
    case fitness      = "Fitness"
    case teaching     = "Teaching"
}

enum Advisors {
    /// Display order on the page. (Roughly chronological by era.)
    static let order: [String] = [
        "Harvey Penick",
        "Ben Hogan",
        "Jack Nicklaus",
        "Lee Trevino",
        "Butch Harmon",
        "Dr. Bob Rotella",
        "Stan Utley",
        "Tiger Woods",
    ]

    static let byName: [String: Advisor] = [

        // MARK: Harvey Penick
        "Harvey Penick": .init(
            name: "Harvey Penick",
            era: "1904–1995",
            specialty: .teaching,
            tagline: "Pro at Austin CC for 70+ years · mentor to Crenshaw, Kite, Wright",
            bio: "Harvey Penick taught golf for seven decades at Austin Country Club, mentoring Tom Kite, Ben Crenshaw, Mickey Wright, and dozens of others. His teaching was simple, unhurried, and quietly profound. Published at age 87, his Little Red Book became one of the best-selling sports books ever written.",
            teachings: [
                Teaching(
                    title: "Take dead aim",
                    summary: "Pick a precise target — not 'the green,' a leaf on a specific tree behind the flag. Commit completely. Once you've taken aim, there's no room left for doubt. This single phrase is Penick's most famous line for a reason."),
                Teaching(
                    title: "The magic move",
                    summary: "At the top of the backswing, replant your left heel and start the downswing with your lower body. The hands and arms follow. Trying to start down with the upper body is the most common amateur fault and it's the source of slices and pulls."),
                Teaching(
                    title: "Buy lessons, not equipment",
                    summary: "Most golfers will drop $500 on a new driver before $50 on a lesson. Penick had it backwards from the start: clubs follow the swing, not the other way around. The new driver won't fix what a one-hour lesson will."),
                Teaching(
                    title: "Practice with a purpose",
                    summary: "Hitting balls at the range with no target is not practice — it's exercise. Every ball needs a target, a club, a shot shape, and a thought. Twenty balls hit with intention beats two hundred raked across the mat."),
                Teaching(
                    title: "Don't try too hard",
                    summary: "Penick said good golf is played in three-quarter time. Swing within yourself. The hardest swing you can make is rarely the best one — and certainly not the most repeatable."),
            ],
            books: [
                "Harvey Penick's Little Red Book (1992)",
                "And If You Play Golf, You're My Friend (1993)",
                "For All Who Love the Game (1995)",
            ],
            photoAssetName: "HarveyPenick",
            wikipediaURL: "https://en.wikipedia.org/wiki/Harvey_Penick"),

        // MARK: Ben Hogan
        "Ben Hogan": .init(
            name: "Ben Hogan",
            era: "1912–1997",
            specialty: .ballStriking,
            tagline: "9 majors · author of the modern fundamentals",
            bio: "Ben Hogan's Five Lessons is the closest thing golf has to a foundational text. After a near-fatal car crash in 1949, he came back the next year to win the U.S. Open and went on to win six more majors. His dedication to ball-striking and to writing it down clearly made him the teacher of teachers.",
            teachings: [
                Teaching(
                    title: "Grip from the fingers",
                    summary: "The club sits across the fingers of the left hand, not in the palm. The left thumb rides just right of center on the shaft. Grip pressure stays light — Hogan compared it to holding a tube of toothpaste without squeezing any out."),
                Teaching(
                    title: "Build the stance, then the swing",
                    summary: "Feet shoulder-width, slightly flared outward. Knees flexed. Spine tilts from the hips, not the waist. Arms hang naturally. If the setup is right, the swing has somewhere to go; if the setup is wrong, no swing thought can save it."),
                Teaching(
                    title: "Swing on a plane",
                    summary: "Hogan imagined a pane of glass running from the ball through his shoulders. The backswing tracked under the glass; the downswing returned on it. Steeper than the plane and you slice the glass; flatter and you'd hit it. One mental image, two checks."),
                Teaching(
                    title: "Lower body starts the downswing",
                    summary: "The transition isn't an arm move. Hips clear toward the target before the hands move down. If your first move down is with the shoulders or hands, you're over the top — the source of nearly every weak slice in amateur golf."),
                Teaching(
                    title: "Hit through, not at",
                    summary: "The ball is in the way of the swing, not the destination of it. Accelerate through impact toward a full, balanced finish. Hogan's follow-through was the proof of his swing, not the goal."),
            ],
            books: [
                "Five Lessons: The Modern Fundamentals of Golf (1957)",
                "Power Golf (1948)",
            ],
            photoAssetName: "BenHogan",
            wikipediaURL: "https://en.wikipedia.org/wiki/Ben_Hogan"),

        // MARK: Jack Nicklaus
        "Jack Nicklaus": .init(
            name: "Jack Nicklaus",
            era: "b. 1940",
            specialty: .strategy,
            tagline: "18 professional majors · the standard for course management",
            bio: "Jack Nicklaus's record of 18 professional majors is still the benchmark of the modern game. As much as he was a great player, he was a great thinker: his decisions club-by-club, hole-by-hole, were the model for how the game should be played under pressure. Golf My Way captures that thinking in 400 patient pages.",
            teachings: [
                Teaching(
                    title: "Go to the movies",
                    summary: "Before every shot, see it. Visualize the ball flight from impact to landing, including the bounce and roll. Nicklaus said he never hit a shot, even in practice, without first seeing it clearly in his mind. Pick the picture, then swing to match it."),
                Teaching(
                    title: "Run the same routine every time",
                    summary: "Same number of waggles, same look at the target, same pause. The point isn't the specific routine — it's the sameness. Under pressure, routine carries you. Without one, pressure carries you."),
                Teaching(
                    title: "Play within yourself",
                    summary: "If a hole calls for a 9-iron, hit a smooth 9-iron — not a hard pitching wedge. The 85% swing is more reliable, more accurate, and gets the same number on the card. Trouble starts the moment you swing at 100%."),
                Teaching(
                    title: "Know the dead side",
                    summary: "On every approach, identify the side of the green where a miss is unrecoverable — water, deep bunker, OB. Play to the safe side, even if it leaves a harder up-and-down. A 12-foot par putt always beats a drop."),
                Teaching(
                    title: "Lag putts to a circle",
                    summary: "On long putts, don't aim at the cup — aim at a 24-inch circle around it. Two-putt par is the goal; three-putt bogey is the disaster. The cup is too small a target from 50 feet; the circle is just right."),
            ],
            books: [
                "Golf My Way (1974)",
                "Jack Nicklaus' Lesson Tee (1977)",
                "My Story (1997)",
            ],
            photoAssetName: "JackNicklaus",
            wikipediaURL: "https://en.wikipedia.org/wiki/Jack_Nicklaus"),

        // MARK: Lee Trevino
        "Lee Trevino": .init(
            name: "Lee Trevino",
            era: "b. 1939",
            specialty: .ballStriking,
            tagline: "6 majors · self-taught master of the controlled fade",
            bio: "Lee Trevino learned the game on hardpan Texas range balls, with no instructor and no money. He won six majors with a swing every teacher would tell him to fix — and he beat the teachers' students. His fade was so reliable he said he could play 18 holes and never hit a draw on purpose.",
            teachings: [
                Teaching(
                    title: "Open the stance, square the face",
                    summary: "Aim your feet, knees, and hips ten yards left of the target. Set the clubface square to the target — not square to your feet. The body-swing line cuts across the ball; the face direction sends it to the target. Built-in fade, repeatable for life."),
                Teaching(
                    title: "Quiet hands at the top",
                    summary: "The most common amateur fault Trevino fixed was re-gripping at the top. If your hands move, the clubface moves with them. Whatever grip you started with, finish the swing with the same grip."),
                Teaching(
                    title: "Hands lead through impact",
                    summary: "At impact, your hands are ahead of the clubhead, which is ahead of the ball. That sequence compresses the shot and produces a low, penetrating ball flight that holds its line in wind. If the clubhead passes your hands before impact, you've flipped — and you'll add 30 feet of carry to nothing."),
                Teaching(
                    title: "Wedges pay the bills",
                    summary: "Trevino spent more practice time inside 100 yards than anyone of his era. Drives win you fans; wedges win you tournaments. If you're not practicing your half-wedge, three-quarter wedge, and full wedge — three distinct shots — you're leaving strokes on the table."),
                Teaching(
                    title: "Talk through the pressure",
                    summary: "Trevino was famously chatty on the course. He'd talk to fans, joke with his playing partner, narrate his own shots. It wasn't a quirk — it was technique. Bottled-up pressure tightens the swing. A quick conversation between shots resets the breath."),
            ],
            books: [
                "Groove Your Golf Swing My Way (1976)",
                "Swing My Way (1983)",
            ],
            photoAssetName: "LeeTrevino",
            wikipediaURL: "https://en.wikipedia.org/wiki/Lee_Trevino"),

        // MARK: Butch Harmon
        "Butch Harmon": .init(
            name: "Butch Harmon",
            era: "b. 1943",
            specialty: .teaching,
            tagline: "Coached Greg Norman, Tiger Woods, Phil Mickelson, Adam Scott",
            bio: "Butch Harmon — son of 1948 Masters champion Claude Harmon — has coached the world's number one player more often than any other teacher of his generation. His method is athletic, classical, and built around understanding the player in front of him rather than imposing a system. Long considered the gold standard of modern tour coaching.",
            teachings: [
                Teaching(
                    title: "Set up like an athlete",
                    summary: "Knees flexed, weight on the balls of the feet, ready to move. If a defensive back could push you over from behind, you're standing wrong. Athletic posture is the precondition for an athletic swing."),
                Teaching(
                    title: "Big muscles run the show",
                    summary: "Power and consistency come from rotating the shoulders and hips. The hands should feel passive — along for the ride. If you feel your hands swinging the club, you're already off the plane."),
                Teaching(
                    title: "Don't fight your shape",
                    summary: "Most amateurs naturally fade or draw the ball. Don't spend a lifetime trying to play the opposite shape. Build your strategy around your shot — aim where a fade can land, play the right side of doglegs that suit you. Work with what you've got."),
                Teaching(
                    title: "Practice the shot you'll use",
                    summary: "If you spend an hour hitting 7-irons at the range, you've prepared for the one shot you'll hit four times all round. Practice driver, wedge, sand shot, putts inside ten feet. Match the time you spend to the shots you'll actually face."),
                Teaching(
                    title: "Find one coach, stay with them",
                    summary: "Bouncing from instructor to instructor is the fastest way to lose your swing entirely. Every coach sees the swing differently; every fix conflicts with the last fix. Pick one set of eyes you trust. Stay."),
            ],
            books: [
                "The Pro: Lessons About Golf and Life (2007)",
                "Butch Harmon's Playing Lessons (2006)",
            ],
            photoAssetName: "ButchHarmon",
            wikipediaURL: "https://en.wikipedia.org/wiki/Butch_Harmon"),

        // MARK: Dr. Bob Rotella
        "Dr. Bob Rotella": .init(
            name: "Dr. Bob Rotella",
            era: "b. 1949",
            specialty: .mental,
            tagline: "Sport psychologist · coach to dozens of major winners",
            bio: "Bob Rotella is the most influential sport psychologist in modern golf, working with Pádraig Harrington, Tom Kite, Davis Love III, Rory McIlroy and a generation of others. His message is consistent: golf is hard enough without your mind making it harder. His books — particularly Golf Is Not a Game of Perfect — are required reading on tour.",
            teachings: [
                Teaching(
                    title: "Train it, then trust it",
                    summary: "Practice is for technique. The course is for trust. If you're thinking 'don't drop the right elbow' over the ball, you've brought practice onto the course — and you'll swing worse than you do on the range. Pick the shot, commit, swing."),
                Teaching(
                    title: "Pick a target you could hit with a dart",
                    summary: "Don't aim 'at the green.' Aim at a brown spot on the bunker face. Don't aim 'at the flag.' Aim at the bottom inch of the flagstick. The smaller and more specific the target, the better the brain organizes the swing around it."),
                Teaching(
                    title: "Process over outcome",
                    summary: "You can't control whether the ball goes in. You can only control your routine, your target, your commitment. Get those right and the outcomes take care of themselves over time. Get those wrong and even good shots feel lucky."),
                Teaching(
                    title: "Putt with quiet eyes",
                    summary: "On short putts, see the cup as larger than it is. On long putts, see the ball going in from the side. The most common amateur putt is steered — head moving, eyes following — because they don't trust the read. Read it, see it, hit it. Don't watch it."),
                Teaching(
                    title: "Stay in the only hole that exists",
                    summary: "The hole you just played doesn't exist anymore. The hole coming up doesn't exist yet. The only hole is this one, and within it the only shot is this one. The fastest way to ruin a round is to be playing two holes at once in your head."),
            ],
            books: [
                "Golf Is Not a Game of Perfect (1995)",
                "Putting Out of Your Mind (2001)",
                "The Golfer's Mind (2004)",
                "How Champions Think (2015)",
            ],
            photoAssetName: "BobRotella",
            wikipediaURL: nil),

        // MARK: Stan Utley
        "Stan Utley": .init(
            name: "Stan Utley",
            era: "b. 1962",
            specialty: .shortGame,
            tagline: "Modern short-game guru · pioneer of the soft-hands release",
            bio: "Stan Utley spent ten years on the PGA and Champions tours before becoming one of the most respected short-game teachers of his generation. His method emphasizes a soft, releasing stroke that uses the club's natural design — bounce, loft, rhythm — instead of fighting it. His books on putting and chipping are widely adopted.",
            teachings: [
                Teaching(
                    title: "Use the bounce",
                    summary: "The wedge's bounce — the angle on the bottom of the club — is there to glide through grass and sand. Most amateurs dig with the leading edge because they aim the face square. Open the face, let the bounce ride along the turf, and the club does the work."),
                Teaching(
                    title: "Grip pressure 3 out of 10",
                    summary: "Death grip kills feel. On short shots especially, hold the club as if it could slip out at any moment. The lighter the grip, the more the head releases through impact — which is where feel and distance control live."),
                Teaching(
                    title: "The putting stroke is a pendulum",
                    summary: "Wrists stay quiet. Hands stay quiet. The stroke comes from the shoulders rocking like a pendulum, with the arms hanging straight down. If you can feel your wrists working in the stroke, the ball is going to come off the face inconsistently."),
                Teaching(
                    title: "Read from the low side",
                    summary: "Walk to the low side of the cup and crouch. Imagine pouring water from your ball to the hole — which way does it run? That's your break. Reading from behind only shows the path; reading from the side shows the slope."),
                Teaching(
                    title: "Chip like you putt",
                    summary: "From just off the green, take a 7- or 8-iron and use a putting stroke. Carry the ball just onto the green, let it roll the rest. It's almost impossible to mishit — and it gets the ball on the ground and rolling toward the hole sooner than a lob ever will."),
            ],
            books: [
                "The Art of Putting (2006)",
                "The Art of the Short Game (2007)",
                "The Art of Scoring (2008)",
            ],
            photoAssetName: "StanUtley",
            wikipediaURL: "https://en.wikipedia.org/wiki/Stan_Utley"),

        // MARK: Tiger Woods
        "Tiger Woods": .init(
            name: "Tiger Woods",
            era: "b. 1975",
            specialty: .mental,
            tagline: "15 majors · redefined practice, preparation, and pressure",
            bio: "Tiger Woods didn't just dominate the game — he changed how it's prepared for. The athleticism, the fitness, the practice intensity, the course scouting: every modern tour player borrows from his template. The lessons here come from his own writing and from the coaches and competitors who watched him work.",
            teachings: [
                Teaching(
                    title: "Practice with intent",
                    summary: "Every ball at the range had a target, a shape, a club, and a thought. There was no warming up — there was preparation for a specific shot you'd see Thursday. If you finish a range session and can't remember what you worked on, you didn't practice."),
                Teaching(
                    title: "Win the days before the week",
                    summary: "By Wednesday, Tiger had walked every green, mapped every bunker, putted from every likely pin position. Thursday felt like a continuation, not a start. Preparation is invisible to spectators but it's where most tournaments are won."),
                Teaching(
                    title: "Accept the miss, don't compound it",
                    summary: "Bad shots are part of golf. The disaster hole is almost never the bad shot — it's the second bad shot trying to make up for the first. Hit one in the trees, take the punch-out, accept bogey. The double comes from going for the hero shot."),
                Teaching(
                    title: "Train the body that swings the club",
                    summary: "Strength, mobility, and durability are equipment as much as your driver is. Tiger's fitness raised the bar for the whole tour. You don't need a tour-level gym — but core stability, hip mobility, and rotational power are trainable, and they show up in every shot."),
                Teaching(
                    title: "The six inches between your ears",
                    summary: "Earl Woods's phrase: golf is played on a six-inch course between your ears. The physical swing is the easy part — it's been grooved by Saturday morning. The hard part is keeping that swing under control when the moment is big. Mental preparation is half the game, minimum."),
            ],
            books: [
                "How I Play Golf (2001)",
            ],
            photoAssetName: "TigerWoods",
            wikipediaURL: "https://en.wikipedia.org/wiki/Tiger_Woods"),
    ]
}
