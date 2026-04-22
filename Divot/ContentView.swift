import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: NavSection? = .rounds

    enum NavSection: String, CaseIterable, Identifiable, Hashable {
        case rounds = "Rounds"
        case practice = "Practice"
        case courses = "Courses"
        case clubs = "Clubs"
        case pga = "PGA"
        case stats = "Stats"
        case handicap = "Handicap"
        case audit = "Audit"

        var id: String { rawValue }
        var systemImage: String {
            switch self {
            case .rounds:   return "flag.fill"
            case .practice: return "figure.golf"
            case .courses:  return "map.fill"
            case .clubs:    return "bag.fill"
            case .pga:      return "trophy.fill"
            case .stats:    return "chart.bar.fill"
            case .handicap: return "figure.golf.circle"
            case .audit:    return "checkmark.shield.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            Group {
                switch selection ?? .rounds {
                case .rounds:   RoundsListView()
                case .practice: PracticeListView()
                case .courses:  CoursesView()
                case .clubs:    ClubsView()
                case .pga:      PGAView()
                case .stats:    StatsView()
                case .handicap: HandicapView()
                case .audit:    AuditLogView()
                }
            }
            .scrollContentBackground(.hidden)
            .background(detailBackdrop)
        }
        .background(appBackdrop)
    }

    // MARK: - Backdrops

    private var appBackdrop: some View {
        ZStack {
            Image("Background")
                .resizable()
                .scaledToFill()
            LinearGradient(
                colors: [
                    .black.opacity(0.50),
                    .black.opacity(0.32),
                    .black.opacity(0.55)
                ],
                startPoint: .top, endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private var detailBackdrop: some View {
        Color.black.opacity(0.08)
            .ignoresSafeArea()
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Traffic-light spacer (no title bar means window controls need room)
            Color.clear.frame(height: 28)

            brandHeader

            gradientDivider

            // Nav items
            List(selection: $selection) {
                ForEach(NavSection.allCases) { item in
                    SidebarRow(item: item, isSelected: selection == item)
                        .tag(item)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.sidebar)
            .environment(\.defaultMinListRowHeight, 38)

            Spacer(minLength: 0)
            gradientDivider
            footer
        }
        .frame(minWidth: 220, idealWidth: 240, maxWidth: 280)
        .background(sidebarBackdrop)
    }

    private var sidebarBackdrop: some View {
        // Rich translucent navy — still lets the background image show through
        let deepNavy   = Color(red: 0.04, green: 0.10, blue: 0.22)
        let midNavy    = Color(red: 0.06, green: 0.14, blue: 0.30)
        let brightBlue = Color(red: 0.10, green: 0.22, blue: 0.42)

        return ZStack {
            // Frosted glass underneath
            Rectangle().fill(.ultraThinMaterial.opacity(0.35))

            // Blue gradient — deeper at the top + bottom, brighter in the middle
            LinearGradient(
                colors: [
                    deepNavy.opacity(0.65),
                    midNavy.opacity(0.55),
                    brightBlue.opacity(0.45),
                    midNavy.opacity(0.55),
                    deepNavy.opacity(0.65)
                ],
                startPoint: .top, endPoint: .bottom
            )

            // Subtle diagonal sheen for depth
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.clear, Color.black.opacity(0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // Amber side-glow along the right edge (keeps the brand accent alive)
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(
                    colors: [Color.clear, Theme.accent.opacity(0.10)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 32)
            }
        }
        .ignoresSafeArea()
    }

    private var gradientDivider: some View {
        LinearGradient(
            colors: [Theme.accent.opacity(0.45), Theme.hairline, Color.clear],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(height: 1)
        .padding(.horizontal, 12)
    }

    private var brandHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DIVOT")
                .font(.system(size: 26, weight: .bold))
                .tracking(8)
                .foregroundStyle(Theme.primaryText)
            HStack(spacing: 6) {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 14, height: 1.5)
                Text("YARDAGE BOOK")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
            HStack {
                Text("V 0.1")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Theme.dimmer)
                Spacer()
                Text("BUILT FOR THE SHORT GAME")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Theme.accent.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Sidebar row

struct SidebarRow: View {
    let item: ContentView.NavSection
    let isSelected: Bool

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar — amber block when selected
            Rectangle()
                .fill(isSelected ? Theme.accent : Color.clear)
                .frame(width: 3)
                .shadow(color: isSelected ? Theme.accent.opacity(0.6) : .clear,
                        radius: 6, x: 0, y: 0)

            HStack(spacing: 12) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .frame(width: 22)
                    .foregroundStyle(isSelected ? Theme.accent : Theme.dim)
                    .shadow(color: isSelected ? Theme.accent.opacity(0.5) : .clear,
                            radius: 6)
                Text(item.rawValue.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.5)
                    .foregroundStyle(isSelected
                                     ? Theme.primaryText
                                     : (isHovering ? Theme.primaryText : Theme.dim))
                Spacer(minLength: 0)
            }
            .padding(.leading, 12)
            .padding(.trailing, 10)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    LinearGradient(
                        colors: [Theme.accent.opacity(0.16), Theme.accent.opacity(0.02)],
                        startPoint: .leading, endPoint: .trailing
                    )
                } else if isHovering {
                    Color.white.opacity(0.04)
                }
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isSelected)
        .animation(.easeOut(duration: 0.12), value: isHovering)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Round.self, Hole.self], inMemory: true)
        .frame(width: 1100, height: 700)
}
