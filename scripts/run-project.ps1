# run-project.ps1 - プロジェクトを簡単に実行するPowerShellスクリプト
#
# 使用方法:
#   .\scripts\run-project.ps1 <project-name>
#
# 例:
#   .\scripts\run-project.ps1 pdf-compressor

param(
    [Parameter(Position=0)]
    [string]$ProjectName
)

# カラー設定
$Host.UI.RawUI.ForegroundColor = "White"

function Write-ColorOutput($ForegroundColor, $Message) {
    $previousColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Host $Message
    $Host.UI.RawUI.ForegroundColor = $previousColor
}

# 引数チェック
if (-not $ProjectName) {
    Write-ColorOutput Red "エラー: プロジェクト名を指定してください"
    Write-Host "使用方法: .\$($MyInvocation.MyCommand.Name) <project-name>"
    Write-Host ""
    Write-Host "利用可能なプロジェクト:"
    
    # リモートブランチ情報を更新
    git fetch --all --quiet 2>$null
    $branches = git branch -r | Select-String "origin/project/" | Where-Object { $_ -notmatch "phase" }
    $branches | ForEach-Object {
        $project = $_ -replace '.*origin/project/', ''
        Write-Host "  - $project"
    }
    exit 1
}

Write-ColorOutput Blue "🚀 プロジェクトを起動します..."
Write-Host "プロジェクト: " -NoNewline
Write-ColorOutput Yellow $ProjectName

# 現在のブランチを保存
$currentBranch = git branch --show-current

# プロジェクトブランチをチェックアウト
Write-Host ""
Write-ColorOutput Blue "📥 プロジェクトをチェックアウト中..."
try {
    git checkout "project/$ProjectName" 2>&1 | Out-Null
} catch {
    Write-ColorOutput Red "エラー: プロジェクトブランチが見つかりません"
    Write-ColorOutput Yellow "ヒント: 利用可能なプロジェクトを確認するには、引数なしで実行してください"
    exit 1
}

# プロジェクトタイプを検出
Write-Host ""
Write-ColorOutput Blue "🔍 プロジェクトタイプを検出中..."

# detect-project-type.ps1を実行
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$detectOutput = & "$scriptDir\detect-project-type.ps1" "."

# 出力を解析
$projectType = ""
$projectDir = ""
$entryFile = ""

$detectOutput -split "`n" | ForEach-Object {
    if ($_ -match "^PROJECT_TYPE=(.+)$") {
        $projectType = $Matches[1]
    } elseif ($_ -match "^PROJECT_DIR=(.+)$") {
        $projectDir = $Matches[1]
    } elseif ($_ -match "^ENTRY_FILE=(.+)$") {
        $entryFile = $Matches[1]
    }
}

Write-Host "タイプ: " -NoNewline
Write-ColorOutput Yellow $projectType
Write-Host "ディレクトリ: " -NoNewline
Write-ColorOutput Yellow $projectDir

Set-Location $projectDir

# クリーンアップ関数
function Cleanup {
    Write-Host ""
    Write-ColorOutput Blue "🧹 クリーンアップ中..."
    Set-Location $PSScriptRoot\..
    git checkout $currentBranch 2>&1 | Out-Null
    Write-ColorOutput Green "元のブランチに戻りました"
}

# 終了時にクリーンアップを実行
trap { Cleanup }

# プロジェクトタイプに応じて実行
Write-Host ""
Write-ColorOutput Blue "🏃 プロジェクトを実行中..."

switch -Wildcard ($projectType) {
    "*electron*" {
        Write-Host ""
        Write-ColorOutput Blue "📦 依存関係をインストール中..."
        npm install
        
        Write-Host ""
        Write-ColorOutput Green "▶️  アプリケーションを起動中..."
        npm start
    }
    
    "*node*" {
        Write-Host ""
        Write-ColorOutput Blue "📦 依存関係をインストール中..."
        npm install
        
        Write-Host ""
        Write-ColorOutput Green "▶️  アプリケーションを起動中..."
        if (Select-String -Path "package.json" -Pattern '"start"') {
            npm start
        } elseif (Select-String -Path "package.json" -Pattern '"dev"') {
            npm run dev
        } elseif (Test-Path $entryFile) {
            node $entryFile
        } else {
            Write-ColorOutput Red "エラー: 起動スクリプトが見つかりません"
            Write-ColorOutput Yellow "package.jsonにstartスクリプトを追加してください"
            Cleanup
            exit 1
        }
    }
    
    "*python*" {
        Write-Host ""
        Write-ColorOutput Blue "🐍 Python環境をセットアップ中..."
        
        # 仮想環境を作成（既存の場合はスキップ）
        if (-not (Test-Path "venv")) {
            python -m venv venv
        }
        
        # 仮想環境を有効化
        & ".\venv\Scripts\Activate.ps1"
        
        Write-Host ""
        Write-ColorOutput Blue "📦 依存関係をインストール中..."
        pip install -r requirements.txt
        
        Write-Host ""
        Write-ColorOutput Green "▶️  アプリケーションを起動中..."
        python $entryFile
    }
    
    "*go*" {
        Write-Host ""
        Write-ColorOutput Blue "🔵 Go依存関係をダウンロード中..."
        go mod download
        
        Write-Host ""
        Write-ColorOutput Green "▶️  アプリケーションを起動中..."
        go run .
    }
    
    default {
        Write-ColorOutput Red "エラー: 未対応のプロジェクトタイプです: $projectType"
        Cleanup
        exit 1
    }
}

# 正常終了時もクリーンアップ
Cleanup