#!/bin/bash

# export-project.sh - プロジェクトディレクトリを独立したリポジトリとして切り出す
#
# 使用方法:
#   ./export-project.sh <プロジェクトディレクトリ> <新リポジトリ名> [オプション]
#
# オプション:
#   --with-history    履歴を保持して切り出す（git subtree使用）
#   --github-create   GitHubに新リポジトリを自動作成
#   --private        プライベートリポジトリとして作成（--github-create時のみ）

set -e

# カラー出力の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 引数の解析
PROJECT_DIR=""
NEW_REPO_NAME=""
WITH_HISTORY=false
GITHUB_CREATE=false
PRIVATE=false

# 引数をパース
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-history)
            WITH_HISTORY=true
            shift
            ;;
        --github-create)
            GITHUB_CREATE=true
            shift
            ;;
        --private)
            PRIVATE=true
            shift
            ;;
        *)
            if [[ -z "$PROJECT_DIR" ]]; then
                PROJECT_DIR="$1"
            elif [[ -z "$NEW_REPO_NAME" ]]; then
                NEW_REPO_NAME="$1"
            fi
            shift
            ;;
    esac
done

# 必須引数のチェック
if [[ -z "$PROJECT_DIR" ]] || [[ -z "$NEW_REPO_NAME" ]]; then
    echo -e "${RED}エラー: プロジェクトディレクトリと新リポジトリ名は必須です${NC}"
    echo "使用方法: $0 <プロジェクトディレクトリ> <新リポジトリ名> [オプション]"
    exit 1
fi

# プロジェクトディレクトリの存在確認
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo -e "${RED}エラー: プロジェクトディレクトリが存在しません: $PROJECT_DIR${NC}"
    exit 1
fi

# GitHub CLIの確認（必要な場合）
if $GITHUB_CREATE; then
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}エラー: GitHub CLI (gh) がインストールされていません${NC}"
        echo "インストール方法: https://cli.github.com/"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}エラー: GitHub CLIが認証されていません${NC}"
        echo "実行してください: gh auth login"
        exit 1
    fi
fi

echo -e "${BLUE}📦 プロジェクトのエクスポートを開始します...${NC}"
echo -e "  プロジェクトディレクトリ: ${YELLOW}$PROJECT_DIR${NC}"
echo -e "  新リポジトリ名: ${YELLOW}$NEW_REPO_NAME${NC}"
echo -e "  履歴保持: ${YELLOW}$(if $WITH_HISTORY; then echo "はい"; else echo "いいえ"; fi)${NC}"
echo -e "  GitHub作成: ${YELLOW}$(if $GITHUB_CREATE; then echo "はい"; else echo "いいえ"; fi)${NC}"
if $GITHUB_CREATE; then
    echo -e "  リポジトリタイプ: ${YELLOW}$(if $PRIVATE; then echo "プライベート"; else echo "パブリック"; fi)${NC}"
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

# エクスポート処理
if $WITH_HISTORY; then
    echo -e "\n${BLUE}📥 履歴付きでプロジェクトを切り出し中...${NC}"
    
    # プロジェクトブランチの確認
    PROJECT_BRANCH="project/$(basename $PROJECT_DIR)"
    
    # git subtreeを使用して履歴を保持して切り出す
    # プロジェクトルートディレクトリに移動
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    cd "$REPO_ROOT"
    
    # 現在のブランチを保存
    CURRENT_BRANCH=$(git branch --show-current)
    
    # プロジェクトブランチが存在する場合はチェックアウト
    if git show-ref --verify --quiet "refs/heads/$PROJECT_BRANCH"; then
        git checkout "$PROJECT_BRANCH"
    fi
    
    # subtree splitで新しいブランチを作成
    echo -e "${BLUE}履歴を抽出中...${NC}"
    git subtree split --prefix="$(basename $PROJECT_DIR)" -b temp-export-branch
    
    # 新しいリポジトリを作成
    cd "$TEMP_DIR"
    git init "$NEW_REPO_NAME"
    cd "$NEW_REPO_NAME"
    
    # 切り出したブランチをpull
    git pull "$REPO_ROOT" temp-export-branch
    
    # 一時ブランチを削除
    cd "$REPO_ROOT"
    git branch -D temp-export-branch
    
    # 元のブランチに戻る
    git checkout "$CURRENT_BRANCH"
    
