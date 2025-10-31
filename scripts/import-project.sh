#!/bin/bash

# import-project.sh - 外部プロジェクトを開発請負AIシステムにインポート
#
# 使用方法:
#   ./import-project.sh <リポジトリURL> <プロジェクト名> [オプション]
#
# オプション:
#   --branch <ブランチ名>    インポートするブランチ (デフォルト: main)
#   --tag <タグ名>          特定のタグをインポート
#   --commit <コミットID>    特定のコミットをインポート
#   --subdirectory <パス>    特定のサブディレクトリのみインポート

set -e

# カラー出力の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 引数の解析
REPO_URL=""
PROJECT_NAME=""
BRANCH="main"
TAG=""
COMMIT=""
SUBDIRECTORY=""

# 引数をパース
while [[ $# -gt 0 ]]; do
    case $1 in
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --commit)
            COMMIT="$2"
            shift 2
            ;;
        --subdirectory)
            SUBDIRECTORY="$2"
            shift 2
            ;;
        *)
            if [[ -z "$REPO_URL" ]]; then
                REPO_URL="$1"
            elif [[ -z "$PROJECT_NAME" ]]; then
                PROJECT_NAME="$1"
            fi
            shift
            ;;
    esac
done

# 必須引数のチェック
if [[ -z "$REPO_URL" ]] || [[ -z "$PROJECT_NAME" ]]; then
    echo -e "${RED}エラー: リポジトリURLとプロジェクト名は必須です${NC}"
    echo "使用方法: $0 <リポジトリURL> <プロジェクト名> [オプション]"
    exit 1
fi

# プロジェクトIDを生成（英数字とハイフンのみ）
PROJECT_ID=$(echo "$PROJECT_NAME" | \
    sed 's/[[:space:]]/-/g' | \
    sed 's/[^a-zA-Z0-9-]//g' | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/--*/-/g' | \
    sed 's/^-//' | \
    sed 's/-$//')

if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}エラー: プロジェクトIDを生成できませんでした${NC}"
    exit 1
fi

# GitHub CLIの確認
if ! command -v gh &> /dev/null; then
    echo -e "${RED}エラー: GitHub CLI (gh) がインストールされていません${NC}"
    echo "インストール方法: https://cli.github.com/"
    exit 1
fi

# GitHub CLIの認証確認
if ! gh auth status &> /dev/null; then
    echo -e "${RED}エラー: GitHub CLIが認証されていません${NC}"
    echo "実行してください: gh auth login"
    exit 1
fi

echo -e "${BLUE}📦 プロジェクトのインポートを開始します...${NC}"
echo -e "  リポジトリ: ${YELLOW}$REPO_URL${NC}"
if [[ -n "$TAG" ]]; then
    echo -e "  タグ: ${YELLOW}$TAG${NC}"
elif [[ -n "$COMMIT" ]]; then
    echo -e "  コミット: ${YELLOW}$COMMIT${NC}"
else
    echo -e "  ブランチ: ${YELLOW}$BRANCH${NC}"
fi
echo -e "  プロジェクト名: ${YELLOW}$PROJECT_NAME${NC}"
echo -e "  プロジェクトID: ${YELLOW}$PROJECT_ID${NC}"
if [[ -n "$SUBDIRECTORY" ]]; then
    echo -e "  サブディレクトリ: ${YELLOW}$SUBDIRECTORY${NC}"
fi

# 確認
echo -e "\n${YELLOW}続行しますか？ (y/N)${NC}"
read -r CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "キャンセルしました"
    exit 0
fi

# 一時ディレクトリの作成
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# ソースリポジトリのクローン
echo -e "\n${BLUE}📥 ソースリポジトリをクローン中...${NC}"
cd "$TEMP_DIR"

if [[ -n "$TAG" ]]; then
    git clone --depth 1 --branch "$TAG" "$REPO_URL" source || {
        echo -e "${RED}エラー: リポジトリのクローンに失敗しました${NC}"
        exit 1
    }
elif [[ -n "$COMMIT" ]]; then
    git clone "$REPO_URL" source || {
        echo -e "${RED}エラー: リポジトリのクローンに失敗しました${NC}"
        exit 1
    }
    cd source
    git checkout "$COMMIT" || {
        echo -e "${RED}エラー: 指定されたコミットが見つかりません${NC}"
        exit 1
    }
    cd ..
else
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" source || {
        echo -e "${RED}エラー: リポジトリのクローンに失敗しました${NC}"
        exit 1
    }
fi

cd source

