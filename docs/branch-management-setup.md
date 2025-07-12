# ブランチ管理システム セットアップガイド

## 概要

このシステムは、Claude AIがフェーズ間で連続性を保ちながら開発を行うことを保証するために設計されています。

## 機能

1. **ブランチ継続性チェック**
   - PR内の`@claude-review-needed`タグを検知
   - Issue番号からブランチを特定
   - フェーズ2以降で新規ブランチ作成を検出

2. **アラート機能**
   - Slackへの通知
   - GitHubへの警告コメント追加
   - 具体的な修正手順の提示

3. **フェーズ追跡**
   - 各フェーズの進行状況を監視
   - ブランチの一貫性を確認

## セットアップ手順

### 1. n8nへのインポート

1. n8nの管理画面にアクセス
2. 「ワークフロー」→「新規作成」を選択
3. 左上のメニューから「インポート from file」を選択
4. `n8n-workflows/ブランチ管理システム.json`を選択

### 2. 認証情報の設定

#### GitHub API
- 「Credentials」→「New」→「GitHub API」
- Personal Access Tokenを設定（repo権限が必要）

#### Slack API
- 既存のSlack認証情報を使用

### 3. トリガーの設定

このワークフローは、GitHub PR監視システムから呼び出されます：

```json
{
  "comment_id": "PR comment ID",
  "issue_number": "Issue number",
  "phase": "Phase number"
}
```

### 4. 統合設定

既存の「Github PR監視システム」に以下のノードを追加：

```javascript
// ブランチ管理チェックを実行
if (comment.includes('@claude-review-needed')) {
  // ブランチ管理システムワークフローを実行
  $node["Execute Workflow"].execute({
    workflowId: "ブランチ管理システムのID",
    data: {
      comment_id: commentId,
      issue_number: issueNumber,
      phase: phaseNumber
    }
  });
}
```

## 動作フロー

1. **コメント解析**
   - `@claude-review-needed`タグを検出
   - Issue番号とフェーズ番号を抽出

2. **ブランチチェック**
   - GitHubから全ブランチリストを取得
   - 該当Issueのブランチを検索

3. **継続性検証**
   - Phase 2以降で既存ブランチがない場合にエラー
   - 複数ブランチが存在する場合に警告

4. **通知送信**
   - Slackにアラートを送信
   - GitHubに修正手順をコメント

## エラーメッセージ例

### ブランチが見つからない場合
```
⚠️ Phase 2が開始されましたが、issue-24用のブランチが見つかりません！

### 対応方法
1. 既存のブランチを確認し、そのブランチで作業を継続してください
2. `git checkout claude/issue-24-20250712_012315`
3. 前のフェーズの実装を必ず確認してください
```

### 複数ブランチが存在する場合
```
📌 issue-24に複数のブランチが存在します: claude/issue-24-20250712_012315, claude/issue-24-20250712_140230

### 対応方法
最初に作成されたブランチを使用してください
```

## メンテナンス

- ワークフローのログを定期的に確認
- 誤検知がある場合は条件を調整
- GitHubのAPI制限に注意