# 開発完了検出ロジック

## 確実性を高めるハイブリッドアプローチ

### 1. 必須条件（AND条件）
以下のすべてを満たす場合に完了と判定：

```javascript
const isPhase4 = phase === '4' || comment.includes('Phase 4') || comment.includes('フェーズ4');
const isByClaudeBot = commenter === 'claude[bot]';
const isNewComment = eventType === 'created';
```

### 2. 完了判定条件（OR条件）
以下のいずれかを含む場合：

```javascript
// 完了キーワードの配列
const completionKeywords = [
  'COMPLETE',
  '完了',
  '完成',
  'DELIVERY',
  'プルリクエスト準備完了',
  'PR準備完了',
  'デプロイ可能',
  'ready for production',
  '100%'
];

// 大文字小文字を無視して検索
const hasCompletionKeyword = completionKeywords.some(keyword => 
  comment.toLowerCase().includes(keyword.toLowerCase())
);
```

### 3. 否定条件（除外）
以下を含む場合は完了と判定しない：

```javascript
const exclusionKeywords = [
  'Phase 4に進む',
  'Phase 4開始',
  'TODO',
  '未完了',
  'エラー',
  'failed'
];

const hasExclusionKeyword = exclusionKeywords.some(keyword => 
  comment.toLowerCase().includes(keyword.toLowerCase())
);
```

### 4. 最終判定ロジック

```javascript
const isProjectComplete = 
  isPhase4 && 
  isByClaudeBot && 
  isNewComment && 
  hasCompletionKeyword && 
  !hasExclusionKeyword;
```

### 5. 信頼度スコア（オプション）
より詳細な判定が必要な場合：

```javascript
let confidenceScore = 0;

// Phase 4明記されている
if (phase === '4') confidenceScore += 30;
else if (comment.includes('Phase 4') || comment.includes('フェーズ4')) confidenceScore += 20;

// 複数の完了キーワード
const keywordCount = completionKeywords.filter(keyword => 
  comment.toLowerCase().includes(keyword.toLowerCase())
).length;
confidenceScore += keywordCount * 15;

// 特定の強い指標
if (comment.includes('PROJECT COMPLETE')) confidenceScore += 25;
if (comment.includes('100%')) confidenceScore += 20;

// 80点以上で完了と判定
const isHighConfidenceComplete = confidenceScore >= 80;
```

## 実装上の注意点

1. **定期的な見直し**
   - Claude Codeの出力パターンが変化する可能性
   - 月1回程度でパターンを確認・更新

2. **誤検知対策**
   - 完了通知後の手動確認フロー
   - 通知にIssue/PRリンクを含める

3. **見逃し対策**
   - Phase 4のreview-neededタグも別途通知
   - 一定時間経過後の未完了案件のリマインド