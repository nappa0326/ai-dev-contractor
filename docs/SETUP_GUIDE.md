# 開発請負AIシステム セットアップガイド

このシステムを自分の環境で動かすための詳細なセットアップ手順です。

## 前提条件

このシステムを動かすには、以下のインフラとサービスが必要です：

### 必須インフラ

1. **GitHubリポジトリ**（無料）
   - GitHub Actions実行のため
   - Claude Codeとの統合のため

2. **Slackワークスペース**（無料プランでOK）
   - 発注インターフェースとして使用
   - 進捗通知の受信

3. **n8nインスタンス**（有料または自己ホスト）
   - ワークフロー自動化エンジン
   - オプション：
     - n8n Cloud（$20/月〜）: https://n8n.io/pricing/
     - 自己ホスト（VPS等で無料〜）: https://docs.n8n.io/hosting/

4. **Claude Code**（有料）
   - AI開発の実行エンジン
   - https://claude.com/claude-code

### 推奨スキル

- Gitの基本操作
- GitHub ActionsとWebhookの理解
- Slack App作成の経験
- n8nの基本的な使い方

### 推定セットアップ時間

- 経験者: 2-3時間
- 初心者: 4-6時間

---

## セットアップ手順

### Step 1: GitHubリポジトリの準備

#### 1-1. このリポジトリをFork

```bash
# ブラウザでForkするか、テンプレートとして使用
# GitHubでこのリポジトリを開き、右上の「Fork」または「Use this template」をクリック
```

#### 1-2. ローカルにクローン

```bash
git clone https://github.com/YOUR_USERNAME/ai-development-company.git
cd ai-development-company
```

#### 1-3. GitHub Secretsの設定

リポジトリの Settings → Secrets and variables → Actions で以下を設定：

