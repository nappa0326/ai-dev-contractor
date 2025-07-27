# detect-project-type.ps1 - プロジェクトタイプを検出するPowerShellスクリプト
#
# 使用方法:
#   .\detect-project-type.ps1 [プロジェクトディレクトリ]
#
# 出力:
#   PROJECT_TYPE: プロジェクトタイプ
#   PROJECT_DIR: プロジェクトディレクトリ
#   BUILD_COMMAND: ビルドコマンド
#   ENTRY_FILE: エントリーファイル

param(
    [Parameter(Position=0)]
    [string]$ProjectDir = "."
)

# プロジェクトディレクトリを探す関数
function Find-ProjectDir {
    param($Dir)
    
    # 絶対パスに変換
    $Dir = Resolve-Path $Dir -ErrorAction SilentlyContinue
    if (-not $Dir) {
        $Dir = Get-Location
    }
    
    # 指定されたディレクトリから開始
    if ((Test-Path "$Dir\package.json") -or (Test-Path "$Dir\requirements.txt") -or (Test-Path "$Dir\go.mod")) {
        return $Dir.Path
    }
    
    # サブディレクトリを検索（node_modulesを除外）
    $foundDirs = Get-ChildItem -Path $Dir -Recurse -File -ErrorAction SilentlyContinue | 
        Where-Object { 
            ($_.Name -eq "package.json" -or $_.Name -eq "requirements.txt" -or $_.Name -eq "go.mod") -and 
            $_.DirectoryName -notmatch "node_modules"
        } | 
        Select-Object -ExpandProperty DirectoryName -Unique
    
    if ($foundDirs) {
        # 複数の結果がある場合
        if ($foundDirs -is [array]) {
            # プロジェクト名と同じディレクトリを優先
            $projectName = Split-Path (Get-Location) -Leaf
            foreach ($foundDir in $foundDirs) {
                if ($foundDir -match [regex]::Escape($projectName) + '$') {
                    return $foundDir
                }
            }
            # 見つからない場合は最初のものを使用
            return $foundDirs[0]
        } else {
            # 単一の結果の場合
            return $foundDirs
        }
    }
    
    return $null
}

# メインの検出ロジック
function Detect-ProjectType {
    param($Dir)
    
    # ディレクトリが存在することを確認
    if (-not (Test-Path $Dir)) {
        Write-Output "PROJECT_TYPE=unknown"
        return
    }
    
    Push-Location $Dir
    
    try {
        # Node.js/JavaScript系
        if (Test-Path "package.json") {
            $packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
            
            # Electron
            if ($packageJson.devDependencies.electron -or $packageJson.dependencies.electron) {
                Write-Output "PROJECT_TYPE=electron-app"
                Write-Output "BUILD_COMMAND='npm run electron:build'"
                Write-Output "PLATFORMS=win,mac,linux"
                return
            }
            
            # Next.js
            if ($packageJson.dependencies.next -or $packageJson.devDependencies.next) {
                Write-Output "PROJECT_TYPE=nextjs-web"
                Write-Output "BUILD_COMMAND='npm run build'"
                Write-Output "DEPLOY_TYPE=vercel"
                return
            }
            
            # React SPA
            if (($packageJson.dependencies.react -or $packageJson.devDependencies.react) -and (Test-Path "public\index.html")) {
                Write-Output "PROJECT_TYPE=react-spa"
                Write-Output "BUILD_COMMAND='npm run build'"
                Write-Output "DEPLOY_TYPE=static"
                return
            }
            
            # CLI Tool
            if ($packageJson.bin -or (Test-Path "bin")) {
                Write-Output "PROJECT_TYPE=node-cli"
                Write-Output "BUILD_COMMAND='npm run build'"
                $main = if ($packageJson.main) { $packageJson.main } else { "index.js" }
                Write-Output "ENTRY_FILE=$main"
                return
            }
            
            # Generic Node.js app
            Write-Output "PROJECT_TYPE=node-app"
            Write-Output "BUILD_COMMAND='npm run build'"
            Write-Output "ENTRY_FILE=index.js"
            return
        }
        
        # Python系
        if (Test-Path "requirements.txt") {
            $requirements = Get-Content "requirements.txt" -Raw
            
            # Web frameworks
            if ($requirements -match "flask|django|fastapi|streamlit") {
                Write-Output "PROJECT_TYPE=python-web"
                
                if ($requirements -match "streamlit") {
                    $entryFile = Get-ChildItem -Filter "*.py" | Where-Object { 
                        Select-String -Path $_.FullName -Pattern "streamlit" -Quiet 
                    } | Select-Object -First 1 -ExpandProperty Name
                    if (-not $entryFile) { $entryFile = "app.py" }
                    Write-Output "ENTRY_FILE=$entryFile"
                    Write-Output "RUN_COMMAND=streamlit run"
                } else {
                    $entryFile = @("app.py", "main.py") | Where-Object { Test-Path $_ } | Select-Object -First 1
                    if (-not $entryFile) { $entryFile = "app.py" }
                    Write-Output "ENTRY_FILE=$entryFile"
                    Write-Output "RUN_COMMAND=python"
                }
                
                Write-Output "DEPLOY_TYPE=container"
                return
            }
            
            # Desktop/CLI app
            Write-Output "PROJECT_TYPE=python-app"
            $entryFile = @("main.py", "app.py", "__main__.py") | Where-Object { Test-Path $_ } | Select-Object -First 1
            if (-not $entryFile) { $entryFile = "main.py" }
            Write-Output "ENTRY_FILE=$entryFile"
            Write-Output "BUILD_COMMAND='pyinstaller --onefile'"
            return
        }
        
        # Go系
        if (Test-Path "go.mod") {
            Write-Output "PROJECT_TYPE=go-app"
            Write-Output "BUILD_COMMAND='go build'"
            $entryFile = Get-ChildItem -Filter "main.go" | Select-Object -First 1 -ExpandProperty Name
            if (-not $entryFile) { $entryFile = "main.go" }
            Write-Output "ENTRY_FILE=$entryFile"
            return
        }
        
        # 不明なタイプ
        Write-Output "PROJECT_TYPE=unknown"
    }
    finally {
        Pop-Location
    }
}

# メイン処理
$foundDir = Find-ProjectDir $ProjectDir

if (-not $foundDir) {
    Write-Error "Error: No project files found"
    exit 1
}

Write-Output "PROJECT_DIR=$foundDir"

# プロジェクトタイプを検出
Detect-ProjectType $foundDir