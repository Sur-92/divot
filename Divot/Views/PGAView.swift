import SwiftUI

struct PGAView: View {
    @State private var tournaments: [PGATournament] = []
    @State private var articles: [PGAArticle] = []
    @State private var featuredTournament: PGATournament?
    @State private var featuredCourseInfo: PGACourseInfo?
    @State private var weather: WeatherSnapshot?
    @State private var isLoading = false
    @State private var errorText: String?

    // Derived groupings
    private var live: PGATournament? {
        tournaments.first(where: { $0.isLive })
    }
    private var upcoming: [PGATournament] {
        tournaments.filter { $0.isUpcoming }.prefix(4).map { $0 }
    }
    private var recent: [PGATournament] {
        tournaments.filter { $0.isComplete }.sorted { $0.endDate > $1.endDate }.prefix(6).map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                if isLoading && tournaments.isEmpty {
                    loadingState
                } else if let errorText {
                    errorState(errorText)
                } else {
                    if let live {
                        liveSection(live)
                    } else if let next = upcoming.first {
                        nextUpSection(next)
                    }

                    if featuredCourseInfo != nil || weather != nil {
                        courseInfoSection
                    }

                    if upcoming.count > (live == nil ? 1 : 0) {
                        upcomingSection
                    }

                    if !recent.isEmpty {
                        recentSection
                    }

                    if !articles.isEmpty {
                        newsSection
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .onAppear { Task { await load() } }
        .refreshable { await load(force: true) }
    }

    // MARK: - Course info + weather

    private var courseInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Course Info",
                         subtitle: "This week's venue · designer · layout · live weather")
            VStack(spacing: 0) {
                if let info = featuredCourseInfo {
                    if !info.designer.isEmpty && info.designer != "varies by year" {
                        courseInfoRow(icon: "pencil.and.ruler.fill", label: "DESIGNER",
                                       value: info.designer)
                        courseInfoDivider
                    }
                    if info.yearOpened > 0 {
                        let city = featuredTournament?.city ?? ""
                        let value = city.isEmpty
                            ? "\(info.yearOpened)"
                            : "\(info.yearOpened)  ·  \(city)"
                        courseInfoRow(icon: "calendar", label: "OPENED",
                                       value: value)
                        courseInfoDivider
                    }
                    if info.par > 0 && info.yardage > 0 {
                        courseInfoRow(icon: "flag.fill", label: "LAYOUT",
                                       value: "Par \(info.par) · \(info.yardage) yards")
                        courseInfoDivider
                    } else if info.par > 0 {
                        courseInfoRow(icon: "flag.fill", label: "PAR",
                                       value: "\(info.par)")
                        courseInfoDivider
                    }
                }

                if let w = weather {
                    weatherRow(w)
                }
            }
            .glassPanel(padding: 0)
        }
    }

    private var courseInfoDivider: some View {
        Rectangle().fill(Theme.hairline.opacity(0.5)).frame(height: 1)
    }

    private func courseInfoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.accent)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Theme.dim)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.primaryText)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private func weatherRow(_ w: WeatherSnapshot) -> some View {
        HStack(spacing: 14) {
            Image(systemName: w.conditionIcon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.accent)
                .frame(width: 20)
            Text("WEATHER")
                .font(.system(size: 9, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Theme.dim)
                .frame(width: 92, alignment: .leading)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(String(format: "%.0f°F", w.temperatureF))
                    .font(.system(size: 18, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.primaryText)
                Text(w.conditionLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.dim)
                if let feels = w.feelsLikeF, abs(feels - w.temperatureF) >= 2 {
                    Text("· feels \(Int(feels))°")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.dimmer)
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: 14) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("WIND")
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.dim)
                    Text("\(Int(w.windMph.rounded())) mph \(w.windCompass)")
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.primaryText)
                }
                if let h = w.humidityPct {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("HUMIDITY")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Theme.dim)
                        Text("\(Int(h.rounded()))%")
                            .font(.system(size: 12, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Theme.primaryText)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - News feed

    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Tour News", subtitle: "Latest from ESPN's PGA feed")
            VStack(spacing: 10) {
                ForEach(articles.prefix(8)) { article in
                    NewsArticleRow(article: article)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("PGA TOUR")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Theme.accent)
                Text("Live leaderboards. Past results. What's next.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 1.5)
                    .padding(.top, 2)
            }
            Spacer()

            Button {
                Task { await load(force: true) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold))
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(isLoading
                                   ? .linear(duration: 1).repeatForever(autoreverses: false)
                                   : .default,
                                   value: isLoading)
                    Text("REFRESH")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .stroke(Theme.accent, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
    }

    // MARK: - Live section

    private func liveSection(_ t: PGATournament) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Live", subtitle: "In progress right now")

            VStack(alignment: .leading, spacing: 0) {
                tournamentHeroHeader(t, statusColor: .green)

                Rectangle().fill(Theme.hairline).frame(height: 1).padding(.top, 18)

                if t.leaderboard.isEmpty {
                    Text("Leaderboard not yet posted.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.dim)
                        .padding(.top, 14)
                } else {
                    leaderboardHeader
                    ForEach(Array(t.leaderboard.prefix(10).enumerated()), id: \.element.id) { i, entry in
                        leaderboardRow(entry, index: i, highlightLeader: true)
                    }
                }
            }
            .glassPanel(cornerRadius: 6, padding: 22)
        }
    }

    // MARK: - Next-up section

    private func nextUpSection(_ t: PGATournament) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Next Up", subtitle: "No tournament live — here's what's next")
            tournamentHeroHeader(t, statusColor: Theme.accent)
                .glassPanel(cornerRadius: 6, padding: 22)
        }
    }

    // MARK: - Upcoming section

    private var upcomingSection: some View {
        let items = live == nil ? Array(upcoming.dropFirst()) : upcoming
        return VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Upcoming",
                         subtitle: "Next \(items.count) \(items.count == 1 ? "stop" : "stops") on tour")
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, t in
                    tournamentCompactRow(t)
                    if index < items.count - 1 {
                        Rectangle().fill(Theme.hairline.opacity(0.5)).frame(height: 1)
                    }
                }
            }
            .glassPanel(padding: 0)
        }
    }

    // MARK: - Recent section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Recent Tournaments",
                         subtitle: "Top 10 finishers from each")
            VStack(spacing: 14) {
                ForEach(recent) { t in
                    RecentTournamentCard(tournament: t)
                }
            }
        }
    }

    // MARK: - Hero header

    private func tournamentHeroHeader(_ t: PGATournament, statusColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top row — status / name / date / leader
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Circle().fill(statusColor).frame(width: 8, height: 8)
                        Text(t.status.displayLabel)
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2.5)
                            .foregroundStyle(statusColor)
                    }
                    Text(t.name.uppercased())
                        .font(.system(size: 22, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Theme.primaryText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("DATES")
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.dim)
                    Text(t.dateRange)
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.primaryText)
                    if t.isLive, let leader = t.leaderboard.first {
                        Text("LEADER")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(Theme.dim)
                            .padding(.top, 6)
                        Text(leader.player.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(Theme.accent)
                        Text(leader.toPar)
                            .font(.system(size: 16, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(Theme.accent)
                    }
                }
            }

            // Location block — dedicated
            if !t.venue.isEmpty || !t.city.isEmpty {
                HStack(alignment: .top, spacing: 16) {
                    locationField(label: "VENUE", value: t.venue, systemImage: "mappin.and.ellipse")
                    if !t.city.isEmpty {
                        locationField(label: "LOCATION", value: t.city, systemImage: "globe.americas")
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func locationField(label: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 12))
                .foregroundStyle(Theme.accent)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.dim)
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 3)
            .stroke(Theme.hairline, lineWidth: 1))
    }

    // MARK: - Leaderboard rows

    private var leaderboardHeader: some View {
        HStack(spacing: 0) {
            Text("POS")     .frame(width: 42, alignment: .leading)
            Text("WR")      .frame(width: 36, alignment: .center)
            Text("PLAYER")  .frame(maxWidth: .infinity, alignment: .leading)
            Text("R1")      .frame(width: 36, alignment: .trailing)
            Text("R2")      .frame(width: 36, alignment: .trailing)
            Text("R3")      .frame(width: 36, alignment: .trailing)
            Text("R4")      .frame(width: 36, alignment: .trailing)
            Text("TOT")     .frame(width: 44, alignment: .trailing)
            Text("TO PAR")  .frame(width: 62, alignment: .trailing)
            Text("THRU")    .frame(width: 50, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .semibold))
        .tracking(2)
        .foregroundStyle(Theme.accent)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private func leaderboardRow(_ entry: PGALeaderboardEntry, index: Int, highlightLeader: Bool) -> some View {
        let highlight = index == 0 && highlightLeader
        return HStack(spacing: 0) {
            Text(entry.position)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(highlight ? Theme.accent : Theme.primaryText)
                .frame(width: 42, alignment: .leading)
            worldRankPill(entry.worldRanking)
                .frame(width: 36)
            Text(entry.player)
                .font(.system(size: 13, weight: index == 0 ? .semibold : .regular))
                .foregroundStyle(highlight ? Theme.accent : Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            roundCell(entry.roundScores[0])
            roundCell(entry.roundScores[1])
            roundCell(entry.roundScores[2])
            roundCell(entry.roundScores[3])
            Text(entry.total > 0 ? "\(entry.total)" : "—")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.primaryText)
                .frame(width: 44, alignment: .trailing)
            Text(entry.toPar)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(entry.toPar.hasPrefix("-") ? Theme.accent : Theme.primaryText)
                .frame(width: 62, alignment: .trailing)
            Text(entry.thru)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.dim)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .background(index.isMultiple(of: 2) ? Color.white.opacity(0.04) : Color.clear)
    }

    private func roundCell(_ score: Int) -> some View {
        Text(score > 0 ? "\(score)" : "—")
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(score > 0 ? Theme.primaryText : Theme.dimmer)
            .frame(width: 36, alignment: .trailing)
    }

    @ViewBuilder
    private func worldRankPill(_ rank: Int?) -> some View {
        if let rank {
            Text("#\(rank)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .stroke(Theme.accent.opacity(0.5), lineWidth: 1))
        } else {
            Text("—")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Theme.dimmer)
        }
    }

    // MARK: - Compact upcoming row

    private func tournamentCompactRow(_ t: PGATournament) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(t.name.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if !t.venue.isEmpty {
                        Text(t.venue)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.dim)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            Text(t.dateRange)
                .font(.system(size: 11, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    // MARK: - Loading / error

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Theme.accent)
            Text("LOADING TOUR DATA…")
                .font(.system(size: 11, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.dim)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(Color.red.opacity(0.8))
            Text("COULDN'T LOAD TOUR DATA")
                .font(.system(size: 11, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.primaryText)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
                .multilineTextAlignment(.center)
            Button("TRY AGAIN") {
                Task { await load(force: true) }
            }
            .buttonStyle(.plain)
            .font(.system(size: 10, weight: .semibold))
            .tracking(2)
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .overlay(RoundedRectangle(cornerRadius: 3)
                .stroke(Theme.accent, lineWidth: 1))
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .glassPanel(padding: 32)
    }

    // MARK: - Load

    @MainActor
    private func load(force: Bool = false) async {
        isLoading = true
        errorText = nil
        async let boardTask = PGAService.shared.fetchTournaments(forceRefresh: force)
        async let newsTask: [PGAArticle] = (try? await PGAService.shared.fetchNews(forceRefresh: force)) ?? []

        do {
            tournaments = try await boardTask
            articles = await newsTask
        } catch let urlError as URLError {
            errorText = urlError.friendlyText
            isLoading = false
            return
        } catch {
            errorText = error.localizedDescription
            isLoading = false
            return
        }

        // Post-fetch: pick the featured tournament (live preferred, else next upcoming).
        let featured = tournaments.first(where: \.isLive)
            ?? tournaments.first(where: \.isUpcoming)
        featuredTournament = featured

        if let featured {
            featuredCourseInfo = PGAService.courseInfo(for: featured)

            // Weather — only if we have stored course coordinates.
            // Silent-fail with try? so a weather blip never nukes the page.
            if let info = featuredCourseInfo,
               info.latitude != 0 || info.longitude != 0 {
                weather = try? await PGAService.shared.fetchWeather(
                    latitude: info.latitude, longitude: info.longitude
                )
            } else {
                weather = nil
            }
        } else {
            featuredCourseInfo = nil
            weather = nil
        }

        isLoading = false
    }
}

// MARK: - News article row

struct NewsArticleRow: View {
    let article: PGAArticle
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let url = article.webURL { openURL(url) }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                // Thumbnail
                if let imageURL = article.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Rectangle().fill(Theme.hairline)
                        }
                    }
                    .frame(width: 90, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                } else {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(width: 90, height: 60)
                        .overlay(Image(systemName: "newspaper")
                            .foregroundStyle(Theme.dim))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(article.headline)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if !article.description.isEmpty {
                        Text(article.description)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.dim)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    HStack(spacing: 8) {
                        Text(article.byline.uppercased())
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Theme.accent)
                        Text("·")
                            .foregroundStyle(Theme.dim)
                        Text(article.relativeTimestamp)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Theme.dim)
                        if article.webURL != nil {
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.dim)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassPanel(cornerRadius: 4, padding: 0)
        .help(article.webURL != nil ? "Open in browser" : "")
    }
}

