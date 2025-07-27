#!/bin/bash

# build-project.sh - プロジェクトを自動的にビルドするスクリプト
#
# 使用方法:
#   ./build-project.sh <project-name> [platform]
#
# 例:
#   ./build-project.sh pdf-compressor
#   ./build-project.sh pdf-compressor windows

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
    echo "使用方法: $0 <project-name> [platform]"
    exit 1
fi

PROJECT_NAME="$1"
PLATFORM="${2:-all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# プロジェクトタイプ検出スクリプトを読み込む
# source "$SCRIPT_DIR/detect-project-type.sh"  # 直接実行するように変更

echo -e "${BLUE}🔨 プロジェクトのビルドを開始します...${NC}"
echo -e "プロジェクト: ${YELLOW}$PROJECT_NAME${NC}"

# プロジェクトブランチをチェックアウト
echo -e "\n${BLUE}📥 プロジェクトをチェックアウト中...${NC}"
git checkout "project/$PROJECT_NAME" 2>/dev/null || {
    echo -e "${RED}エラー: プロジェクトブランチが見つかりません${NC}"
    exit 1
}

# プロジェクトタイプを検出
echo -e "\n${BLUE}🔍 プロジェクトタイプを検出中...${NC}"
eval "$("$SCRIPT_DIR/detect-project-type.sh" .)"

echo -e "タイプ: ${YELLOW}$PROJECT_TYPE${NC}"
echo -e "ディレクトリ: ${YELLOW}$PROJECT_DIR${NC}"

cd "$PROJECT_DIR"

# ビルド関数
build_electron() {
    local platform=$1
    echo -e "\n${BLUE}🖥️  Electronアプリをビルド中 (${platform})...${NC}"
    
    npm install
    
    # ソースコードをビルド
    echo -e "${BLUE}📦 ソースコードをビルド中...${NC}"
    npm run build || {
        echo -e "${YELLOW}警告: ビルドスクリプトが見つかりません${NC}"
        echo -e "${YELLOW}distディレクトリが既に存在することを期待します${NC}"
    }
    
    # distディレクトリの存在確認
    if [ ! -f "dist/main.js" ]; then
        echo -e "${RED}エラー: dist/main.js が見つかりません${NC}"
        echo -e "${YELLOW}ヒント: ソースコードのビルドが必要です${NC}"
        exit 1
    fi
    
    case "$platform" in
        windows|win)
            npm run dist -- --win || npx electron-builder --win
            ;;
        mac|darwin)
            npm run dist -- --mac || npx electron-builder --mac
            ;;
        linux)
            npm run dist -- --linux || npx electron-builder --linux
            ;;
        all)
            npm run dist || npx electron-builder
            ;;
    esac
}

build_node_cli() {
    local platform=$1
    echo -e "\n${BLUE}📦 Node.js CLIツールをビルド中...${NC}"
    
    npm install
    npm run build 2>/dev/null || echo "No build script found"
    
    # pkgでバイナリ化
    if ! npm list pkg &> /dev/null; then
        npm install --save-dev pkg
    fi
    
    mkdir -p dist
    
    case "$platform" in
        windows|win)
            npx pkg . -t node18-win-x64 -o "dist/${PROJECT_NAME}.exe"
            ;;
        mac|darwin)
            npx pkg . -t node18-macos-x64 -o "dist/${PROJECT_NAME}-mac"
            ;;
        linux)
            npx pkg . -t node18-linux-x64 -o "dist/${PROJECT_NAME}-linux"
            ;;
        all)
            npx pkg . -t node18-win-x64,node18-macos-x64,node18-linux-x64 \
                -o "dist/${PROJECT_NAME}"
            ;;
    esac
}

build_python_app() {
    local platform=$1
    echo -e "\n${BLUE}🐍 Pythonアプリをビルド中...${NC}"
    
    # 仮想環境を作成
    python -m venv venv || python3 -m venv venv
    
    # 仮想環境を有効化
    if [ -f "venv/Scripts/activate" ]; then
        source venv/Scripts/activate
    else
        source venv/bin/activate
    fi
    
    pip install -r requirements.txt
    pip install pyinstaller
    
    # エントリーファイルを見つける
    ENTRY_FILE="${ENTRY_FILE:-$(find . -name "main.py" -o -name "app.py" | head -1)}"
    
    if [ -z "$ENTRY_FILE" ]; then
        echo -e "${RED}エラー: エントリーファイルが見つかりません${NC}"
        exit 1
    fi
    
    mkdir -p dist
    
    case "$platform" in
        windows|win)
            pyinstaller --onefile --name "${PROJECT_NAME}.exe" "$ENTRY_FILE"
            ;;
        mac|darwin|linux|all)
            pyinstaller --onefile --name "${PROJECT_NAME}" "$ENTRY_FILE"
            ;;
    esac
    
    # distディレクトリに移動
    mv dist/* dist/ 2>/dev/null || true
}

build_go_app() {
    local platform=$1
    echo -e "\n${BLUE}🔵 Goアプリをビルド中...${NC}"
    
    # 依存関係をダウンロード
    go mod download
    
    mkdir -p dist
    
    case "$platform" in
        windows|win)
            GOOS=windows GOARCH=amd64 go build -o "dist/${PROJECT_NAME}.exe"
            ;;
        mac|darwin)
            GOOS=darwin GOARCH=amd64 go build -o "dist/${PROJECT_NAME}-mac"
            ;;
        linux)
            GOOS=linux GOARCH=amd64 go build -o "dist/${PROJECT_NAME}-linux"
            ;;
        all)
            GOOS=windows GOARCH=amd64 go build -o "dist/${PROJECT_NAME}.exe"
            GOOS=darwin GOARCH=amd64 go build -o "dist/${PROJECT_NAME}-mac"
            GOOS=linux GOARCH=amd64 go build -o "dist/${PROJECT_NAME}-linux"
            ;;
    esac
}

build_web_app() {
    echo -e "\n${BLUE}🌐 Webアプリをビルド中...${NC}"
    
    if [ "$PROJECT_TYPE" = "nextjs-web" ] || [ "$PROJECT_TYPE" = "react-spa" ]; then
        npm install
        npm run build
        echo -e "${GREEN}✅ ビルド完了。デプロイは別途行ってください。${NC}"
    elif [ "$PROJECT_TYPE" = "python-web" ]; then
        echo -e "${YELLOW}Pythonウェブアプリはビルド不要です。${NC}"
        echo -e "デプロイ時にコンテナ化されます。"
    fi
}

# メインのビルド処理
case "$PROJECT_TYPE" in
    electron-app)
        build_electron "$PLATFORM"
        ;;
    node-cli)
        build_node_cli "$PLATFORM"
        ;;
    python-app)
        build_python_app "$PLATFORM"
        ;;
    go-app)
        build_go_app "$PLATFORM"
        ;;
    nextjs-web|react-spa|python-web)
        build_web_app
        ;;
    *)
        echo -e "${RED}エラー: 未対応のプロジェクトタイプです: $PROJECT_TYPE${NC}"
        exit 1
        ;;
esac

# ビルド結果を表示
echo -e "\n${GREEN}✅ ビルドが完了しました！${NC}"

if [ -d "dist" ]; then
    echo -e "\n${BLUE}📦 ビルド成果物:${NC}"
    ls -la dist/ 2>/dev/null || true
fi

# 元のブランチに戻る
git checkout - > /dev/null 2>&1

echo -e "\n${GREEN}完了しました！${NC}"