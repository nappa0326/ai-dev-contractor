# 開発請負AI
AIが開発案件を自動で請け負うシステム

## 概要

このシステムは、GitHub IssuesとSlackを連携させて、AIが自動的に開発案件を請け負い、フェーズごとに段階的に実装を進めるシステムです。

## システム構成

- **GitHub Issues**: 開発案件の管理
- **Slack**: 発注インターフェース・進捗通知
- **n8n**: ワークフロー自動化
- **GitHub Actions**: 自動開発実行

## Slackスラッシュコマンド

### `/ai-dev` - 統一開発コマンド

開発請負AIシステムの主要コマンドです。新規開発と継続開発の両方に対応しています。

#### コマンド一覧

| コマンド | 説明 | フェーズ数 |
|---------|------|-----------|
| `/ai-dev new "プロジェクト名" "要件"` | 新規プロジェクト開発 | 4フェーズ |
| `/ai-dev fix #元Issue番号 "修正内容"` | 軽微な修正（タイポ、設定値変更など） | 1フェーズ |
| `/ai-dev bugfix #元Issue番号 "修正内容"` | バグ修正 | 2フェーズ |
| `/ai-dev enhance #元Issue番号 "機能追加内容"` | 機能追加・拡張 | 3フェーズ |
| `/ai-dev refactor #元Issue番号 "リファクタリング内容"` | コード改善 | 3-4フェーズ |

#### 使用例

```bash
# 新規プロジェクト
/ai-dev new "PDF圧縮デスクトップアプリ" "PDFファイルのサイズを圧縮するElectronアプリを作成してください"

# バグ修正
/ai-dev bugfix #44 "メモリリークが発生している問題を修正"

# 機能追加
/ai-dev enhance #44 "ドラッグ&ドロップ機能を追加"

# リファクタリング
/ai-dev refactor #44 "コンポーネントを分割してテスタビリティを向上"
```

## 開発フロー

### 新規プロジェクト（4フェーズ）

1. **Phase 1 (20%)**: 設計書・アーキテクチャ設計
2. **Phase 2 (50%)**: MVP実装（最小限の動作）
3. **Phase 3 (80%)**: 完全実装
4. **Phase 4 (100%)**: 品質向上・ドキュメント整備

### 継続開発

タスクタイプに応じて1〜4フェーズで実行されます。

## n8n連携

Slackコマンドはn8nワークフローを通じて処理されます：

1. Slackスラッシュコマンド → n8n Webhook
2. n8nがコマンドを解析してGitHub Issue作成
3. GitHub Webhookがn8nに通知
4. n8nがSlackに進捗を通知
5. 開発完了時にPR作成とSlack通知

## セットアップ

詳細なセットアップ手順は各ドキュメントを参照してください：

- [Slack App設定](docs/slack-app-interactive-setup.md)
- [n8nワークフロー設定](docs/n8n-completion-notification-setup.md)
- [GitHub Webhook設定](docs/n8n-github-pr-webhook-setup.md)
