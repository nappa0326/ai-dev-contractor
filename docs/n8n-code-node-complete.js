// Github PR監視システム - Codeノード 完全な修正後のコード

// PRコメントの内容を解析
const eventType = $json.body.action; // created, edited, deleted
const comment = $json.body.comment?.body || '';
const prNumber = $json.body.issue?.number || $json.body.pull_request?.number;
const htmlUrl = $json.body.comment?.html_url || '';
const commenter = $json.body.comment?.user?.login || '';
const commentId = $json.body.comment?.id || null;
const prUrl = `https://github.com/${$json.body.repository?.full_name}/pull/${prNumber}`;

// @claude-review-neededタグの検出
const hasReviewTag = comment.includes('@claude-review-needed');

// フェーズの検出
const phaseMatch = comment.match(/Phase (\d)/);
const phase = phaseMatch ? phaseMatch[1] : null;

// Phase 4完了マーカーの検出（確実な方法）
const hasPhase4CompleteMarker = comment.includes('【PHASE4_COMPLETE】');

// 開発完了判定（シンプルで確実）
const isProjectComplete = hasPhase4CompleteMarker && commenter === 'claude[bot]';

// レビューが必要かどうかを判定
const needsReview = hasReviewTag &&
  !isProjectComplete &&  // 完了時はレビュー不要
  (eventType === 'created' ||
   (eventType === 'edited' && comment.includes('Claude finished')));

// 通知タイプの判定
const notificationType = isProjectComplete ? 'completion' :
                        needsReview ? 'review' :
                        'none';

return {
  json: {
    notification_type: notificationType,
    needs_review: needsReview,
    is_completed: isProjectComplete,
    pr_number: prNumber,
    phase: phase,
    comment: comment,
    html_url: htmlUrl,
    event_type: eventType,
    commenter: commenter,
    comment_id: commentId,
    pr_url: prUrl,
    has_phase4_marker: hasPhase4CompleteMarker  // デバッグ用
  }
};