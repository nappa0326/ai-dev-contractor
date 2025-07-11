# n8n GitHub PR監視ワークフロー設定手順書

## 重要な前提知識

n8nのGitHub Triggerノードは`issue_comment`イベントをサポートしていません。そのため、PRのConversationタブのコメント（Claude Codeが投稿する通常のコメント）を監視するには、**Webhookノード**を使用する必要があります。

## 前提条件

1. n8nがLinode VPSで稼働中
2. GitHubリポジトリの管理者権限
3. n8nのWebhook URLにアクセス可能
4. Slack APIの認証情報

## Part 1: GitHubでWebhookを設定

### 手順1: GitHubリポジトリのWebhook設定画面へ

1. GitHubで `nappa0326/ai-development-company` リポジトリを開く
2. Settings タブをクリック
3. 左側メニューの「Webhooks」をクリック
4. 「Add webhook」ボタンをクリック

### 手順2: Webhook URLの取得（n8n側）

1. n8nダッシュボードで「New Workflow」を作成
2. ワークフロー名を「GitHub PR監視システム」に設定
3. 「Webhook」ノードを追加
4. Webhookノードの設定：
   - HTTP Method: `POST`
   - Path: `github-pr-comments`
   - Response Mode: `Immediately`
   - Response Code: `200`
5. 表示されるWebhook URLをコピー（例: `https://n8n.oppy-ai.com/webhook/github-pr-comments`）

### 手順3: GitHubでWebhookを作成

1. **Payload URL**: n8nでコピーしたWebhook URLを貼り付け
2. **Content type**: `application/json`を選択
3. **Secret**: 空欄のまま（またはセキュリティ強化のため任意の文字列）
4. **Which events would you like to trigger this webhook?**
   - 「Let me select individual events」を選択
   - 以下のイベントにチェック：
     - ✅ Issue comments
     - ✅ Pull request reviews
     - ✅ Pull request review comments
5. **Active**: チェックを入れる
6. 「Add webhook」ボタンをクリック

## Part 2: n8nワークフローの構築

### ワークフロー1: GitHub PR コメント監視

### 手順3: Codeノードでコメント解析

1. **ノードの追加**
   - 「Code」ノードを追加
   - GitHub Triggerノードと接続

2. **コード設定**
   ```javascript
   // PRコメントの内容を解析
   const eventType = $json.action; // created, edited, deleted
   const comment = $json.comment?.body || '';
   const prNumber = $json.issue?.number || $json.pull_request?.number;
   const htmlUrl = $json.comment?.html_url || '';
   
   // @claude-review-neededタグの検出
   const hasReviewTag = comment.includes('@claude-review-needed');
   
   // フェーズの検出
   const phaseMatch = comment.match(/Phase (\d)/);
   const phase = phaseMatch ? phaseMatch[1] : null;
   
   // レビューが必要かどうかを判定
   const needsReview = hasReviewTag && eventType === 'created';
   
   return {
     json: {
       needs_review: needsReview,
       pr_number: prNumber,
       phase: phase,
       comment: comment,
       html_url: htmlUrl,
       event_type: eventType
     }
   };
   ```

### 手順4: Filterノードで条件分岐

1. **ノードの追加**
   - 「Filter」ノードを追加
   - Codeノードと接続

2. **条件設定**
   - Conditions:
     - Field: `{{ $json.needs_review }}`
     - Operation: Equal
     - Value: `true`

### 手順5: Slack通知ノードの設定

1. **ノードの追加**
   - 「Slack」ノードを追加
   - Filterノードと接続

2. **設定内容**
   - Credential: 既存のSlack認証情報を選択
   - Resource: Message
   - Operation: Send
   - Channel ID: `C094LNGF8H5`
   - Message Type: Block

3. **メッセージ内容**
   ```json
   {
     "blocks": [
       {
         "type": "header",
         "text": {
           "type": "plain_text",
           "text": "🔔 レビューが必要です"
         }
       },
       {
         "type": "section",
         "text": {
           "type": "mrkdwn",
           "text": "*PR #{{ $json.pr_number }}* でレビューが必要です\n*フェーズ*: Phase {{ $json.phase }}\n*GitHub*: <{{ $json.html_url }}|コメントを確認>"
         }
       },
       {
         "type": "divider"
       },
       {
         "type": "section",
         "text": {
           "type": "plain_text",
           "text": "アクションを選択してください："
         }
       },
       {
         "type": "actions",
         "elements": [
           {
             "type": "button",
             "text": {
               "type": "plain_text",
               "text": "✅ 承認して続行"
             },
             "style": "primary",
             "value": "continue_{{ $json.pr_number }}"
           },
           {
             "type": "button",
             "text": {
               "type": "plain_text",
               "text": "📝 修正を依頼"
             },
             "value": "revise_{{ $json.pr_number }}"
           }
         ]
       }
     ]
   }
   ```

