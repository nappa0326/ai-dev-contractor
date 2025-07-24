# フェーズ別ブランチ戦略仕様書

## 概要

開発請負AIシステムにおいて、各開発フェーズを独立したブランチとPull Requestで管理する戦略を採用します。これにより、段階的なコードレビューと品質保証を実現します。

## ブランチ構造

```
master（システム設定のみ）
└── project/{project-name}（プロジェクトメインブランチ）
    ├── claude/issue-{number}-phase1（Phase 1作業）
    ├── claude/issue-{number}-phase2（Phase 2作業）
    ├── claude/issue-{number}-phase3（Phase 3作業）
    └── claude/issue-{number}-phase4（Phase 4作業）
```

## フェーズ別開発フロー

### Phase 1: 設計フェーズ（20%）

```bash
# プロジェクトメインブランチから作業ブランチ作成
git checkout project/{project-name}
git checkout -b project/{project-name}/claude/issue-{number}-phase1

# 設計書・アーキテクチャドキュメント作成
# コミット後、PR作成
gh pr create --base project/{project-name} \
  --title "Phase 1: {プロジェクト名}設計書 (#{issue-number})" \
  --body "## Phase 1: 設計フェーズ\n\n### 作成ドキュメント\n- ARCHITECTURE.md\n- REQUIREMENTS.md\n- ディレクトリ構造設計\n\nRelated to #{issue-number}"
```

### Phase 2: MVP実装（50%）

```bash
# 最新のプロジェクトメインブランチから開始（Phase 1がマージ済み）
git checkout project/{project-name}
git pull origin project/{project-name}
git checkout -b project/{project-name}/claude/issue-{number}-phase2

# Phase 1の成果物を確認
# MVP実装
# PR作成
```

### Phase 3: 完全実装（80%）

```bash
# Phase 1, 2がマージ済みの状態から開始
git checkout project/{project-name}
git pull origin project/{project-name}
git checkout -b project/{project-name}/claude/issue-{number}-phase3

# 全機能実装
# PR作成
```

### Phase 4: 品質向上（100%）

```bash
# Phase 1, 2, 3がマージ済みの状態から開始
git checkout project/{project-name}
git pull origin project/{project-name}
git checkout -b project/{project-name}/claude/issue-{number}-phase4

# テスト追加、ドキュメント整備、最適化
# PR作成
```

## PR管理戦略

### PR作成タイミング
- 各フェーズ完了時に自動的にPRを作成
- PRはそのフェーズの全変更を含む

### PR命名規則
```
Phase 1: Phase 1: {プロジェクト名}設計書 (#{issue-number})
Phase 2: Phase 2: {プロジェクト名}MVP実装 (#{issue-number})
Phase 3: Phase 3: {プロジェクト名}完全実装 (#{issue-number})
Phase 4: Phase 4: {プロジェクト名}品質向上 (#{issue-number})
```

### レビューフロー
1. 各フェーズのPRはGitHub上でレビュー
2. 承認後、プロジェクトメインブランチにマージ
3. 次のフェーズはマージ済みの内容を含んで開始

## Slack通知

### 通知フォーマット
```
┌─────────────────────────────────────────────────┐
│ 📋 {プロジェクト名} - Phase {N}完了              │
├─────────────────────────────────────────────────┤
│ Issue: <{issue-url}|#{issue-number}>           │
│ PR: <{pr-url}|#{pr-number}> 🆕                 │
│ Branch: project/{name}/claude/issue-{num}-phase{N} │
│ 進捗: {進捗バー} {フェーズ名}完了 ({進捗率}%)     │
│                                                 │
│ 📄 {フェーズ別の成果物サマリー}                   │
└─────────────────────────────────────────────────┘
```

### 通知内容
- PR URLを含む（クリックで直接アクセス可能）
- 承認/修正ボタンは削除（GitHub PR上で操作）
- 進捗状況と成果物の概要を表示

## フェーズ間の継続性保証

### 必須手順
1. **最新化**: プロジェクトメインブランチを必ず最新化
2. **確認**: 前フェーズの成果物を確認
3. **継承**: 既存の実装を拡張（削除・置換は禁止）

### 実装の注意点
```yaml
DO:
  - git pull origin project/{name} # 最新を取得
  - 既存ファイルの読み込みと理解
  - 前フェーズの設計に従った実装
  
DON'T:
  - 前フェーズの成果物を無視
  - ゼロから再実装
  - 設計と異なる実装
```

## 継続開発での適用

継続開発タスクも同様のフェーズ別ブランチ戦略を適用：

```
project/{name}/claude/issue-{number}-{task-type}-phase{N}
```

例：
- `project/pdf-compressor/claude/issue-67-enhance-phase1`
- `project/pdf-compressor/claude/issue-68-bugfix-phase1`

## 利点

1. **段階的レビュー**: 各フェーズで適切な粒度のレビュー
2. **並行作業**: レビュー中も次フェーズの準備が可能
3. **透明性**: 全体の進捗がPR履歴で可視化
4. **品質保証**: フェーズごとの承認により品質を段階的に確保
5. **柔軟性**: 必要に応じて特定フェーズの再実行が可能

## 移行計画

1. 新規プロジェクトから適用開始
2. 既存の進行中プロジェクトは現行方式で完了
3. CLAUDE.mdとGitHub Actionsの更新
4. n8nワークフローの調整