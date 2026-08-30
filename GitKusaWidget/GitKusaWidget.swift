import AppIntents
import SwiftUI
import WidgetKit

struct KusaConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "GitHubアカウント"
    static let description = IntentDescription("草を表示するGitHubユーザーを設定します。")

    @Parameter(title: "ユーザー名", default: "octocat")
    var username: String
}

struct KusaEntry: TimelineEntry {
    let date: Date
    let username: String
    let days: [ContributionDay]
    let totalCount: Int
    let year: Int
    let errorMessage: String?
}

struct KusaProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> KusaEntry {
        KusaEntry(date: .now, username: "octocat", days: ContributionDay.preview, totalCount: 128, year: Calendar.current.component(.year, from: .now), errorMessage: nil)
    }

    func snapshot(for configuration: KusaConfigurationIntent, in context: Context) async -> KusaEntry {
        await entry(for: configuration)
    }

    func timeline(for configuration: KusaConfigurationIntent, in context: Context) async -> Timeline<KusaEntry> {
        let result = await entry(for: configuration)
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        return Timeline(entries: [result], policy: .after(refresh))
    }

    private func entry(for configuration: KusaConfigurationIntent) async -> KusaEntry {
        let username = GitHubContributionService.normalizedUsername(configuration.username)
        do {
            let snapshot = try await GitHubContributionService.fetch(username: username)
            return KusaEntry(date: .now, username: username, days: snapshot.days, totalCount: snapshot.totalCount, year: snapshot.year, errorMessage: nil)
        } catch {
            return KusaEntry(date: .now, username: username, days: ContributionDay.preview, totalCount: 0, year: Calendar.current.component(.year, from: .now), errorMessage: error.localizedDescription)
        }
    }
}

struct KusaWidgetView: View {
    let entry: KusaEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("@\(entry.username)")
                .font(.headline)
            Spacer(minLength: 0)
            ContributionGrid(
                days: entry.days,
                columns: family == .systemMedium ? 26 : 14,
                cellSize: family == .systemMedium ? 8 : 7,
                spacing: 2
            )
            .frame(maxWidth: .infinity, alignment: .center)
            Spacer(minLength: 0)
            if let message = entry.errorMessage {
                Text(message).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            } else {
                Text("\(entry.totalCount) contributions in \(String(entry.year))")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

@main
struct GitKusaWidget: Widget {
    let kind = "GitKusaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: KusaConfigurationIntent.self, provider: KusaProvider()) { entry in
            KusaWidgetView(entry: entry)
        }
        .configurationDisplayName("Git Kusa")
        .description("GitHubの草をデスクトップに表示します。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