### 手順6: ワークフローの保存と有効化

1. 右上の「Save」をクリック
2. 「Active」トグルをONにする
3. 「Execute Workflow」でテスト実行（任意）

## ワークフロー2: Slack応答処理

### 手順1: 新規ワークフローの作成

1. 「New Workflow」をクリック
2. ワークフロー名を「Slack開発制御システム」に設定

### 手順2: Slack Triggerノードの設定

1. **ノードの追加**
   - 「Slack Trigger」を追加

2. **設定内容**
   - Credential: 既存のSlack認証情報
   - Event: Interactive Message（ボタンクリック用）

### 手順3: データ処理用Codeノード

1. **コード設定**
   ```javascript
   // Slackボタンのアクションを解析
   const action = $json.body.actions[0];
   const actionValue = action.value; // "continue_42" or "revise_42"
   
   const [actionType, prNumber] = actionValue.split('_');
   
   // 応答メッセージの準備
   const responseUrl = $json.body.response_url;
   
   return {
     json: {
       action_type: actionType,
       pr_number: prNumber,
       response_url: responseUrl,
       user: $json.body.user.name
     }
   };
   ```

### 手順4: GitHub APIでコメント追加

1. **ノードの追加**
   - 「GitHub」ノードを追加

2. **設定内容**
   - Resource: Issue
   - Operation: Create Comment
   - Repository Owner: `nappa0326`
   - Repository Name: `ai-development-company`
   - Issue Number: `{{ $json.pr_number }}`
   - Comment: 
     ```
     {{ $json.action_type === 'continue' ? '@claude continue' : '@claude revise: ユーザーからの修正依頼があります' }}
     
     （{{ $json.user }} さんがSlackから応答）
     ```

### 手順5: Slack応答の更新

1. **HTTP Requestノードを追加**
   - Method: POST
   - URL: `{{ $json.response_url }}`
   - Body Type: JSON
   - Body:
     ```json
     {
       "text": "✅ GitHubにコメントを追加しました",
       "replace_original": true
     }
     ```

## テスト手順

### Part 1: GitHub Webhook接続テスト

1. GitHubのWebhook設定画面で「Recent Deliveries」タブを確認
2. 「Redeliver」ボタンで過去のイベントを再送信
3. n8nのワークフローで受信確認

### Part 2: PRコメントテスト

1. GitHubで実際のPRにコメントを投稿：
   ```
   ## 📊 進捗報告: Phase 1 完了（20%）
   
   設計書を作成しました。レビューをお願いします。
   
   @claude-review-needed
   ```

2. n8nの実行履歴で以下を確認：
   - Webhookが受信された
   - PRコメントとして認識された
   - @claude-review-neededタグが検出された

3. Slackに通知が届くことを確認

### Part 3: Slackボタンテスト

1. Slackの通知でボタンをクリック
2. n8nのSlack用Webhookが反応することを確認
3. GitHubのPRに適切なコメントが追加されることを確認

## トラブルシューティング

### GitHub Webhook が機能しない場合

1. **GitHubのWebhook画面で確認**
   - Recent Deliveriesで緑のチェックマークがあるか
   - Response codeが200か
   - エラーメッセージがないか

2. **n8n側で確認**
   - Webhookノードが「Listening」状態か
   - ワークフローがActiveになっているか
   - Execution logでエラーがないか

3. **ペイロードの確認**
   - GitHubのRecent Deliveriesでペイロードを確認
   - `x-github-event`ヘッダーが`issue_comment`になっているか

### Issueコメントも受信してしまう場合

- Filterノードの条件を追加：
  ```javascript
  // PRコメントのみを通過させる
  const isPR = $json.body.issue?.pull_request !== undefined;
  ```

### Slack通知が届かない場合

1. Channel IDが正しいか確認（C094LNGF8H5）
2. Slack Bot がチャンネルに追加されているか確認
3. Slack APIトークンの権限を確認（chat:write, chat:write.public）

### 重要な注意事項

- **Webhookノードは手動でGitHubに登録が必要**（GitHub Triggerと異なり自動登録されない）
- **ワークフローを無効化してもGitHub側のWebhookは残る**（手動削除が必要）
- **Webhook URLはn8nインスタンスごとに異なる**
- **GitHubのWebhookは即座に配信される**（ポーリングではない）