else
    echo -e "\n${BLUE}📁 プロジェクトファイルをコピー中...${NC}"
    
    # 新しいリポジトリディレクトリを作成
    mkdir -p "$TEMP_DIR/$NEW_REPO_NAME"
    
    # ファイルをコピー（.gitディレクトリを除く）
    cd "$PROJECT_DIR"
    find . -type f -not -path "./.git/*" -not -path "./.next/*" -not -path "./node_modules/*" -not -path "./.env.local" | while read -r file; do
        dir=$(dirname "$file")
        mkdir -p "$TEMP_DIR/$NEW_REPO_NAME/$dir"
        cp "$file" "$TEMP_DIR/$NEW_REPO_NAME/$file"
    done
    
    # 新しいリポジトリを初期化
    cd "$TEMP_DIR/$NEW_REPO_NAME"
    git init
    git add .
    git commit -m "Initial commit - Exported from ai-development-company/$PROJECT_DIR"
fi

# README.mdの追加または更新
cd "$TEMP_DIR/$NEW_REPO_NAME"

if [[ ! -f "README.md" ]]; then
    echo -e "\n${BLUE}📝 README.mdを作成中...${NC}"

    # 元のリポジトリ情報を取得
    ORIGIN_REMOTE=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [[ -n "$ORIGIN_REMOTE" ]]; then
        # GitHub URLから owner/repo を抽出
        REPO_INFO=$(echo "$ORIGIN_REMOTE" | sed -n 's/.*github\.com[:/]\(.*\)\.git.*/\1/p')
        if [[ -z "$REPO_INFO" ]]; then
            REPO_INFO=$(echo "$ORIGIN_REMOTE" | sed -n 's/.*github\.com[:/]\(.*\)/\1/p')
        fi
        ORIGIN_LINK="[ai-development-company](https://github.com/$REPO_INFO)"
    else
        ORIGIN_LINK="ai-development-company システム"
    fi

    cat > README.md << EOF
# $NEW_REPO_NAME

このプロジェクトは $ORIGIN_LINK の \`$PROJECT_DIR\` ディレクトリからエクスポートされました。

## エクスポート情報
- エクスポート日時: $(date)
- 元のプロジェクト: \`$PROJECT_DIR\`
- 履歴保持: $(if $WITH_HISTORY; then echo "あり"; else echo "なし"; fi)

## プロジェクト情報
[元のプロジェクト情報をここに記載]
EOF
    git add README.md
    git commit -m "docs: Add export information to README"
fi

# GitHubリポジトリの作成
if $GITHUB_CREATE; then
    echo -e "\n${BLUE}🌐 GitHubリポジトリを作成中...${NC}"
    
    # GitHubユーザー名を取得
    GH_USER=$(gh api user -q .login)
    
    # リポジトリ作成オプション
    CREATE_OPTS=""
    if $PRIVATE; then
        CREATE_OPTS="--private"
    else
        CREATE_OPTS="--public"
    fi
    
    # リポジトリを作成
    gh repo create "$GH_USER/$NEW_REPO_NAME" $CREATE_OPTS --source=. --push || {
        echo -e "${YELLOW}警告: GitHubリポジトリの作成に失敗しました${NC}"
        echo -e "${YELLOW}手動でリポジトリを作成し、以下のコマンドを実行してください:${NC}"
        echo -e "  git remote add origin https://github.com/$GH_USER/$NEW_REPO_NAME.git"
        echo -e "  git branch -M main"
        echo -e "  git push -u origin main"
    }
    
    REPO_URL="https://github.com/$GH_USER/$NEW_REPO_NAME"
else
    # ローカルリポジトリのパスを出力
    REPO_PATH="$TEMP_DIR/$NEW_REPO_NAME"
    
    # 実際のディレクトリにコピー
    TARGET_DIR="$(pwd)/../$NEW_REPO_NAME"
    echo -e "\n${BLUE}📁 リポジトリを保存中...${NC}"
    cp -r "$REPO_PATH" "$TARGET_DIR"
    REPO_PATH="$TARGET_DIR"
fi

# 完了メッセージ
echo -e "\n${GREEN}✅ エクスポートが完了しました！${NC}"
echo -e "\n📊 エクスポート結果:"
echo -e "  新リポジトリ名: ${YELLOW}$NEW_REPO_NAME${NC}"

if $GITHUB_CREATE && [[ -n "$REPO_URL" ]]; then
    echo -e "  GitHubリポジトリ: ${BLUE}$REPO_URL${NC}"
else
    echo -e "  ローカルパス: ${YELLOW}$REPO_PATH${NC}"
    echo -e "\n📝 次のステップ:"
    echo -e "  1. cd $REPO_PATH"
    echo -e "  2. GitHubでリポジトリを作成"
    echo -e "  3. git remote add origin <your-repository-url>"
    echo -e "  4. git push -u origin main"
fi

echo -e "\n${GREEN}プロジェクトのエクスポートが成功しました！${NC}"