| Secret名 | 説明 | 取得方法 |
|---------|------|---------|
| `CLAUDE_CODE_OAUTH_TOKEN` | Claude Code認証トークン | [Claude Code設定](https://claude.com/claude-code/settings)から取得 |
| `PAT_WITH_REPO_SCOPE` | GitHub Personal Access Token | [GitHub Settings](https://github.com/settings/tokens) → repo権限を付与 |

**GITHUB_TOKEN**は自動的に提供されるため、設定不要です。

---

### Step 2: n8nのセットアップ

#### オプション A: n8n Cloud（推奨）

1. **n8nアカウント作成**
   - https://n8n.io/ でサインアップ
   - プランを選択（$20/月〜）

2. **インスタンスを起動**
   - 自動的にWebhook URLが発行されます
   - 例: `https://your-instance.app.n8n.cloud/webhook/`

#### オプション B: 自己ホスト（上級者向け）

```bash
# Dockerで起動
docker run -d \
  --name n8n \
  --restart unless-stopped \
  -p 5678:5678 \
  -e N8N_HOST=your-n8n-domain.com \
  -e N8N_PROTOCOL=https \
  -e GENERIC_TIMEZONE=Asia/Tokyo \
  -e TZ=Asia/Tokyo \
  -e WEBHOOK_URL=https://your-n8n-domain.com/ \
  -e SLACK_CHANNEL_ID=C0XXXXXXXXX \
  -e N8N_BLOCK_ENV_ACCESS_IN_NODE=false \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n:latest

# または Docker Compose
# 詳細: https://docs.n8n.io/hosting/installation/docker/
```

**重要な環境変数**:
- `SLACK_CHANNEL_ID`: Slack通知先チャンネルID（必須）
- `N8N_BLOCK_ENV_ACCESS_IN_NODE=false`: ワークフローで環境変数アクセスを許可（必須）
- `N8N_HOST`, `N8N_PROTOCOL`: 外部アクセス用のURL設定

**重要**: 外部からアクセス可能なURLを確保してください（ngrok、Cloudflare Tunnelなど）。

#### 2-1. ワークフローのインポート

1. n8nのWebインターフェースにアクセス
2. 左上の「Workflows」→「Import from File」
3. 以下のファイルを順番にインポート：

```
n8n-workflows/
├── AI開発会社 - プロジェクト受注システム.json
├── AI開発会社 - Slack発注システム.json
├── Github PR監視システム.json
├── Github PR承認監視システム.json
├── Slack開発制御システム.json
├── PR作成通知システム.json
└── エラー通知システム.json
```

#### 2-2. ワークフローのカスタマイズ（重要）

インポート後、以下の値を**あなたの環境に合わせて変更**してください：

##### A. GitHubリポジトリ情報の変更

**対象ワークフロー**:
- `AI開発会社 - プロジェクト受注システム`
- `Github PR監視システム`

**変更箇所**:

1. **AI開発会社 - プロジェクト受注システム**
   - `Code` ノード内のJavaScriptコード
   - 検索: `nappa0326`
   - 置換: `あなたのGitHubユーザー名`
   - 該当箇所: `assignees: ['nappa0326']` (2箇所)

   - `HTTP Request - Create an issue` ノードのURL
   - 変更前: `https://api.github.com/repos/nappa0326/ai-development-company/issues`
   - 変更後: `https://api.github.com/repos/YOUR_USERNAME/YOUR_REPO/issues`

2. **Github PR監視システム**
   - `Code` ノード内のJavaScriptコード
   - 検索: `nappa0326/ai-development-company`
   - 置換: `あなたのGitHubユーザー名/リポジトリ名`
   - 該当箇所: ``https://github.com/nappa0326/ai-development-company/pull/${prNumber}``

##### B. Webhook URLの更新

各ワークフローで以下のURLを**あなたのn8n URL**に書き換えてください：

| 元のURL | 置換先 |
|--------|-------|
| `https://n8n.oppy-ai.com/webhook/` | `https://YOUR_N8N_URL/webhook/` |

**置換が必要な箇所**：
- HTTP Requestノード内のURL
- Webhookノード内のパス

**一括置換スクリプト**（オプション）:
```bash
# Linux/macOS
find n8n-workflows -name "*.json" -exec sed -i 's|https://n8n.oppy-ai.com|https://YOUR_N8N_URL|g' {} \;

# Windows PowerShell
Get-ChildItem n8n-workflows/*.json | ForEach-Object {
    (Get-Content $_.FullName) -replace 'https://n8n.oppy-ai.com', 'https://YOUR_N8N_URL' | Set-Content $_.FullName
}
```

#### 2-3. n8n認証情報の設定

n8nで以下の認証情報を設定：

1. **GitHub認証**
   - Settings → Credentials → Add Credential → GitHub
   - Personal Access Tokenを入力（repo権限必要）

2. **Slack認証**（次のステップで取得）
   - Settings → Credentials → Add Credential → Slack OAuth2 API
   - Bot User OAuth Tokenを入力

---

### Step 3: Slack Appの作成と設定

#### 3-1. Slack Appの作成

1. **Slack API管理画面を開く**
   - https://api.slack.com/apps
   - 「Create New App」→「From scratch」

2. **App名とワークスペースを選択**
   - App Name: `AI開発会社`（任意）
   - Workspace: あなたのワークスペース

#### 3-2. Bot Token Scopesの設定

「OAuth & Permissions」→「Scopes」→「Bot Token Scopes」で以下を追加：

```
chat:write          - メッセージ送信
chat:write.public   - パブリックチャンネルへの投稿
commands           - スラッシュコマンド
```

#### 3-3. スラッシュコマンドの作成

「Slash Commands」→「Create New Command」で以下を設定：

| 項目 | 値 |
|-----|-----|
| Command | `/ai-dev` |
| Request URL | `https://YOUR_N8N_URL/webhook/slack-order` |
| Short Description | AI開発請負システム |
| Usage Hint | `new "プロジェクト名" "要件"` |

#### 3-4. Interactive Componentsの有効化

「Interactivity & Shortcuts」で以下を設定：

| 項目 | 値 |
|-----|-----|
| Interactivity | ON |
| Request URL | `https://YOUR_N8N_URL/webhook/slack-interactive` |

#### 3-5. Bot Tokenの取得とインストール

1. 「OAuth & Permissions」→「Install to Workspace」
2. 権限を確認して「Allow」
3. 表示される**Bot User OAuth Token**（`xoxb-`で始まる）をコピー
4. n8nの認証情報に設定

#### 3-6. Signing Secretの取得

「Basic Information」→「App Credentials」→「Signing Secret」をコピー
（オプション：署名検証を実装する場合に使用）

---

### Step 4: GitHub Webhookの設定

#### 4-1. Webhookの追加

GitHubリポジトリの Settings → Webhooks → Add webhook

| 項目 | 値 |
|-----|-----|
| Payload URL | `https://YOUR_N8N_URL/webhook/github-pr` |
| Content type | `application/json` |
| Secret | （空欄でOK、またはランダムな文字列） |
| Events | 以下を選択: |
|  | - Pull requests |
|  | - Issue comments |
|  | - Pull request reviews |
|  | - Pull request review comments |

「Add webhook」をクリック。

#### 4-2. 接続確認

Webhookの「Recent Deliveries」タブで配信履歴を確認。
緑のチェックマークが表示されればOK。

---

### Step 5: 動作確認

#### 5-1. テストIssueの作成

GitHubリポジトリで新しいIssueを作成：

```markdown
タイトル: テストプロジェクト

本文:
@claude シンプルなHello Worldアプリを作成してください
```

#### 5-2. 確認ポイント

- [ ] GitHub ActionsでClaude Codeワークフローが起動
- [ ] Slackに進捗通知が届く
- [ ] PRが自動作成される
- [ ] PR作成通知がSlackに届く

#### 5-3. Slackコマンドのテスト

Slackで以下を実行：

```
/ai-dev new "テストプロジェクト" "Hello Worldを出力するシンプルなアプリ"
```

確認：
- [ ] Slackに受注完了メッセージが表示
- [ ] GitHubにIssueが自動作成
- [ ] Claude Codeが自動実行

---

## トラブルシューティング

### よくある問題

#### 1. Claude Codeが起動しない

**症状**: GitHub Issueに`@claude`とコメントしても反応しない

**確認事項**:
- [ ] `CLAUDE_CODE_OAUTH_TOKEN`がGitHub Secretsに設定されているか
- [ ] claude.ymlが正しく配置されているか（`.github/workflows/claude.yml`）
- [ ] GitHub Actionsが有効になっているか（Settings → Actions）

**解決方法**:
```bash
# ワークフロー実行履歴を確認
https://github.com/YOUR_USERNAME/ai-development-company/actions
```

#### 2. n8n Webhookが応答しない

**症状**: Slackコマンドやボタンクリックが反応しない

**確認事項**:
- [ ] n8nワークフローがActiveになっているか
- [ ] Webhook URLが正しいか（HTTPSか、末尾のスラッシュ等）
- [ ] n8nが外部からアクセス可能か

**解決方法**:
```bash
# Webhook URLをテスト
curl -X POST https://YOUR_N8N_URL/webhook/test
```

#### 3. Slack通知が届かない

**症状**: GitHubの動きは正常だがSlackに通知が来ない

**確認事項**:
- [ ] Slack Bot TokenがN8nに正しく設定されているか
- [ ] BotがチャンネルにInviteされているか
- [ ] n8nのSlackノードが正しく設定されているか

**解決方法**:
Slack Appの「Event Subscriptions」→「Subscribe to bot events」を確認。

#### 4. GitHub Webhook配信エラー

**症状**: GitHubのWebhook画面に赤い×マーク

**確認事項**:
- [ ] n8nのWebhook URLが間違っていないか
- [ ] n8nが起動しているか
- [ ] ファイアウォールでブロックされていないか

**解決方法**:
Recent Deliveriesからエラー内容を確認。

---

## セキュリティのベストプラクティス

### 必須

1. **すべてのトークンをGitHub Secretsで管理**
   - ❌ ハードコードしない
   - ✅ Secretsまたは環境変数を使用

2. **Webhook署名の検証**
   - Slackの署名検証を実装（[docs/slack-app-interactive-setup.md](slack-app-interactive-setup.md)参照）
   - GitHub Webhookのシークレットを設定

3. **最小権限の原則**
   - GitHub PAT: repo権限のみ
   - Slack Bot: 必要なスコープのみ

### 推奨

1. **n8nのアクセス制御**
   - 基本認証またはOAuth2を有効化
   - IPホワイトリスト設定（可能な場合）

2. **定期的なトークンローテーション**
   - 3-6ヶ月ごとにトークンを再生成

3. **監査ログの確認**
   - n8nの実行履歴を定期的にチェック
   - GitHub Actionsの実行ログを確認

---

## コスト見積もり

### 最小構成

| サービス | プラン | 月額 |
|---------|-------|------|
| GitHub | Freeプラン | $0 |
| Slack | Freeプラン | $0 |
| n8n | Starterプラン | $20 |
| Claude Code | Proプラン | $20 |
| **合計** | | **$40/月** |

### 推奨構成（中規模チーム）

| サービス | プラン | 月額 |
|---------|-------|------|
| GitHub | Team | $4/user |
| Slack | Pro | $7.25/user |
| n8n | Proプラン | $50 |
| Claude Code | Pro | $20 |

---

## 次のステップ

セットアップが完了したら：

1. [CLAUDE.md](../CLAUDE.md)を読んで開発フローを理解
2. [README.md](../README.md)でSlackコマンドの使い方を確認
3. 実際のプロジェクトで試してみる

## サポート

問題が解決しない場合：

1. GitHub Issuesで質問
2. このセットアップガイドの関連セクションを再確認
3. n8nワークフローのログを確認してエラーメッセージを特定

---

**重要な注意事項**

このシステムはあなた自身のインフラで動作します。以下を理解した上で使用してください：

- ✅ すべてのコードとデータは自分の管理下
- ✅ プライバシーが保護される
- ⚠️ インフラコストは自己負担
- ⚠️ セットアップと運用は自己責任
- ⚠️ サポートはコミュニティベース
