# Slack App インタラクティブ機能設定ガイド

## 概要

Slackのボタンクリックなどのインタラクティブな操作をn8nで処理するための設定手順です。

## 前提条件

- Slack Appが作成済み
- n8nのワークフローでWebhookが使用可能
- Slack Appがワークスペースにインストールされている

## 設定手順

### Part 1: n8n側でWebhook URLを準備

1. **n8nで新規ワークフローを作成**
   - ワークフロー名：「Slack開発制御システム」

2. **Webhookノードを追加**
   - HTTP Method: `POST`
   - Path: `slack-interactive`
   - Response Mode: `Immediately`
   - Response Code: `200`

3. **Webhook URLをコピー**
   - 例：`https://n8n.oppy-ai.com/webhook/slack-interactive`
   - このURLを次のステップで使用

### Part 2: Slack Appの設定

1. **Slack App管理画面を開く**
   - https://api.slack.com/apps
   - 対象のAppを選択

2. **Interactive Components（インタラクティビティ）を有効化**
   - 左側メニューから「Interactivity & Shortcuts」をクリック
   - 「Interactivity」のトグルを**ON**にする

3. **Request URLを設定**
   - 「Request URL」欄にn8nのWebhook URLを入力
   - 例：`https://n8n.oppy-ai.com/webhook/slack-interactive`
   - Slackが自動的にURLを検証（緑のチェックマークが表示される）

4. **設定を保存**
   - 「Save Changes」ボタンをクリック

### Part 3: ボタンアクションの処理

#### n8nでのデータ受信形式

Slackのボタンクリック時、以下の形式でデータが送信されます：

```javascript
{
  "payload": "{\"type\":\"block_actions\",\"user\":{...},\"actions\":[{\"value\":\"continue_42\"}],...}"
}
```

**重要：** payloadは文字列として送信されるため、JSONパースが必要です。

#### Codeノードでの処理例

```javascript
// Slackからのインタラクティブペイロードを解析
const payload = JSON.parse($json.body.payload);

// アクション情報を取得
const action = payload.actions[0];
const actionValue = action.value; // "continue_42" or "revise_42"

// 値を分解
const [actionType, prNumber] = actionValue.split('_');

// ユーザー情報
const user = payload.user.name;
const userId = payload.user.id;

// 応答URL（3秒以内に応答が必要な場合に使用）
const responseUrl = payload.response_url;

return {
  json: {
    action_type: actionType,  // "continue" or "revise"
    pr_number: prNumber,      // "42"
    user: user,
    user_id: userId,
    response_url: responseUrl,
    channel: payload.channel.id,
    original_message_ts: payload.message.ts
  }
};
```

### Part 4: 応答の送信

#### 即座の応答（推奨）

Slackは3秒以内の応答を期待します。Webhookノードの`Immediately`設定により自動的に200 OKが返されます。

#### メッセージの更新

元のメッセージを更新する場合：

1. **HTTP Requestノードを使用**
   - Method: `POST`
   - URL: `https://slack.com/api/chat.update`
   - Authentication: OAuth2 (Slack API)
   - Body:
     ```json
     {
       "channel": "{{ $json.channel }}",
       "ts": "{{ $json.original_message_ts }}",
       "text": "✅ 処理を開始しました",
       "blocks": [
         {
           "type": "section",
           "text": {
             "type": "mrkdwn",
             "text": "✅ *承認されました*\n\nGitHubに `@claude continue` コメントを追加しています..."
           }
         }
       ]
     }
     ```

## トラブルシューティング

### Request URLの検証に失敗する場合

1. **n8nのワークフローがActiveか確認**
   - Webhookノードは有効化されている必要があります

2. **HTTPSであることを確認**
   - SlackはHTTPSのみ受け付けます

3. **n8nが外部からアクセス可能か確認**
   - ファイアウォールやプロキシの設定を確認

### ボタンクリックが反応しない場合

1. **Interactivityが有効か確認**
   - Slack Appの設定画面で確認

2. **Request URLが正しいか確認**
   - 末尾のスラッシュの有無も含めて完全一致

3. **n8nのExecution logを確認**
   - リクエストが届いているか確認

### payloadのパースエラー

```javascript
// エラーハンドリングを追加
try {
  const payload = JSON.parse($json.body.payload);
  // 処理を続行
} catch (error) {
  console.error('Payload parse error:', error);
  return {
    json: {
      error: 'Invalid payload format',
      raw_payload: $json.body.payload
    }
  };
}
```

## セキュリティ考慮事項

### 署名の検証（推奨）

Slackからのリクエストを検証するには、署名を確認します：

1. **Slack Appの「Signing Secret」を取得**
   - Basic Information → App Credentials → Signing Secret

2. **n8nで署名を検証**
   ```javascript
   const crypto = require('crypto');
   
   const slackSignature = $json.headers['x-slack-signature'];
   const timestamp = $json.headers['x-slack-request-timestamp'];
   const signingSecret = 'your_signing_secret'; // 環境変数で管理推奨
   
   const baseString = `v0:${timestamp}:${$json.body}`;
   const mySignature = 'v0=' + crypto
     .createHmac('sha256', signingSecret)
     .update(baseString)
     .digest('hex');
   
   const isValid = slackSignature === mySignature;
   ```

## 次のステップ

1. インタラクティブ機能を設定
2. n8nでSlack応答処理ワークフローを構築
3. GitHubへのコメント追加機能を実装
4. エンドツーエンドでテスト