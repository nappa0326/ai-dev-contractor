# n8n 開発完了通知設定手順

## 概要
GitHub PR監視システムワークフローを修正して、Phase 4完了時に【PHASE4_COMPLETE】マーカーを検出し、Slack通知を送信するように設定します。

## 前提条件
- n8nにアクセスできること
- 「Github PR監視システム」ワークフローへの編集権限
- claude.ymlへの【PHASE4_COMPLETE】マーカー追加が完了していること

## 修正手順

### ステップ1: ワークフローを開く

1. n8nのダッシュボードにログイン
2. 「Github PR監視システム」ワークフローを見つけてクリック
3. ワークフローエディタが開きます

### ステップ2: Codeノードの修正

1. **Codeノードを開く**
   - 「Code」という名前のノードをダブルクリック
   - またはノードをクリックして自動的に開く

2. **JavaScriptコードを修正**
   - Parametersタブが開いていることを確認
   - jsCodeフィールド内のコードを以下のように修正：

   **修正箇所1**: commenterの修正（18行目付近）
   ```javascript
   // 修正前
   const isClaudeFinished = commenter === 'claudeaide[bot]' &&
   
   // 修正後
   const isClaudeFinished = commenter === 'claude[bot]' &&
   ```

   **修正箇所2**: Phase 4完了判定の追加（isClaudeFinishedの後に追加）
   ```javascript
   // Phase 4完了マーカーの検出（新規追加）
   const hasPhase4CompleteMarker = comment.includes('【PHASE4_COMPLETE】');
   
   // 開発完了判定（isClaudeFinishedを置き換え）
   const isProjectComplete = hasPhase4CompleteMarker && commenter === 'claude[bot]';
   ```

   **修正箇所3**: notificationTypeの判定を更新
   ```javascript
   // 修正前
   const notificationType = isClaudeFinished ? 'completion' :
   
   // 修正後
   const notificationType = isProjectComplete ? 'completion' :
   ```

   **修正箇所4**: needsReviewの判定を更新
   ```javascript
   // 修正前
   const needsReview = hasReviewTag &&
     (eventType === 'created' ||
      (eventType === 'edited' && comment.includes('Claude finished')));
   
   // 修正後
   const needsReview = hasReviewTag &&
     !isProjectComplete &&  // 完了時はレビュー不要
     (eventType === 'created' ||
      (eventType === 'edited' && comment.includes('Claude finished')));
   ```

   **修正箇所5**: return文のis_completedを更新
   ```javascript
   // 修正前
   is_completed: isClaudeFinished,
   
   // 修正後
   is_completed: isProjectComplete,
   ```

3. **変更を確定**
   - コードエディタの外側をクリック
   - 「Back to canvas」をクリックしてキャンバスに戻る

### ステップ3: Slack通知メッセージの修正（Send a message - Completion）

1. **Slackノードを開く**
   - 「Send a message - Completion」ノードをダブルクリック

2. **Blocks UIを修正**
   - Parametersタブで「Message Type」が「Block」になっていることを確認
   - 「Blocks UI」フィールドの内容を以下のように更新：

   ```json
   {
     "blocks": [
       {
         "type": "header",
         "text": {
           "type": "plain_text",
           "text": "🎉 プロジェクト開発完了",
           "emoji": true
         }
       },
       {
         "type": "section",
         "text": {
           "type": "mrkdwn",
           "text": "*Issue #{{ $json.pr_number }}* の開発が完了しました！\n\n*フェーズ*: Phase 4 (100%)\n*ステータス*: 【PHASE4_COMPLETE】\n*GitHub*: <{{ $json.html_url }}|完了コメントを確認>"
         }
       },
       {
         "type": "divider"
       },
       {
         "type": "section",
         "text": {
           "type": "mrkdwn",
           "text": "✅ 全フェーズが完了し、プルリクエストの準備が整いました。\n実装内容をご確認ください。"
         }
       },
       {
         "type": "actions",
         "elements": [
           {
             "type": "button",
             "text": {
               "type": "plain_text",
               "text": "📋 Issueを確認"
             },
             "url": "https://github.com/nappa0326/ai-development-company/issues/{{ $json.pr_number }}"
           }
         ]
       }
     ]
   }
   ```

3. **変更を確定**
   - フィールドの外側をクリック
   - 「Back to canvas」をクリック

### ステップ4: ワークフローを保存

1. **保存方法（いずれかを選択）**
   - キーボードショートカット: `Ctrl + S`（Windows）または `Cmd + S`（Mac）
   - 右上の「Save」ボタンをクリック

2. **保存の確認**
   - 「Save」ボタンが「Saved」（グレー文字）に変わることを確認
   - またはSaveボタンが非活性になることを確認

### ステップ5: ワークフローの状態確認

1. **アクティブ状態の確認**
   - ワークフロー名の横にあるトグルスイッチがONになっていることを確認
   - OFFの場合はクリックしてONにする

2. **エラーチェック**
   - 各ノードに赤いエラーアイコンが表示されていないことを確認

## 修正完了後のテスト

1. 新しいIssueでPhase 4完了時に【PHASE4_COMPLETE】マーカーが含まれることを確認
2. Slackに完了通知が送信されることを確認

## トラブルシューティング

- **保存できない場合**: ブラウザのコンソールでエラーを確認
- **通知が来ない場合**: Webhookの設定とSlack連携を確認
- **マーカーが検出されない場合**: コメントに【PHASE4_COMPLETE】が正確に含まれているか確認

## 注意事項

- この修正は新規のPhase 4完了時のみ有効（過去のIssueには適用されません）
- claude.ymlの修正が先に完了している必要があります