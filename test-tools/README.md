# Slackボタンテスト手順

## URLの確認
- GitHub Webhook (テスト): `https://n8n.oppy-ai.com/webhook-test/github-pr-comments`
- Slack Interactive (テスト): `https://n8n.oppy-ai.com/webhook-test/slack-interactive`

## テスト手順

### 1. GitHubイベントをシミュレート
```bash
./test-github-webhook.sh 42
```

### 2. Slackでボタン表示を確認
- #ai-developmentチャンネルに通知が表示される
- ボタンが2つ表示される

### 3. ボタンクリックテスト
- 「✅ 承認して続行」または「📝 修正を依頼」をクリック
- n8nのテスト環境でリクエストを受信
- Slackメッセージが更新される

## 注意事項
- テスト環境ではGitHubへの実際のコメント投稿は行われません
- Slack App設定でInteractive URLがテスト用URLに設定されていることを確認