// MARK: - Recent tournament card (top 10 expandable)

struct RecentTournamentCard: View {
    let tournament: PGATournament
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                expanded.toggle()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 14)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(tournament.name.uppercased())
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(Theme.primaryText)
                            .lineLimit(1)
                        if let winner = tournament.leaderboard.first {
                            HStack(spacing: 6) {
                                Text("WINNER:")
                                    .font(.system(size: 9, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundStyle(Theme.dim)
                                Text(winner.player)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                                Text(winner.toPar)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                    }
                    Spacer()
                    Text(tournament.dateRange)
                        .font(.system(size: 10, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.dim)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                Rectangle().fill(Theme.hairline).frame(height: 1).padding(.top, 12)
                expandedLeaderboard
            }
        }
        .glassPanel(cornerRadius: 6, padding: 18)
    }

    private var expandedLeaderboard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("POS")    .frame(width: 40, alignment: .leading)
                Text("PLAYER") .frame(maxWidth: .infinity, alignment: .leading)
                Text("R1")     .frame(width: 34, alignment: .trailing)
                Text("R2")     .frame(width: 34, alignment: .trailing)
                Text("R3")     .frame(width: 34, alignment: .trailing)
                Text("R4")     .frame(width: 34, alignment: .trailing)
                Text("TOT")    .frame(width: 42, alignment: .trailing)
                Text("SCORE")  .frame(width: 58, alignment: .trailing)
            }
            .font(.system(size: 9, weight: .semibold))
            .tracking(2)
            .foregroundStyle(Theme.accent)
            .padding(.vertical, 6)

            ForEach(Array(tournament.leaderboard.prefix(10).enumerated()), id: \.element.id) { i, entry in
                HStack(spacing: 0) {
                    Text(entry.position)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(i == 0 ? Theme.accent : Theme.primaryText)
                        .frame(width: 40, alignment: .leading)
                    Text(entry.player)
                        .font(.system(size: 12, weight: i == 0 ? .semibold : .regular))
                        .foregroundStyle(i == 0 ? Theme.accent : Theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                    miniRoundCell(entry.roundScores[0])
                    miniRoundCell(entry.roundScores[1])
                    miniRoundCell(entry.roundScores[2])
                    miniRoundCell(entry.roundScores[3])
                    Text(entry.total > 0 ? "\(entry.total)" : "—")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.primaryText)
                        .frame(width: 42, alignment: .trailing)
                    Text(entry.toPar)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(entry.toPar.hasPrefix("-") ? Theme.accent : Theme.primaryText)
                        .frame(width: 58, alignment: .trailing)
                }
                .padding(.vertical, 5)
                .background(i.isMultiple(of: 2) ? Color.white.opacity(0.04) : Color.clear)
            }
        }
    }

    private func miniRoundCell(_ score: Int) -> some View {
        Text(score > 0 ? "\(score)" : "—")
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(score > 0 ? Theme.primaryText : Theme.dimmer)
            .frame(width: 34, alignment: .trailing)
    }
}
