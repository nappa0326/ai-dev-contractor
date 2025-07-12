# ブランチ管理システム統合ガイド

## PR監視システムへの統合手順

### 1. 統合場所の特定

PR監視システムのフローは以下の通りです：
```
Webhook → Code → Filter → Switch → Send a message (Review/Completion)
```

**HTTP Requestノードを追加する場所**：Switchノードの「review」出力の後

### 2. 具体的な追加手順

1. **n8nでPR監視システムを開く**

2. **Switchノードを確認**
   - 「review」と「completion」の2つの出力がある
   - 「review」出力がSlackメッセージ送信につながっている

3. **HTTP Requestノードを追加**
   - Switchノードの「review」出力とSlackメッセージノードの間に追加
   - または、Switchノードの「review」出力から並列で接続

### 3. HTTP Requestノードの設定

```json
{
  "parameters": {
    "method": "POST",
    "url": "YOUR_BRANCH_MANAGEMENT_WEBHOOK_URL",
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={\n  \"pr_url\": \"{{ $json.html_url }}\",\n  \"comment_id\": \"{{ $json.comment_id || 'unknown' }}\",\n  \"issue_number\": \"{{ $json.pr_number }}\",\n  \"phase\": \"{{ $json.phase }}\"\n}",
    "options": {}
  },
  "type": "n8n-nodes-base.httpRequest",
  "name": "Call Branch Management"
}
```

### 4. 視覚的な配置

```
                    ┌─[review]─→ HTTP Request → Send Slack Message (Review)
Webhook → Code → Filter → Switch
                    └─[completion]─→ Send Slack Message (Completion)
```

または並列配置：

```
                    ┌─[review]─┬→ Send Slack Message (Review)
                    │          └→ HTTP Request (Branch Check)
Webhook → Code → Filter → Switch
                    └─[completion]─→ Send Slack Message (Completion)
```

### 5. 設定手順（UI操作）

1. **ノードを追加**
   - 左側のノードパネルから「HTTP Request」を検索
   - ワークフローにドラッグ&ドロップ

2. **接続を作成**
   - Switchノードの「review」出力ポイントをクリック
   - HTTP Requestノードの入力ポイントまでドラッグ

3. **HTTP Requestノードを設定**
   - ノードをダブルクリックして設定画面を開く
   - Method: POST
   - URL: ブランチ管理システムのWebhook URL
   - Send Body: ON
   - Body Content Type: JSON
   - JSON Body: 上記のJSONを貼り付け

4. **並列実行の設定（推奨）**
   - HTTP RequestノードとSlackメッセージノードを並列に接続
   - これにより、両方が同時に実行される

### 6. テスト方法

1. **手動テスト**
   - PR監視システムのWebhookノードで「Execute Workflow」
   - テストデータに`@claude-review-needed`を含むコメントを設定

2. **実際のテスト**
   - GitHubでテストPRを作成
   - `@claude-review-needed Phase 2`というコメントを追加
   - Slackとブランチ管理システムの両方が動作することを確認

### 7. 注意事項

- HTTP Requestがエラーになってもワークフロー全体は停止しないように設定
- 「Continue On Fail」オプションを有効にすることを推奨
- ブランチ管理システムのWebhook URLは環境変数で管理することを推奨

### 8. デバッグ

問題が発生した場合：
1. PR監視システムの実行履歴を確認
2. HTTP Requestノードの出力を確認
3. ブランチ管理システムの実行履歴を確認