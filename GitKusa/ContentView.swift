import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var username = ""
    @State private var days: [ContributionDay] = ContributionDay.preview
    @State private var status = "ウィジェットを追加してユーザー名を設定してください"
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.green)
                VStack(alignment: .leading) {
                    Text("Git Kusa").font(.largeTitle.bold())
                    Text("GitHubの草をデスクトップに。")
                        .foregroundStyle(.secondary)
                }
            }

            ContributionGrid(days: days, columns: 26, cellSize: 9, spacing: 3)
                .frame(height: 80)
                .padding(14)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

            HStack {
                TextField("GitHubユーザー名", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(loadPreview)
                Button(isLoading ? "取得中…" : "プレビュー", action: loadPreview)
                    .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }

            Text(status)
                .font(.callout)
                .foregroundStyle(.secondary)

            Divider()

            Text("設定方法").font(.headline)
            Text("デスクトップを右クリック →「ウィジェットを編集」→ Git Kusa を追加。追加後にウィジェットを右クリックし、ユーザー名を設定します。")
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(width: 520)
    }

    private func loadPreview() {
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        isLoading = true
        status = "@\(name) のデータを取得しています…"
        Task {
            do {
                let fetched = try await GitHubContributionService.fetch(username: name)
                await MainActor.run {
                    days = fetched.days
                    status = "@\(name)・\(fetched.year)年 \(fetched.totalCount) contributions"
                    isLoading = false
                    WidgetCenter.shared.reloadTimelines(ofKind: "GitKusaWidget")
                }
            } catch {
                await MainActor.run {
                    status = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
