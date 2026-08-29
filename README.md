# Git Kusa

GitHub の contribution graph（草）を macOS のデスクトップに表示する WidgetKit アプリです。

## 必要環境

- macOS 14 以降
- Xcode 15 以降

## 起動方法

1. `GitKusa.xcodeproj` を Xcode で開きます。
2. `GitKusa` scheme を選んで実行します。
3. デスクトップを右クリックし、「ウィジェットを編集」を選びます。
4. `Git Kusa` を追加します。
5. ウィジェットを右クリックして「Git Kusaを編集」から GitHub ユーザー名を入力します。

公開プロフィールの contribution graph を利用するため、GitHub token は不要です。プロフィールが非公開の場合やネットワークに接続できない場合は、直前に取得した表示またはエラー表示になります。

