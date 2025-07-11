# n8n 重複通知対策

## 問題
Claude Codeがコメントを編集するたびに通知が発生する

## 解決方法

### Github PR監視システムのCodeノードを以下のように修正：

```javascript
// 受信データを取得
const eventType = $json.body.action; // created, edited, deleted
const comment = $json.body.comment?.body || '';
const prNumber = $json.body.issue?.number || $json.body.pull_request?.number;
const htmlUrl = $json.body.comment?.html_url || '';
const commentId = $json.body.comment?.id;
const user = $json.body.comment?.user?.login || '';

// @claude-review-neededタグの検出
const hasReviewTag = comment.includes('@claude-review-needed');

// フェーズの検出
const phaseMatch = comment.match(/Phase (\d)/);
const phase = phaseMatch ? phaseMatch[1] : null;

// 重複チェック用のキー（PR番号とフェーズの組み合わせ）
const notificationKey = `pr_${prNumber}_phase_${phase}`;

// レビューが必要かどうかを判定
// editedイベントの場合は、新規に@claude-review-neededが追加された場合のみ
let needsReview = false;

if (eventType === 'created' && hasReviewTag) {
  needsReview = true;
} else if (eventType === 'edited' && hasReviewTag && user === 'claude[bot]') {
  // editedイベントでかつClaude botの場合
  // コメント内に"Phase X 完了"があるかチェック
  const phaseCompleted = comment.includes(`Phase ${phase} 完了`) || 
                         comment.includes(`Phase ${phase} を完了`);
  needsReview = phaseCompleted;
}

return {
  json: {
    needs_review: needsReview,
    pr_number: prNumber,
    phase: phase,
    comment: comment,
    html_url: htmlUrl,
    event_type: eventType,
    comment_id: commentId,
    notification_key: notificationKey,
    user: user
  }
};
```

## より簡単な解決策（推奨）

重複通知を防ぐため、以下のパターンマッチングを使用：

```javascript
// レビューが必要かどうかを判定
let needsReview = false;

if (hasReviewTag) {
  if (eventType === 'created') {
    needsReview = true;
  } else if (eventType === 'edited') {
    // 編集の場合は、特定のパターンがある場合のみ通知
    // 例：「Phase X 完了」という文字列が含まれる場合
    needsReview = comment.includes('完了') && comment.includes('@claude-review-needed');
  }
}
```