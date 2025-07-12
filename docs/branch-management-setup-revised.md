# ブランチ管理システム セットアップガイド（修正版）

## 重要な修正点

元のワークフローには以下の問題がありましたので、修正版を使用してください：

1. **トリガーの欠如** - Webhookトリガーを追加
2. **接続の重複** - データフローを整理
3. **データ結合の問題** - Mergeノードで適切に処理
4. **エラーハンドリング** - 配列処理を安全に

## セットアップ手順

### 1. n8nへのインポート

1. n8nの管理画面にアクセス
2. 「ワークフロー」→「新規作成」を選択
3. 左上のメニューから「インポート from file」を選択
4. **`n8n-workflows/ブランチ管理システム_修正版.json`を選択**（修正版を使用）

### 2. 認証情報の設定

#### 重要：認証情報IDの置換

インポート後、以下の手順で認証情報を設定：

1. **GitHub API認証情報**
   - 各HTTPリクエストノードを開く
   - `{{githubCredentialId}}`を実際のGitHub認証情報に置き換え
   - または新規作成：
     - 「Credentials」→「New」→「GitHub API」
     - Personal Access Token（repo権限必要）を設定

2. **Slack API認証情報**
   - 既存のSlack認証情報が自動的に適用されるはず
   - されない場合は手動で選択

### 3. Webhook URLの取得

1. ワークフローを保存
2. 「Webhook Trigger」ノードをクリック
3. 表示されるWebhook URLをコピー
   - 例: `https://your-n8n-instance.com/webhook/branch-check`

### 4. 既存ワークフローへの統合

「Github PR監視システム」に以下のHTTPリクエストノードを追加：

```json
{
  "parameters": {
    "method": "POST",
    "url": "YOUR_WEBHOOK_URL_HERE",
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={\n  \"pr_url\": \"{{ $json.pull_request.html_url }}\",\n  \"comment_id\": \"{{ $json.comment.id }}\",\n  \"issue_number\": \"{{ $json.issue.number }}\"\n}",
    "options": {}
  },
  "type": "n8n-nodes-base.httpRequest",
  "name": "Call Branch Management"
}
```

### 5. テスト手順

1. **手動テスト**
   - Webhook Triggerノードで「Execute Workflow」をクリック
   - テストデータを送信：
   ```json
   {
     "pr_url": "https://github.com/ai-development-company/projects/pull/24",
     "comment_id": "12345678",
     "issue_number": "24"
   }
   ```

2. **動作確認**
   - Phase 2以降のコメントでブランチチェックが動作するか
   - Slackに通知が送信されるか
   - GitHubにコメントが追加されるか

## トラブルシューティング

### 認証エラーが出る場合
- GitHub/Slack認証情報が正しく設定されているか確認
- Personal Access Tokenの権限を確認

### Webhookが動作しない場合
- Webhook URLが正しくコピーされているか確認
- n8nインスタンスが外部からアクセス可能か確認

### データが正しく処理されない場合
- 各Codeノードの実行結果を確認
- エラーログを確認

## 注意事項

- GitHub APIレート制限に注意（認証済みで5000回/時）
- 大規模リポジトリではブランチ一覧取得に時間がかかる可能性
- Webhook URLは機密情報として扱う