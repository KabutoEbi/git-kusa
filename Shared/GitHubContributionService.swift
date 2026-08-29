import Foundation

enum ContributionError: LocalizedError {
    case invalidUsername
    case notFound
    case invalidResponse
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidUsername: "GitHubユーザー名を確認してください。"
        case .notFound: "GitHubユーザーが見つかりませんでした。"
        case .invalidResponse: "GitHubからデータを取得できませんでした。"
        case .noData: "プロフィールから草データを読み取れませんでした。"
        }
    }
}

enum GitHubContributionService {
    static func fetch(username: String) async throws -> ContributionSnapshot {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")
        let year = Calendar.current.component(.year, from: Date())
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.calendar = Calendar(identifier: .gregorian)
        dayFormatter.dateFormat = "yyyy-MM-dd"
        let today = dayFormatter.string(from: Date())
        guard !username.isEmpty, username.rangeOfCharacter(from: allowed.inverted) == nil,
              let url = URL(string: "https://github.com/users/\(username)/contributions?from=\(year)-01-01&to=\(today)") else {
            throw ContributionError.invalidUsername
        }

        var request = URLRequest(url: url)
        request.setValue("GitKusa/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ContributionError.invalidResponse }
        if http.statusCode == 404 { throw ContributionError.notFound }
        guard (200..<300).contains(http.statusCode), let html = String(data: data, encoding: .utf8) else {
            throw ContributionError.invalidResponse
        }
        let result = parse(html: html)
        guard !result.isEmpty else { throw ContributionError.noData }
        return ContributionSnapshot(days: result, totalCount: parseTotal(html: html), year: year)
    }

    static func parseTotal(html: String) -> Int {
        let pattern = #"([0-9,]+)\s+contributions?\s+in\s+(?:the last year|[0-9]{4})"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..<html.endIndex, in: html)),
              let countRange = Range(match.range(at: 1), in: html) else { return 0 }
        return Int(html[countRange].replacingOccurrences(of: ",", with: "")) ?? 0
    }

    static func parse(html: String) -> [ContributionDay] {
        let pattern = #"<(?:td|rect)\b[^>]*\bdata-date=\"([^\"]+)\"[^>]*\bdata-level=\"([0-4])\"[^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"

        return regex.matches(in: html, range: range).compactMap { match in
            guard let dateRange = Range(match.range(at: 1), in: html),
                  let levelRange = Range(match.range(at: 2), in: html),
                  let date = formatter.date(from: String(html[dateRange])) else { return nil }
            let level = Int(html[levelRange]) ?? 0
            return ContributionDay(date: date, count: level == 0 ? 0 : level, level: level)
        }.sorted { $0.date < $1.date }
    }
}