# 現在のコミット情報を取得
CURRENT_COMMIT=$(git rev-parse HEAD)
COMMIT_MESSAGE=$(git log -1 --pretty=%B)
COMMIT_AUTHOR=$(git log -1 --pretty="%an <%ae>")
COMMIT_DATE=$(git log -1 --pretty=%ai)

# 開発請負AIリポジトリのクローン（現在のリポジトリから取得）
echo -e "\n${BLUE}📥 開発請負AIリポジトリをクローン中...${NC}"
cd "$TEMP_DIR"

# 現在のリポジトリのリモートURLを取得
CURRENT_REPO=$(git -C "$SCRIPT_DIR/.." config --get remote.origin.url 2>/dev/null || echo "")
if [[ -z "$CURRENT_REPO" ]]; then
    echo -e "${RED}エラー: リモートリポジトリのURLを取得できませんでした${NC}"
    echo -e "${YELLOW}このスクリプトはGitリポジトリ内で実行する必要があります${NC}"
    exit 1
fi

git clone "$CURRENT_REPO" target || {
    echo -e "${RED}エラー: 開発請負AIリポジトリのクローンに失敗しました${NC}"
    exit 1
}

cd target

# 既存のプロジェクトブランチを確認
if git ls-remote --heads origin | grep -q "refs/heads/project/$PROJECT_ID"; then
    echo -e "${YELLOW}警告: プロジェクトブランチ 'project/$PROJECT_ID' は既に存在します${NC}"
    echo -e "${YELLOW}別のプロジェクトIDを使用するか、既存のブランチを削除してください${NC}"
    exit 1
fi

# 新しいプロジェクトブランチを作成
echo -e "\n${BLUE}🌿 プロジェクトブランチを作成中...${NC}"
git checkout --orphan "project/$PROJECT_ID"
git rm -rf . 2>/dev/null || true

# プロジェクトディレクトリの作成とコピー
echo -e "\n${BLUE}📁 プロジェクトファイルをコピー中...${NC}"
mkdir -p "$PROJECT_ID"

