# build-project.ps1 - プロジェクトを自動的にビルドするPowerShellスクリプト
#
# 使用方法:
#   .\scripts\build-project.ps1 <project-name> [platform]
#
# 例:
#   .\scripts\build-project.ps1 pdf-compressor
#   .\scripts\build-project.ps1 pdf-compressor windows

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ProjectName,
    
    [Parameter(Position=1)]
    [string]$Platform = "windows"
)

# カラー設定
function Write-ColorOutput($ForegroundColor, $Message) {
    $previousColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Host $Message
    $Host.UI.RawUI.ForegroundColor = $previousColor
}

Write-ColorOutput Blue "🔨 プロジェクトのビルドを開始します..."
Write-Host "プロジェクト: " -NoNewline
Write-ColorOutput Yellow $ProjectName

# プロジェクトブランチをチェックアウト
Write-Host ""
Write-ColorOutput Blue "📥 プロジェクトをチェックアウト中..."
try {
    git checkout "project/$ProjectName" 2>&1 | Out-Null
} catch {
    Write-ColorOutput Red "エラー: プロジェクトブランチが見つかりません"
    exit 1
}

# プロジェクトタイプを検出
Write-Host ""
Write-ColorOutput Blue "🔍 プロジェクトタイプを検出中..."

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$detectOutput = & "$scriptDir\detect-project-type.ps1" "."

# 出力を解析
$projectType = ""
$projectDir = ""

# 空行や余分な文字を除去してから解析
$detectOutput -split "`r?`n" | ForEach-Object {
    $line = $_.Trim()
    if ($line -match "^PROJECT_TYPE=(.+)$") {
        $projectType = $Matches[1]
    } elseif ($line -match "^PROJECT_DIR=(.+)$") {
        $projectDir = $Matches[1]
    }
}

# PROJECT_DIRが設定されていない場合のデフォルト処理
if ([string]::IsNullOrEmpty($projectDir)) {
    $projectDir = "."
}

Write-Host "タイプ: " -NoNewline
Write-ColorOutput Yellow $projectType
Write-Host "ディレクトリ: " -NoNewline
Write-ColorOutput Yellow $projectDir

Set-Location $projectDir

# ビルド関数
function Build-ElectronApp {
    param($Platform)
    
    Write-Host ""
    Write-ColorOutput Blue "🖥️  Electronアプリをビルド中 ($Platform)..."
    
    npm install
    
    # ソースコードをビルド
    Write-ColorOutput Blue "📦 ソースコードをビルド中..."
    try {
        npm run build
    } catch {
        Write-ColorOutput Yellow "警告: ビルドスクリプトが見つかりません"
        Write-ColorOutput Yellow "distディレクトリが既に存在することを期待します"
    }
    
    # distディレクトリの存在確認
    if (-not (Test-Path "dist\main.js")) {
        Write-ColorOutput Red "エラー: dist\main.js が見つかりません"
        Write-ColorOutput Yellow "ヒント: ソースコードのビルドが必要です"
        exit 1
    }
    
    # Windowsの場合はelectron-builderを直接実行
    Write-Host ""
    Write-ColorOutput Blue "📦 実行可能ファイルを作成中..."
    npm run dist -- --win
}

function Build-NodeCLI {
    param($Platform)
    
    Write-Host ""
    Write-ColorOutput Blue "📦 Node.js CLIツールをビルド中..."
    
    npm install
    
    try {
        npm run build
    } catch {
        Write-Host "No build script found"
    }
    
    # pkgでバイナリ化
    if (-not (npm list pkg 2>$null)) {
        npm install --save-dev pkg
    }
    
    New-Item -ItemType Directory -Force -Path dist | Out-Null
    
    switch ($Platform) {
        "windows" { npx pkg . -t node18-win-x64 -o "dist\$ProjectName.exe" }
        "mac" { npx pkg . -t node18-macos-x64 -o "dist\$ProjectName-mac" }
        "linux" { npx pkg . -t node18-linux-x64 -o "dist\$ProjectName-linux" }
        default { npx pkg . -t node18-win-x64 -o "dist\$ProjectName.exe" }
    }
}

function Build-PythonApp {
    Write-Host ""
    Write-ColorOutput Blue "🐍 Pythonアプリをビルド中..."
    
    # 仮想環境を作成
    if (-not (Test-Path "venv")) {
        python -m venv venv
    }
    
    # 仮想環境を有効化
    & ".\venv\Scripts\Activate.ps1"
    
    pip install -r requirements.txt
    pip install pyinstaller
    
    # エントリーファイルを見つける
    $entryFile = Get-ChildItem -Filter "main.py" -ErrorAction SilentlyContinue
    if (-not $entryFile) {
        $entryFile = Get-ChildItem -Filter "app.py" -ErrorAction SilentlyContinue
    }
    
    if (-not $entryFile) {
        Write-ColorOutput Red "エラー: エントリーファイルが見つかりません"
        exit 1
    }
    
    New-Item -ItemType Directory -Force -Path dist | Out-Null
    pyinstaller --onefile --name "$ProjectName.exe" $entryFile.Name
}

# メインのビルド処理
switch -Wildcard ($projectType) {
    "*electron*" {
        Build-ElectronApp -Platform $Platform
    }
    "*node-cli*" {
        Build-NodeCLI -Platform $Platform
    }
    "*python*" {
        Build-PythonApp
    }
    default {
        Write-ColorOutput Red "エラー: 未対応のプロジェクトタイプです: $projectType"
        exit 1
    }
}

# ビルド結果を表示
Write-Host ""
Write-ColorOutput Green "✅ ビルドが完了しました！"

if (Test-Path "dist") {
    Write-Host ""
    Write-ColorOutput Blue "📦 ビルド成果物:"
    Get-ChildItem dist
}

if (Test-Path "release") {
    Write-Host ""
    Write-ColorOutput Blue "📦 リリース成果物:"
    Get-ChildItem release
}

# 元のブランチに戻る
Set-Location $PSScriptRoot\..
git checkout - 2>&1 | Out-Null

Write-Host ""
Write-ColorOutput Green "完了しました！"