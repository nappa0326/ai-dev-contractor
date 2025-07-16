# CLAUDE.md - AI開発請負システム ガイドライン

## 🚨 最重要：ブランチ管理による連続性の保証

### 絶対的ルール
**各Issue/PRに対して単一のブランチのみを使用し、フェーズ間の連続性を必ず保証すること**

### 開発フェーズ記録

#### 現在進行中のプロジェクト
<!-- ここに各プロジェクトの進行状況を記録 -->

#### Issue別ブランチマッピング
<!-- 
例：
- Issue #46: project/meishi-generator/claude/issue-46-initial
- Issue #47: project/pdf-compressor/claude/issue-47-initial
- Issue #48: project/pdf-compressor/claude/issue-48-drag-drop
-->

### ブランチ管理手順（毎回必ず実行）

```bash
# 1. 作業開始時、必ず既存ブランチを確認
git fetch --all
git branch -a | grep -E "project/.*/claude/issue-{現在のissue番号}"

# 2. Phase 1の場合（新規プロジェクト）
# → プロジェクトブランチ戦略のセクションを参照

# 3. Phase 2以降の場合（継続開発）
git checkout {既存作業ブランチ名}
git pull origin {既存作業ブランチ名}

# 4. 前のフェーズの実装を確認
git log --oneline -10  # コミット履歴を確認
ls -la  # ファイル構造を確認
# 主要ファイルの内容を読み込んで理解する
```

## プロジェクトブランチ戦略

### ブランチ構造
- `master`: システム設定・ワークフローのみ（プロジェクトコードは含まない）
- `project/{project-name}`: 案件専用メインブランチ（永続的）
- `project/{project-name}/claude/issue-{number}-initial`: 初期開発の作業ブランチ
- `project/{project-name}/claude/issue-{number}-{feature}`: 継続開発の作業ブランチ

### 新規プロジェクト開発フロー

#### Phase 1開始時の手順
```bash
# 1. プロジェクトメインブランチを作成
git checkout master
git checkout -b project/{project-name}

# 2. プロジェクトディレクトリを作成
mkdir {project-name}
cd {project-name}
echo "# {プロジェクト名}" > README.md

# 3. プロジェクトメタデータを作成
cat > .project.yml << EOF
project_id: {project-name}
project_name: {日本語プロジェクト名}
initial_issue: {issue-number}
created_at: $(date -I)
status: active
maintainer: "@{github-username}"
EOF

# 4. 初期コミットとプッシュ
git add .
git commit -m "chore: Initialize project/{project-name} branch"
git push -u origin project/{project-name}

# 5. 作業ブランチを作成
git checkout -b project/{project-name}/claude/issue-{number}-initial
```

#### 開発完了時（Phase 4後）
```bash
# プロジェクトメインブランチへPR作成
gh pr create --base project/{project-name} \
             --title "feat: Issue #{number} - [機能説明]" \
             --body "## 実装内容\n[実装内容の要約]\n\nCloses #{number}"
```

### 継続開発フロー

#### 機能追加・バグ修正の開始
```bash
# 1. プロジェクトメインブランチを最新化
git checkout project/{project-name}
git pull origin project/{project-name}

# 2. 新しい作業ブランチを作成
git checkout -b project/{project-name}/claude/issue-{number}-{feature/bugfix}

# 3. 既存コードを理解
cat .project.yml  # プロジェクト情報確認
git log --oneline -10  # 開発履歴確認
```

### Issue記法の拡張

```markdown
# 新規プロジェクト
@claude PDF圧縮デスクトップアプリを作成してください

# 継続開発（プロジェクト名指定）
@claude [project: pdf-compressor] ドラッグ&ドロップ機能を追加

# 継続開発（関連Issue指定）
@claude [extends: #44] WebSocket対応を追加
@claude [bugfix: #44] メモリリーク修正
```

## プロジェクトディレクトリの作成ルール

### 絶対的ルール
**Phase 1で必ずプロジェクト専用ディレクトリを作成すること**

### ディレクトリ命名規則
- プロジェクト名を英語のkebab-caseに変換
- 日本語プロジェクト名は適切な英語名に翻訳
- 例：
  - "PDF圧縮デスクトップアプリ" → `pdf-compressor/`
  - "画像OCR・ドキュメント変換Webサービス" → `ocr-document-service/`
  - "Markdown変換デスクトップアプリ" → `markdown-converter/`

