# 開発請負AI

AIが開発案件を自動で請け負い、フェーズごとに段階的に実装を進めるシステムです。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Setup Guide](https://img.shields.io/badge/docs-setup_guide-blue.svg)](docs/SETUP_GUIDE.md)

> ⚠️ **セットアップが必要です**: このリポジトリを使用する場合、[SETUP_GUIDE.md](docs/SETUP_GUIDE.md)の手順に従って環境変数とワークフローの設定を行ってください。

## 概要

このシステムは、GitHub Issues、Slack、n8nを連携させて、Claude CodeによるAI開発を自動化します。

```
Slack (/ai-dev コマンド)
    ↓
n8n (ワークフロー自動化)
    ↓
GitHub Issue作成
    ↓
Claude Code (@claudeメンション)
    ↓
フェーズ型開発（設計→MVP→完全実装→品質向上）
    ↓
Pull Request作成
    ↓
Slack通知
```

## 主な特徴

- 🤖 **完全自動化**: Slackコマンド一つで開発開始
- 📊 **フェーズ型開発**: 段階的なレビューと品質保証
- 🔄 **継続開発対応**: バグ修正・機能追加も自動化
- 📦 **プロジェクト分離**: 案件ごとに独立したブランチ管理
- 🛠️ **マルチ言語対応**: Node.js、Python、Go、Rust等をサポート

## システム構成

### 必須コンポーネント

| コンポーネント | 用途 | コスト |
|------------|------|--------|
| **GitHub** | プロジェクト管理・CI/CD | 無料〜 |
| **Slack** | 発注インターフェース・通知 | 無料〜 |
| **n8n** | ワークフロー自動化 | $20/月〜 |
| **Claude Code** | AI開発エンジン | $20/月〜 |

**最小構成の月額コスト**: 約$40〜

### アーキテクチャ図

```
┌─────────────┐
│   Slack     │ スラッシュコマンド
│ Workspace   │ メンション応答
└──────┬──────┘
       │
       ▼
┌─────────────┐
│     n8n     │ ワークフロー自動化
│  Instance   │ - Issue作成
└──────┬──────┘ - PR監視
       │        - Slack通知
       │
       ▼
┌─────────────┐
│   GitHub    │ コード管理
│ Repository  │ - project/* ブランチ
└──────┬──────┘ - フェーズ別PR
       │
       ▼
┌─────────────┐
│ Claude Code │ AI開発実行
│   (@claude) │ - 設計書作成
└─────────────┘ - コード実装
```

## Slackスラッシュコマンド

### `/ai-dev` - 統一開発コマンド

開発請負AIシステムの主要コマンドです。

#### コマンド一覧

| コマンド | 説明 | フェーズ数 |
|---------|------|-----------|
| `/ai-dev new "プロジェクト名" "要件"` | 新規プロジェクト開発 | 4フェーズ |
| `/ai-dev fix #元Issue "修正内容"` | 軽微な修正 | 1フェーズ |
| `/ai-dev bugfix #元Issue "修正内容"` | バグ修正 | 2フェーズ |
| `/ai-dev enhance #元Issue "機能追加"` | 機能追加 | 3フェーズ |
| `/ai-dev refactor #元Issue "内容"` | リファクタリング | 3-4フェーズ |

#### 使用例

```bash
# 新規プロジェクト
/ai-dev new "PDF圧縮デスクトップアプリ" "PDFファイルを圧縮するElectronアプリ"

# バグ修正
/ai-dev bugfix #44 "メモリリーク問題を修正"

# 機能追加
/ai-dev enhance #44 "ドラッグ&ドロップ機能を追加"

# リファクタリング
/ai-dev refactor #44 "コンポーネントを分割してテスタビリティ向上"
```

## 開発フロー

### 新規プロジェクト（4フェーズ）

```
Phase 1 (20%) → 設計書・アーキテクチャ設計
                 - ARCHITECTURE.md
                 - REQUIREMENTS.md
                 ↓
Phase 2 (50%) → MVP実装（最小限の動作）
                 - コア機能のみ
                 - 動作確認
                 ↓
Phase 3 (80%) → 完全実装
                 - すべての要求機能
                 - エラーハンドリング
                 ↓
Phase 4 (100%) → 品質向上・ドキュメント整備
                  - コード品質チェック
                  - README・ドキュメント完成
```

### 継続開発

既存プロジェクトへの機能追加やバグ修正は、タスクタイプに応じて1〜4フェーズで実行されます。

## セットアップ

### クイックスタート

1. **このリポジトリをForkまたはTemplate利用**

2. **必要なサービスを準備**
   - GitHubアカウント
   - Slackワークスペース
   - n8nインスタンス
   - Claude Codeアカウント

3. **セットアップガイドに従う**

   詳細は **[セットアップガイド](docs/SETUP_GUIDE.md)** を参照してください。

### セットアップ時間の目安

- 経験者: 2-3時間
- 初心者: 4-6時間

## ドキュメント

### 主要ドキュメント

- **[セットアップガイド](docs/SETUP_GUIDE.md)** - 詳細なインストール手順
- **[CLAUDE.md](CLAUDE.md)** - Claude Code用の開発ガイドライン

## 対応プロジェクトタイプ

自動ビルド・実行スクリプトが以下のプロジェクトタイプに対応：

- Node.js (package.json)
- Python (requirements.txt, setup.py, pyproject.toml)
- Go (go.mod)
- Rust (Cargo.toml)
- Java/Maven (pom.xml)
- Java/Gradle (build.gradle)
- .NET (*.csproj, *.sln)
- PHP/Composer (composer.json)
- Ruby (Gemfile)

## 使用例

### 実際のプロジェクト例

1. **Electronデスクトップアプリ**
   ```
   /ai-dev new "PDF圧縮ツール" "PDFファイルを圧縮するElectronアプリを作成"
   ```

2. **Webサービス**
   ```
   /ai-dev new "TODOアプリ" "ReactとNode.jsを使ったTODO管理アプリ"
   ```

3. **CLIツール**
   ```
   /ai-dev new "ファイル整理ツール" "Pythonでファイルを種類別に整理するCLI"
   ```

## よくある質問（FAQ）

### Q: このシステムは無料で使えますか？

A: リポジトリ自体はオープンソース（MIT License）ですが、以下のサービスが必要です：
- n8n: $20/月〜（または自己ホスト）
- Claude Code: $20/月〜

最小構成で月額$40程度です。

### Q: 自分のインフラで動きますか？

A: はい。すべて自分の管理下で動作します：
- 自分のGitHubリポジトリ
- 自分のSlackワークスペース
- 自分のn8nインスタンス

### Q: セキュリティは大丈夫ですか？

A: すべてのトークンとキーはGitHub Secretsまたはn8nの認証情報で管理されます。
リポジトリにはハードコードされた機密情報は含まれていません。

### Q: サポートはありますか？

A: コミュニティベースのサポートです。
GitHub Issuesで質問してください。

### Q: 商用利用は可能ですか？

A: はい。MITライセンスなので商用利用可能です。

## トラブルシューティング

問題が発生した場合は[セットアップガイドのトラブルシューティング](docs/SETUP_GUIDE.md#トラブルシューティング)を参照してください。

## 貢献

貢献を歓迎します！

1. このリポジトリをFork
2. Feature branchを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をCommit (`git commit -m 'Add amazing feature'`)
4. BranchをPush (`git push origin feature/amazing-feature`)
5. Pull Requestを作成

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 謝辞

このシステムは以下の素晴らしいツールを活用しています：

- [Claude Code](https://claude.com/claude-code) - AI開発エンジン
- [n8n](https://n8n.io/) - ワークフロー自動化
- [GitHub Actions](https://github.com/features/actions) - CI/CD
- [Slack API](https://api.slack.com/) - インターフェース

## 関連リンク

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [n8n Documentation](https://docs.n8n.io/)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Slack API Documentation](https://api.slack.com/)

---

**注意事項**

このシステムを使用する場合、以下を理解してください：

- ✅ すべてのコードとデータは自分の管理下
- ✅ 自由にカスタマイズ可能
- ⚠️ インフラコストは自己負担
- ⚠️ セットアップと運用は自己責任
- ⚠️ サポートはコミュニティベース

まずは[セットアップガイド](docs/SETUP_GUIDE.md)を読んで、自分の環境で動かしてみてください！
