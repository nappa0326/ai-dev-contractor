#!/bin/bash

# run-project.sh - プロジェクトを簡単に実行するスクリプト
#
# 使用方法:
#   ./run-project.sh <project-name>
#
# 例:
#   ./run-project.sh pdf-compressor

set -e

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 引数チェック
if [ $# -lt 1 ]; then
    echo -e "${RED}エラー: プロジェクト名を指定してください${NC}"
    echo "使用方法: $0 <project-name>"
    echo ""
    echo "利用可能なプロジェクト:"
    # リモートブランチ情報を更新
    git fetch --all --quiet 2>/dev/null || true
    git branch -r | grep "origin/project/" | grep -v "phase" | sed 's/.*origin\/project\//  - /'
    exit 1
fi

PROJECT_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# プロジェクトタイプ検出スクリプトを読み込む
# source "$SCRIPT_DIR/detect-project-type.sh"  # 直接実行するように変更

echo -e "${BLUE}🚀 プロジェクトを起動します...${NC}"
echo -e "プロジェクト: ${YELLOW}$PROJECT_NAME${NC}"

# 現在のブランチを保存
CURRENT_BRANCH=$(git branch --show-current)

# プロジェクトブランチをチェックアウト
echo -e "\n${BLUE}📥 プロジェクトをチェックアウト中...${NC}"
git checkout "project/$PROJECT_NAME" 2>/dev/null || {
    echo -e "${RED}エラー: プロジェクトブランチが見つかりません${NC}"
    echo -e "${YELLOW}ヒント: 利用可能なプロジェクトを確認するには、引数なしで実行してください${NC}"
    exit 1
}

# プロジェクトタイプを検出
echo -e "\n${BLUE}🔍 プロジェクトタイプを検出中...${NC}"
DETECT_OUTPUT=$("$SCRIPT_DIR/detect-project-type.sh" .)
eval "$DETECT_OUTPUT"

echo -e "タイプ: ${YELLOW}$PROJECT_TYPE${NC}"
echo -e "ディレクトリ: ${YELLOW}$PROJECT_DIR${NC}"

cd "$PROJECT_DIR"

# クリーンアップ関数
cleanup() {
    echo -e "\n${BLUE}🧹 クリーンアップ中...${NC}"
    cd - > /dev/null 2>&1
    git checkout "$CURRENT_BRANCH" > /dev/null 2>&1
    echo -e "${GREEN}元のブランチに戻りました${NC}"
}

# 終了時にクリーンアップを実行
trap cleanup EXIT INT TERM

# 実行関数
run_node_app() {
    echo -e "\n${BLUE}📦 依存関係をインストール中...${NC}"
    
    if [ -f "yarn.lock" ]; then
        yarn install
    elif [ -f "package-lock.json" ]; then
        npm ci
    else
        npm install
    fi
    
    echo -e "\n${GREEN}▶️  アプリケーションを起動中...${NC}"
    
    # 実行スクリプトを確認
    if grep -q '"start"' package.json; then
        npm start
    elif grep -q '"dev"' package.json; then
        npm run dev
    elif [ -f "$ENTRY_FILE" ]; then
        node "$ENTRY_FILE"
    else
        echo -e "${RED}エラー: 起動スクリプトが見つかりません${NC}"
        echo -e "${YELLOW}package.jsonにstartスクリプトを追加してください${NC}"
        exit 1
    fi
}

run_python_app() {
    echo -e "\n${BLUE}🐍 Python環境をセットアップ中...${NC}"
    
    # 仮想環境を作成（既存の場合はスキップ）
    if [ ! -d "venv" ]; then
        python -m venv venv || python3 -m venv venv
    fi
    
    # 仮想環境を有効化
    if [ -f "venv/Scripts/activate" ]; then
        source venv/Scripts/activate
    else
        source venv/bin/activate
    fi
    
    echo -e "\n${BLUE}📦 依存関係をインストール中...${NC}"
    pip install -r requirements.txt
    
    echo -e "\n${GREEN}▶️  アプリケーションを起動中...${NC}"
    
    # Streamlitアプリの場合
    if [ "$PROJECT_TYPE" = "python-web" ] && grep -q "streamlit" requirements.txt; then
        streamlit run "$ENTRY_FILE"
    else
        python "$ENTRY_FILE"
    fi
}

run_go_app() {
    echo -e "\n${BLUE}🔵 Go依存関係をダウンロード中...${NC}"
    go mod download
    
    echo -e "\n${GREEN}▶️  アプリケーションを起動中...${NC}"
    go run .
}

run_web_app() {
    case "$PROJECT_TYPE" in
        nextjs-web|react-spa)
            run_node_app
            ;;
        python-web)
            run_python_app
            ;;
        *)
            echo -e "${RED}エラー: 未対応のWebアプリタイプです${NC}"
            exit 1
            ;;
    esac
}

# ポート情報を表示
show_port_info() {
    echo -e "\n${BLUE}🌐 アプリケーション情報:${NC}"
    
    case "$PROJECT_TYPE" in
        nextjs-web|react-spa|node-app)
            echo -e "URL: ${GREEN}http://localhost:3000${NC}"
            echo -e "（ポートは設定により異なる場合があります）"
            ;;
        python-web)
            if grep -q "streamlit" requirements.txt 2>/dev/null; then
                echo -e "URL: ${GREEN}http://localhost:8501${NC}"
            elif grep -q "flask" requirements.txt 2>/dev/null; then
                echo -e "URL: ${GREEN}http://localhost:5000${NC}"
            elif grep -q "fastapi" requirements.txt 2>/dev/null; then
                echo -e "URL: ${GREEN}http://localhost:8000${NC}"
            fi
            ;;
    esac
    
    echo -e "\n${YELLOW}Ctrl+C で終了します${NC}"
}

# メインの実行処理
echo -e "\n${BLUE}🏃 プロジェクトを実行中...${NC}"

case "$PROJECT_TYPE" in
    electron-app)
        run_node_app
        ;;
    node-cli|node-app)
        run_node_app
        ;;
    python-app|python-web)
        run_python_app
        ;;
    go-app)
        run_go_app
        ;;
    nextjs-web|react-spa)
        show_port_info
        run_web_app
        ;;
    *)
        echo -e "${RED}エラー: 未対応のプロジェクトタイプです: $PROJECT_TYPE${NC}"
        exit 1
        ;;
esac