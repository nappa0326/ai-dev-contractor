#!/bin/bash

# detect-project-type.sh - プロジェクトタイプを検出するスクリプト
#
# 使用方法:
#   ./detect-project-type.sh [プロジェクトディレクトリ]
#
# 出力:
#   PROJECT_TYPE: プロジェクトタイプ
#   PROJECT_DIR: プロジェクトディレクトリ
#   BUILD_COMMAND: ビルドコマンド
#   ENTRY_FILE: エントリーファイル

set -e

# デフォルトは現在のディレクトリ
PROJECT_DIR="${1:-.}"

# プロジェクトディレクトリを探す関数
find_project_dir() {
    local dir="$1"
    
    # 指定されたディレクトリから開始
    if [ -f "$dir/package.json" ] || [ -f "$dir/requirements.txt" ] || [ -f "$dir/go.mod" ]; then
        echo "$dir"
        return 0
    fi
    
    # サブディレクトリを検索（node_modulesを除外）
    local found_dirs=$(find "$dir" -type f \( -name "package.json" -o -name "requirements.txt" -o -name "go.mod" \) -not -path "*/node_modules/*" 2>/dev/null | xargs -I {} dirname {} | sort -u)
    
    if [ -n "$found_dirs" ]; then
        # プロジェクト名と同じディレクトリを優先
        local project_name=$(basename $(pwd))
        for found_dir in $found_dirs; do
            if [[ "$found_dir" == *"/$project_name" ]] || [[ "$found_dir" == "./$project_name" ]]; then
                echo "$found_dir"
                return 0
            fi
        done
        # 見つからない場合は最初のものを使用
        echo "$found_dirs" | head -1
        return 0
    fi
    
    return 1
}

# メインの検出ロジック
detect_project_type() {
    local dir="$1"
    cd "$dir"
    
    # Node.js/JavaScript系
    if [ -f "package.json" ]; then
        local pkg_content=$(cat package.json)
        
        # Electron
        if echo "$pkg_content" | grep -q '"electron"'; then
            echo "PROJECT_TYPE=electron-app"
            echo "BUILD_COMMAND='npm run electron:build'"
            echo "PLATFORMS=win,mac,linux"
            return 0
        fi
        
        # Next.js
        if echo "$pkg_content" | grep -q '"next"'; then
            echo "PROJECT_TYPE=nextjs-web"
            echo "BUILD_COMMAND='npm run build'"
            echo "DEPLOY_TYPE=vercel"
            return 0
        fi
        
        # React SPA
        if echo "$pkg_content" | grep -q '"react"' && [ -f "public/index.html" ]; then
            echo "PROJECT_TYPE=react-spa"
            echo "BUILD_COMMAND='npm run build'"
            echo "DEPLOY_TYPE=static"
            return 0
        fi
        
        # CLI Tool
        if echo "$pkg_content" | grep -q '"bin"' || [ -d "bin" ]; then
            echo "PROJECT_TYPE=node-cli"
            echo "BUILD_COMMAND='npm run build'"
            echo "ENTRY_FILE=$(echo "$pkg_content" | grep -o '"main"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 || echo "index.js")"
            return 0
        fi
        
        # Generic Node.js app
        echo "PROJECT_TYPE=node-app"
        echo "BUILD_COMMAND='npm run build'"
        echo "ENTRY_FILE=index.js"
        return 0
    fi
    
    # Python系
    if [ -f "requirements.txt" ]; then
        local req_content=$(cat requirements.txt)
        
        # Web frameworks
        if echo "$req_content" | grep -qE "flask|django|fastapi|streamlit"; then
            echo "PROJECT_TYPE=python-web"
            
            if echo "$req_content" | grep -q "streamlit"; then
                echo "ENTRY_FILE=$(find . -name "*.py" -exec grep -l "streamlit" {} \; | head -1 || echo "app.py")"
                echo "RUN_COMMAND=streamlit run"
            else
                echo "ENTRY_FILE=$(find . -name "app.py" -o -name "main.py" | head -1 || echo "app.py")"
                echo "RUN_COMMAND=python"
            fi
            
            echo "DEPLOY_TYPE=container"
            return 0
        fi
        
        # Desktop/CLI app
        echo "PROJECT_TYPE=python-app"
        echo "ENTRY_FILE=$(find . -name "main.py" -o -name "app.py" -o -name "__main__.py" | head -1 || echo "main.py")"
        echo "BUILD_COMMAND='pyinstaller --onefile'"
        return 0
    fi
    
    # Go系
    if [ -f "go.mod" ]; then
        echo "PROJECT_TYPE=go-app"
        echo "BUILD_COMMAND='go build'"
        echo "ENTRY_FILE=$(find . -name "main.go" | head -1 || echo "main.go")"
        return 0
    fi
    
    # 不明なタイプ
    echo "PROJECT_TYPE=unknown"
    return 1
}

# メイン処理
main() {
    # プロジェクトディレクトリを見つける
    PROJECT_DIR=$(find_project_dir "$PROJECT_DIR")
    
    if [ -z "$PROJECT_DIR" ]; then
        echo "Error: No project files found" >&2
        exit 1
    fi
    
    echo "PROJECT_DIR=$PROJECT_DIR"
    
    # プロジェクトタイプを検出
    if ! detect_project_type "$PROJECT_DIR"; then
        echo "Warning: Unknown project type" >&2
    fi
}

# スクリプトとして実行された場合のみmainを実行
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi