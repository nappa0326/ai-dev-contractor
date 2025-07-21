# Scripts ディレクトリ

開発請負AIシステムで使用する各種スクリプトを格納しています。

## import-project.sh

外部のGitリポジトリを開発請負AIシステムにインポートするためのスクリプトです。

### 機能

- 任意のGitリポジトリ（Public/Private）をインポート
- 特定のブランチ、タグ、コミットを指定可能
- モノレポの特定ディレクトリのみインポート可能
- 自動的にGitHub Issueを作成
- インポート後は通常の継続開発フローで開発可能

### 前提条件

1. **GitHub CLI (gh) のインストール**
   ```bash
   # macOS
   brew install gh
   
   # Ubuntu/Debian
   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
   sudo apt update
   sudo apt install gh
   ```

2. **GitHub CLI の認証**
   ```bash
   gh auth login
   ```

3. **開発請負AIリポジトリへのアクセス権限**

### 使用方法

#### 基本的な使い方
```bash
./import-project.sh <リポジトリURL> <プロジェクト名>
```

#### オプション
- `--branch <ブランチ名>` - インポートするブランチを指定（デフォルト: main）
- `--tag <タグ名>` - 特定のタグをインポート
- `--commit <コミットID>` - 特定のコミットをインポート
- `--subdirectory <パス>` - 特定のサブディレクトリのみインポート

### 使用例

#### 1. Publicリポジトリのインポート（デフォルトブランチ）
```bash
./import-project.sh https://github.com/user/todo-app "TODOアプリ"
```

#### 2. Privateリポジトリのインポート（SSH）
```bash
./import-project.sh git@github.com:company/internal-tool.git "社内ツール"
```

#### 3. 特定のブランチをインポート
```bash
./import-project.sh https://github.com/user/webapp "Webアプリ" --branch develop
```

#### 4. 特定のタグをインポート
```bash
./import-project.sh https://github.com/user/library "ライブラリv2.0" --tag v2.0.0
```

#### 5. モノレポの特定ディレクトリをインポート
```bash
./import-project.sh https://github.com/company/monorepo "フロントエンド" \
  --subdirectory apps/frontend
```

#### 6. 特定のコミットをインポート
```bash
./import-project.sh https://github.com/user/project "安定版" \
  --commit abc123def456
```

### インポート後の流れ

1. スクリプトが自動的に以下を実行：
   - プロジェクト専用ブランチ `project/<project-id>` を作成
   - ソースコードをプロジェクトディレクトリにコピー
   - プロジェクトメタデータ（.project.yml）を作成
   - GitHub Issueを作成（`@claude` メンション付き）

2. Claudeが自動的に：
   - プロジェクトの仕様書を作成
   - 技術スタックを解析
   - セットアップ手順を文書化

3. 継続開発：
   ```bash
   # Slackから
   /ai-dev enhance #<Issue番号> "新機能追加"
   /ai-dev bugfix #<Issue番号> "バグ修正"
   
   # GitHub Issueから
   @claude [enhance: #<Issue番号>] 新機能追加
   ```

### トラブルシューティング

#### "GitHub CLIが認証されていません" エラー
```bash
gh auth login
# ブラウザが開くので、GitHubアカウントで認証
```

#### "プロジェクトブランチが既に存在します" エラー
- 別のプロジェクト名を使用するか
- 既存のブランチを削除してから再実行

#### Privateリポジトリへのアクセスエラー
- SSH鍵が正しく設定されているか確認
- リポジトリへのアクセス権限があるか確認

### セキュリティに関する注意

- インポート時の認証情報はローカルのGit設定を使用
- トークンやパスワードはスクリプトに保存されません
- インポートされたコードは開発請負AIリポジトリに保存されます

### 制限事項

- リポジトリサイズが大きい場合は時間がかかります
- Git LFSを使用しているリポジトリは追加設定が必要な場合があります
- サブモジュールは自動的にはインポートされません