if [[ -n "$SUBDIRECTORY" ]]; then
    # 特定のサブディレクトリのみコピー
    if [[ -d "../source/$SUBDIRECTORY" ]]; then
        cp -r "../source/$SUBDIRECTORY"/* "$PROJECT_ID/" 2>/dev/null || true
        cp -r "../source/$SUBDIRECTORY"/.[^.]* "$PROJECT_ID/" 2>/dev/null || true
    else
        echo -e "${RED}エラー: 指定されたサブディレクトリが見つかりません${NC}"
        exit 1
    fi
else
    # 全体をコピー
    cp -r ../source/* "$PROJECT_ID/" 2>/dev/null || true
    cp -r ../source/.[^.]* "$PROJECT_ID/" 2>/dev/null || true
fi

# .gitディレクトリを削除
rm -rf "$PROJECT_ID/.git"

# プロジェクトメタデータの作成
echo -e "\n${BLUE}📝 プロジェクトメタデータを作成中...${NC}"
cat > "$PROJECT_ID/.project.yml" << EOF
project_id: $PROJECT_ID
project_name: $PROJECT_NAME
import_info:
  source_repository: $REPO_URL
  source_branch: ${TAG:-${COMMIT:-$BRANCH}}
  source_commit: $CURRENT_COMMIT
  imported_at: $(date -I)
  import_method: $(if [[ -n "$TAG" ]]; then echo "tag"; elif [[ -n "$COMMIT" ]]; then echo "commit"; else echo "branch"; fi)
  subdirectory: ${SUBDIRECTORY:-""}
  original_commit:
    hash: $CURRENT_COMMIT
    message: "$COMMIT_MESSAGE"
    author: "$COMMIT_AUTHOR"
    date: "$COMMIT_DATE"
status: imported
initial_issue: pending
EOF

# インポート情報ファイルの作成
cat > "$PROJECT_ID/.import-info.md" << EOF
# インポート情報

このプロジェクトは外部リポジトリからインポートされました。

## ソース情報
- **リポジトリ**: \`$REPO_URL\`
- **ブランチ/タグ/コミット**: \`${TAG:-${COMMIT:-$BRANCH}}\`
- **コミットハッシュ**: \`$CURRENT_COMMIT\`
- **インポート日時**: $(date)
${SUBDIRECTORY:+- **サブディレクトリ**: \`$SUBDIRECTORY\`}

## 元のコミット情報
- **メッセージ**: $COMMIT_MESSAGE
- **作成者**: $COMMIT_AUTHOR
- **日時**: $COMMIT_DATE
EOF

# コミットとプッシュ
echo -e "\n${BLUE}📤 変更をプッシュ中...${NC}"
git add .
git commit -m "Import: $PROJECT_NAME from $REPO_URL" \
    -m "Source: $REPO_URL" \
    -m "Branch/Tag/Commit: ${TAG:-${COMMIT:-$BRANCH}}" \
    -m "Commit: $CURRENT_COMMIT" \
    ${SUBDIRECTORY:+-m "Subdirectory: $SUBDIRECTORY"}

git push -u origin "project/$PROJECT_ID" || {
    echo -e "${RED}エラー: プッシュに失敗しました${NC}"
    exit 1
}

# GitHub Issue の作成
echo -e "\n${BLUE}📋 GitHub Issueを作成中...${NC}"
ISSUE_BODY=$(cat << EOF
## インポート情報

このIssueは既存プロジェクトのインポートにより自動生成されました。

### ソースリポジトリ情報
- **リポジトリ**: \`$REPO_URL\`
- **ブランチ/タグ/コミット**: \`${TAG:-${COMMIT:-$BRANCH}}\`
- **コミットハッシュ**: \`$CURRENT_COMMIT\`
- **インポート日時**: $(date)
${SUBDIRECTORY:+- **サブディレクトリ**: \`$SUBDIRECTORY\`}

### プロジェクト情報
- **プロジェクト名**: $PROJECT_NAME
- **プロジェクトID**: \`$PROJECT_ID\`
- **ブランチ**: \`project/$PROJECT_ID\`

### 元のコミット情報
\`\`\`
コミット: $CURRENT_COMMIT
作成者: $COMMIT_AUTHOR
日時: $COMMIT_DATE

$COMMIT_MESSAGE
\`\`\`

## 次のステップ

このプロジェクトで継続開発を行う場合は、以下のコマンドを使用してください：

### Slackコマンド
- \`/ai-dev enhance #[このIssue番号] "機能追加内容"\`
- \`/ai-dev bugfix #[このIssue番号] "バグ修正内容"\`
- \`/ai-dev refactor #[このIssue番号] "リファクタリング内容"\`

### GitHub Issue
- \`@claude [enhance: #このIssue番号] 機能追加内容\`
- \`@claude [bugfix: #このIssue番号] バグ修正内容\`

---

@claude このプロジェクトの仕様書を作成してください。ブランチ \`project/$PROJECT_ID\` のコードを解析し、以下の情報を含めてください：

1. プロジェクトの概要
2. 使用技術・フレームワーク
3. 主要機能の説明
4. ディレクトリ構造
5. セットアップ手順
6. 今後の拡張可能性
EOF
)

# リポジトリ情報を自動取得
REPO_INFO=$(git config --get remote.origin.url | sed -n 's/.*github\.com[:/]\(.*\)\.git.*/\1/p')
if [[ -z "$REPO_INFO" ]]; then
    REPO_INFO=$(git config --get remote.origin.url | sed -n 's/.*github\.com[:/]\(.*\)/\1/p')
fi

ISSUE_URL=$(gh issue create \
    --repo "$REPO_INFO" \
    --title "[Import] $PROJECT_NAME - 既存プロジェクトのインポート" \
    --body "$ISSUE_BODY") || {
    echo -e "${RED}エラー: Issue作成に失敗しました${NC}"
    echo -e "${YELLOW}手動でIssueを作成してください${NC}"
    exit 1
}

# 完了メッセージ
echo -e "\n${GREEN}✅ インポートが完了しました！${NC}"
echo -e "\n📊 インポート結果:"
echo -e "  プロジェクトID: ${YELLOW}$PROJECT_ID${NC}"
echo -e "  ブランチ: ${YELLOW}project/$PROJECT_ID${NC}"
if [[ -n "$ISSUE_URL" ]]; then
    echo -e "  Issue: ${BLUE}$ISSUE_URL${NC}"
    
    # Issue番号を抽出
    ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -o '[0-9]*$')
    echo -e "\n📝 次のアクション:"
    echo -e "  1. 上記のIssueでClaudeが仕様書を作成するのを待つ"
    echo -e "  2. 継続開発する場合:"
    echo -e "     ${YELLOW}/ai-dev enhance #$ISSUE_NUMBER \"機能追加内容\"${NC}"
fi

echo -e "\n${GREEN}プロジェクトのインポートが成功しました！${NC}"