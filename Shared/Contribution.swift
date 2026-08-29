import Foundation
import SwiftUI

struct ContributionDay: Identifiable, Hashable, Sendable {
    let date: Date
    let count: Int
    let level: Int

    var id: Date { date }

    static var preview: [ContributionDay] {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        return (0..<182).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - 181, to: today) else { return nil }
            let level = (offset * 17 + offset / 7) % 5
            return ContributionDay(date: date, count: level * 2, level: level)
        }
    }
}

struct ContributionSnapshot: Sendable {
    let days: [ContributionDay]
    let totalCount: Int
    let year: Int
}

enum KusaColor {
    static func color(for level: Int, scheme: ColorScheme) -> Color {
        if level == 0 { return scheme == .dark ? Color.white.opacity(0.09) : Color.black.opacity(0.07) }
        return [Color.clear, Color(red: 0.24, green: 0.77, blue: 0.38), Color(red: 0.15, green: 0.64, blue: 0.30), Color(red: 0.06, green: 0.48, blue: 0.22), Color(red: 0.02, green: 0.34, blue: 0.15)][min(level, 4)]
    }
}
