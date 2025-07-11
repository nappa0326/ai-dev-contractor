# n8n Webhookのテスト方法ガイド

## GitHubからのWebhookをテストする具体的な手順

### 重要な前提知識

- **「Execute Workflow」ボタンは使えません** - Webhookは外部からのリクエストを待つため
- **Test URLとProduction URLの2種類**があります
- **Test Webhookは120秒間**しか待機しません

## 開発時のテスト方法（推奨）

### 1. Test Webhookを使用

1. **n8nでWebhookノードを選択**
   - ノードをクリックして選択状態にする

2. **「Listen For Test Event」ボタンをクリック**
   - ボタンが「Listening for test event...」に変わる
   - カウントダウンが始まる（120秒）

3. **Test Webhook URLを確認**
   - Webhookノードの上部に表示される
   - 例：`https://n8n.oppy-ai.com/webhook-test/github-pr-comments`
   - このURLは一時的なもの

4. **GitHubから実際のデータを送信**

   **方法A: Recent Deliveriesから再送信**
   ```
   1. GitHub → Settings → Webhooks
   2. 設定済みのWebhookをクリック
   3. 「Recent Deliveries」タブ
   4. 任意のdeliveryの「...」→「Redeliver」
   5. ポップアップで「Yes, redeliver this payload」
   ```

   **方法B: 新規にコメントを投稿**
   ```
   1. PRページでコメントを投稿
   2. テスト用のコメント例：
      "テストコメント @claude-review-needed"
   ```

5. **n8nで受信を確認**
   - Webhookノードに緑のチェックマーク
   - 「Output」タブで受信データを確認
   - headers、body、queryなどが表示される

### 2. デバッグのポイント

**受信データの確認方法：**
```javascript
// Webhookノードの出力例
{
  "headers": {
    "x-github-event": "issue_comment",
    "x-github-delivery": "12345-67890",
    "content-type": "application/json"
  },
  "body": {
    "action": "created",
    "issue": {
      "number": 42,
      "pull_request": { ... }
    },
    "comment": {
      "body": "テストコメント @claude-review-needed"
    }
  }
}
```

## 本番環境でのテスト方法

### 1. Production Webhookを使用

1. **ワークフローを保存してActive化**
   - 「Save」ボタン → 「Active」トグルON

2. **Production URLをGitHubに設定**
   - Webhookノードの「PRODUCTION URL」をコピー
   - GitHubのWebhook設定で使用

3. **実際のイベントで動作確認**
   - PRにコメントを投稿
   - n8nの「Executions」メニューで確認

### 2. Execution履歴の確認

**成功時の確認ポイント：**
- Status: Success（緑のチェック）
- 各ノードが正しく実行されている
- Slackに通知が届いている

**失敗時の確認ポイント：**
- Status: Error（赤の×）
- どのノードでエラーが発生したか
- エラーメッセージの内容

## トラブルシューティング

### Webhookが受信されない場合

1. **n8n側の確認**
   ```
   □ ワークフローがActiveになっているか
   □ Webhookノードが正しく設定されているか
   □ URLが正しくコピーされているか
   ```

2. **GitHub側の確認**
   ```
   □ Webhook URLが正しく設定されているか
   □ Content typeが「application/json」か
   □ 必要なイベントにチェックが入っているか
   □ Webhookが「Active」になっているか
   ```

3. **Recent Deliveriesで確認**
   - Response: 200 OK（正常）
   - Response: タイムアウト（n8n側の問題）
   - Response: 404（URL間違い）

### データが期待通りでない場合

1. **Codeノードでデバッグ出力**
   ```javascript
   console.log('Received event type:', $json.headers['x-github-event']);
   console.log('Body:', JSON.stringify($json.body, null, 2));
   ```

2. **Filterノードの条件を確認**
   - 条件式が正しいか
   - データの階層が正しいか

## ベストプラクティス

1. **開発時は必ずTest Webhookから始める**
   - データ構造を確認できる
   - エラーをその場で修正できる

2. **小さく始めて段階的に構築**
   - まずWebhookでデータ受信だけ確認
   - 次にフィルタリング
   - 最後にアクション追加

3. **エラーハンドリングを追加**
   - Try-Catchノードで囲む
   - エラー時の通知設定

4. **本番移行前のチェックリスト**
   - [ ] Test Webhookで全パターンテスト済み
   - [ ] エラーハンドリング実装済み
   - [ ] Production URLに切り替え済み
   - [ ] GitHubのWebhook設定を本番用に更新