import SwiftUI

struct ContributionGrid: View {
    let days: [ContributionDay]
    let columns: Int
    let cellSize: CGFloat
    let spacing: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let currentWeekSunday = calendar.date(
            byAdding: .day,
            value: -(calendar.component(.weekday, from: today) - 1),
            to: today
        ) ?? today
        let firstSunday = calendar.date(byAdding: .day, value: -(columns - 1) * 7, to: currentWeekSunday) ?? currentWeekSunday
        let daysByDate = Dictionary(uniqueKeysWithValues: days.map { (calendar.startOfDay(for: $0.date), $0) })

        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { column in
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { row in
                        let date = calendar.date(byAdding: .day, value: column * 7 + row, to: firstSunday) ?? firstSunday
                        let day = date <= today ? daysByDate[date] : nil
                        RoundedRectangle(cornerRadius: 2)
                            .fill(date <= today ? KusaColor.color(for: day?.level ?? 0, scheme: colorScheme) : Color.clear)
                            .frame(width: cellSize, height: cellSize)
                            .help(day.map(helpText) ?? "")
                    }
                }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func helpText(for day: ContributionDay) -> String {
        let date = day.date.formatted(date: .abbreviated, time: .omitted)
        return day.level == 0 ? "\(date): contributionsなし" : "\(date): level \(day.level)"
    }
}