### ディレクトリ作成手順
```bash
# Phase 1開始時に必ず実行
mkdir {project-name}
cd {project-name}
# README.mdを作成して初期コミット
echo "# {プロジェクト名}" > README.md
```

## 開発プロセス

### フェーズ型開発の厳守

新規プロジェクト開始時は、**必ず**以下のフェーズに従って開発を進めてください：

1. **Phase 1 (20%)**: 設計書・アーキテクチャドキュメントを作成
   - **プロジェクト専用ディレクトリを作成**
   - 技術選定の理由を明記
   - ディレクトリ構造の提案
   - ブランチ名: `project/{project-name}/claude/issue-{番号}-initial`を作成
   - **報告に必ずブランチ名を含める**
   - `@claude-review-needed`タグを必ず含める

2. **Phase 2 (50%)**: MVP（最小限の動作可能な実装）を作成
   - **Phase 1と同じブランチを使用**
   - Phase 1の設計に基づいて実装
   - 既存ファイルがあれば読み込んで理解
   - コア機能のみ実装
   - **報告例**: "Phase 2完了 (branch: project/pdf-compressor/claude/issue-24-initial)"
   - `@claude-review-needed`タグを必ず含める

3. **Phase 3 (80%)**: 完全実装
   - **Phase 1,2と同じブランチを使用**
   - Phase 2のコードを拡張（削除・置換しない）
   - すべての要求機能を実装
   - エラーハンドリング、テスト追加
   - **前のフェーズのファイルを必ず読み込む**
   - `@claude-review-needed`タグを必ず含める

4. **Phase 4 (100%)**: 品質向上とドキュメント整備
   - **Phase 1,2,3と同じブランチを使用**
   - コード品質の最終確認
   - ドキュメントの完成
   - パフォーマンス最適化
   - `@claude-review-needed`タグを必ず含める

### 連続性保証のチェックリスト

各フェーズ開始時に必ず確認：
- [ ] 既存ブランチの存在確認をしたか？
- [ ] 前のフェーズのコミットを確認したか？
- [ ] 前のフェーズのファイルを読み込んだか？
- [ ] 既存実装の上に追加実装する計画か？
- [ ] ブランチ名を報告に含めたか？

### 🚨 各フェーズ完了時の必須作業

**絶対に忘れてはいけない手順**：
```bash
# 1. すべての変更をステージング
git add -A

# 2. フェーズ完了をコミット
git commit -m "feat: Phase X implementation for Issue #XX"

# 3. リモートにプッシュ（これが最重要！）
git push origin {現在のブランチ名}
```

**なぜプッシュが必須なのか**：
- プッシュしないと、次回実行時に既存ブランチが見つからない
- 結果として新しいブランチが作成され、連続性が失われる
- 作業内容が失われ、フェーズの継続ができなくなる

### 禁止事項

- ❌ フェーズごとに新しいブランチを作成すること
- ❌ 前のフェーズの実装を無視すること
- ❌ 既存ファイルを削除してゼロから作り直すこと
- ❌ git履歴を確認せずに作業を開始すること

### エラー時の対処

- ブランチが見つからない場合は、ユーザーに確認を求める
- 勝手に新しいブランチを作成しない
- エラーメッセージを明確に報告し、次のアクションを提案する

### プロジェクト完了報告

すべてのフェーズが完了し、以下の条件を満たしたらプロジェクト完了です：
- すべての機能が実装済み
- テストがパス
- ドキュメントが整備済み
- コードレビュー準備完了

完了時は、以下を実行：
1. すべての変更をコミット・プッシュ
2. プルリクエストを作成：
   ```bash
   # プロジェクトブランチへのPR作成
   gh pr create --base project/{project-name} \
                --title "feat: Issue #XX - [機能説明]" \
                --body "## 実装内容\n[実装内容の要約]\n\nCloses #XX"
   ```
3. Phase 4の通常報告の後、以下の形式でプロジェクト完了を報告：
   ```
   #### Final Status:
   🎉 **PROJECT COMPLETED** - [プロジェクト名] is production-ready
   **Pull Request Created**: [#PR番号](PRのURL)
   ```

### コミュニケーション

- 各フェーズの成果物を明確に説明する
- 次のフェーズで何を実装するか予告する
- 技術的な選択の理由を説明する