# n8nワークフロー調整案 - フェーズ別ブランチ戦略対応

## 概要

フェーズ別ブランチ戦略の導入に伴い、n8nワークフローの調整が必要です。主にSlack通知の内容変更と、承認/修正ボタンの削除が主な変更点となります。

## 調整が必要なワークフロー

### 1. **Slack開発制御システム**

#### 現在の機能
- 承認ボタン → GitHubに`@claude continue`コメント
- 修正依頼ボタン → モーダル表示 → `@claude revise`コメント
- ブランチ情報の抽出と表示

#### 調整内容
- **承認/修正ボタンの削除**（GitHub PR上で操作するため）
- **PR URL抽出ロジックの追加**
- **Slack通知フォーマットの変更**

#### 新しいSlack通知フォーマット
```javascript
// Extract PR Info ノードの追加
const extractPRInfo = (comment) => {
  // PR番号の抽出
  const prMatch = comment.match(/PR:\s*#(\d+)/);
  const prNumber = prMatch ? prMatch[1] : null;
  
  // フェーズ番号の抽出
  const phaseMatch = comment.match(/Phase\s+(\d)/i);
  const phaseNumber = phaseMatch ? phaseMatch[1] : '1';
  
  // ブランチ名の抽出（新形式対応）
  const branchMatch = comment.match(/[Bb]ranch:\s*`?([^`\s]+)`?/);
  const branchName = branchMatch ? branchMatch[1] : null;
  
  return { prNumber, phaseNumber, branchName };
};

// Format Slack Message ノードの更新
const formatSlackMessage = (data) => {
  const { issueNumber, issueTitle, projectName, prNumber, phaseNumber, branchName } = data;
  const repoUrl = 'https://github.com/org/repo'; // 実際のリポジトリURLに置換
  
  const progress = {
    1: { bar: '✅⬜⬜⬜', text: '設計完了', percent: 25 },
    2: { bar: '✅✅⬜⬜', text: 'MVP完了', percent: 50 },
    3: { bar: '✅✅✅⬜', text: '実装完了', percent: 80 },
    4: { bar: '✅✅✅✅', text: '品質向上完了', percent: 100 }
  };
  
  const currentProgress = progress[phaseNumber] || progress[1];
  
  return {
    blocks: [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: `*📋 ${projectName} - Phase ${phaseNumber}完了*`
        }
      },
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: [
            `Issue: <${repoUrl}/issues/${issueNumber}|#${issueNumber}>`,
            `PR: <${repoUrl}/pull/${prNumber}|#${prNumber}> 🆕`,
            `Branch: \`${branchName}\``,
            `進捗: ${currentProgress.bar} ${currentProgress.text} (${currentProgress.percent}%)`
          ].join('\n')
        }
      },
      {
        type: "divider"
      },
      {
        type: "context",
        elements: [
          {
            type: "mrkdwn",
            text: "👉 PRでレビューをお願いします"
          }
        ]
      }
    ]
  };
};
```

### 2. **AI開発会社 - プロジェクト受注システム**

#### 調整内容
- 特に変更なし（Issue作成時の処理のため）
- ただし、ラベル設定は維持

### 3. **GitHub PR監視システム**

#### 現在の機能
- PR作成/更新時の通知
- 完了判定（PROJECT COMPLETED）

#### 調整内容
- **フェーズ別PR検出の追加**
- **進捗追跡機能の強化**

```javascript
// Detect Phase PR ノード
const detectPhasePR = (prTitle) => {
  const phaseMatch = prTitle.match(/Phase\s+(\d):/i);
  if (phaseMatch) {
    return {
      isPhaseP R: true,
      phaseNumber: parseInt(phaseMatch[1]),
      isComplete: phaseMatch[1] === '4'
    };
  }
  return { isPhasePR: false };
};

// Format Completion Message ノード
const formatCompletionMessage = (data) => {
  const { projectName, issueNumber, mergedPRs } = data;
  
  if (data.phaseNumber === 4) {
    return {
      blocks: [
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: `*🎉 ${projectName} - PROJECT COMPLETED*`
          }
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: [
              `すべての開発が完了しました！`,
              `Issue: #${issueNumber}`,
              `マージされたPR: ${mergedPRs.join(', ')}`
            ].join('\n')
          }
        }
      ]
    };
  }
  
  // 通常のフェーズ完了通知
  return formatSlackMessage(data);
};
```

## 実装手順

### Step 1: Slack開発制御システムの更新

1. **削除するノード**:
   - Button Action Handler
   - Modal Handler
   - Continue/Revise GitHub Comment

2. **追加するノード**:
   - Extract PR Info
   - Format Phase Message

3. **更新するノード**:
   - Slack Message Formatter

### Step 2: GitHub PR監視システムの更新

1. **追加するノード**:
   - Detect Phase PR
   - Track Project Progress

2. **更新するノード**:
   - Completion Detection
   - Slack Notification Format

## メリット

1. **シンプル化**: Slackは通知のみ、操作はGitHub
2. **一貫性**: GitHub PRが唯一の操作場所
3. **追跡性**: フェーズごとの進捗が明確
4. **自動化**: PR情報の自動抽出と表示

## 注意事項

1. **後方互換性**: 既存のプロジェクトは現行方式で完了させる
2. **エラーハンドリング**: PR番号が取得できない場合の対処
3. **権限管理**: GitHub PRへのアクセス権限の確認

## テスト計画

1. **単体テスト**:
   - PR情報抽出ロジック
   - フェーズ番号検出
   - メッセージフォーマット

2. **統合テスト**:
   - 新規プロジェクトの全フェーズ
   - 継続開発タスク
   - エラーケース

## 移行スケジュール

1. **Phase 1**: ワークフローのバックアップ
2. **Phase 2**: テスト環境での検証
3. **Phase 3**: 本番環境への適用
4. **Phase 4**: 既存プロジェクトの完了確認