# CLAUDE.md - 開発請負AI ガイドライン

## 🚨 最重要：フェーズ別ブランチ戦略

### 絶対的ルール
**各フェーズで独立したブランチとPull Requestを作成し、段階的なレビューと品質保証を実現すること**

### 開発フェーズ記録

#### 現在進行中のプロジェクト
<!-- ここに各プロジェクトの進行状況を記録 -->

#### Issue別ブランチマッピング
<!-- 
例：
- Issue #46: project/meishi-generator-46-phase1
- Issue #47: project/pdf-compressor-47-phase1
- Issue #48: project/pdf-compressor-48-phase1
-->

### ブランチ管理手順（フェーズ別）

```bash
# 1. 各フェーズ開始時、プロジェクトメインブランチを最新化
git checkout project/{project-name}
git pull origin project/{project-name}

# 2. フェーズ別作業ブランチを作成
# Phase 1: git checkout -b project/{project-name}-{issue-number}-phase1
# Phase 2: git checkout -b project/{project-name}-{issue-number}-phase2
# Phase 3: git checkout -b project/{project-name}-{issue-number}-phase3  
# Phase 4: git checkout -b project/{project-name}-{issue-number}-phase4

# 3. 前フェーズの成果物を確認（Phase 2以降）
git log --oneline -10  # マージ済みコミットを確認
ls -la  # ファイル構造を確認
# 設計書・既存実装を読み込んで理解する
```

## プロジェクトブランチ戦略

### ブランチ構造
- `master`: システム設定・ワークフローのみ（プロジェクトコードは含まない）
- `project/{project-name}`: 案件専用メインブランチ（永続的）
- `project/{project-name}-{issue-number}-phase{N}`: フェーズ別作業ブランチ（N=1-4）

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
git commit -m "chore: Initialize {project-name} branch"
git push -u origin project/{project-name}

# 5. Phase 1作業ブランチを作成
git checkout -b project/{project-name}-{issue-number}-phase1
```

#### 各フェーズ完了時のPR作成
```bash
# Phase 1完了時
gh pr create --base project/{project-name} \
             --title "Phase 1: {プロジェクト名}設計書 (#{number})" \
             --body "## Phase 1: 設計フェーズ\n\n### 作成ドキュメント\n- ARCHITECTURE.md\n- REQUIREMENTS.md\n\nRelated to #{number}"

# Phase 2-4も同様にPR作成（タイトルとフェーズ番号を変更）
```

### 継続開発フロー

#### 機能追加・バグ修正の開始
```bash
# 1. プロジェクトメインブランチを最新化
git checkout project/{project-name}
git pull origin project/{project-name}

# 2. 新しい作業ブランチを作成
git checkout -b project/{project-name}-{issue-number}-phase1

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
   - ブランチ名: `project/{project-name}-{issue-number}-phase1`を作成
   - PR作成: 設計書レビュー用のPRを作成
   - **報告に必ずブランチ名を含める**
   - `@claude-review-needed`タグを必ず含める

2. **Phase 2 (50%)**: MVP（最小限の動作可能な実装）を作成
   - **新しいPhase 2ブランチを作成**（Phase 1がマージ済みの前提）
   - Phase 1の設計に基づいて実装
   - 既存ファイルがあれば読み込んで理解
   - コア機能のみ実装
   - PR作成: MVP実装レビュー用のPRを作成
   - **報告例**: "Phase 2完了 | PR: #102 | Branch: project/pdf-compressor-24-phase2"
   - `@claude-review-needed`タグを必ず含める

3. **Phase 3 (80%)**: 完全実装
   - **新しいPhase 3ブランチを作成**（Phase 1,2がマージ済みの前提）
   - Phase 2のコードを拡張（削除・置換しない）
   - すべての要求機能を実装
   - エラーハンドリング、テスト追加
   - **前のフェーズのファイルを必ず読み込む**
   - PR作成: 完全実装レビュー用のPRを作成
   - `@claude-review-needed`タグを必ず含める

4. **Phase 4 (100%)**: 品質向上とドキュメント整備
   - **新しいPhase 4ブランチを作成**（Phase 1,2,3がマージ済みの前提）
   - コード品質の最終確認
   - ドキュメントの完成
   - パフォーマンス最適化
   - PR作成: 最終品質向上レビュー用のPRを作成
   - `@claude-review-needed`タグを必ず含める

### フェーズ間連続性のチェックリスト

各フェーズ開始時に必ず確認：
- [ ] プロジェクトメインブランチを最新化したか？
- [ ] 前フェーズのPRがマージされているか確認したか？
- [ ] 前フェーズの成果物（設計書・実装）を読み込んだか？
- [ ] 新しいフェーズブランチを作成したか？
- [ ] PR URLを報告に含める準備はできているか？

### 🚨 各フェーズ完了時の必須作業

**絶対に忘れてはいけない手順**：
```bash
# 1. すべての変更をステージング
git add -A

# 2. フェーズ完了をコミット
git commit -m "feat: Phase X implementation for Issue #XX"

# 3. リモートにプッシュ
git push origin {現在のブランチ名}

# 4. PRを作成（最重要！）
gh pr create --base project/{project-name} \
             --title "Phase X: {説明} (#{issue-number})" \
             --body "## Phase X完了\n\n[成果物の説明]\n\nRelated to #{issue-number}"
```

**なぜPR作成が必須なのか**：
- 各フェーズの成果物を段階的にレビュー
- 品質を確保しながら開発を進行
- 進捗の透明性を確保
- GitHub上で全体の開発履歴を追跡可能

### 禁止事項

- ❌ PR作成せずに次のフェーズに進むこと
- ❌ 前のフェーズの成果物を無視すること
- ❌ 既存ファイルを削除してゼロから作り直すこと
- ❌ プロジェクトメインブランチを最新化せずに作業を開始すること

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
1. Phase 4のPRを作成
2. Phase 4の報告内で、**必ず最後に**以下の形式でプロジェクト完了を報告：
   ```
   #### Final Status:
   🎉 **PROJECT COMPLETED** - [プロジェクト名] is production-ready
   **Pull Request Created**: [#PR番号](PRのURL)
   ```
   
**重要**: Phase 4の`@claude-review-needed`タグの前に、必ずこの「Final Status:」セクションを含めること

### コミュニケーション

- 各フェーズの成果物を明確に説明する
- 次のフェーズで何を実装するか予告する
- 技術的な選択の理由を説明する

## 継続開発フロー

### 概要
既存プロジェクトへの機能追加、バグ修正、リファクタリングなどの継続開発をサポートします。

### Issue記法の拡張

```markdown
# 軽微な修正（1フェーズ）
@claude [fix: #元Issue番号] タイポ修正、設定値変更など

# バグ修正（2フェーズ）
@claude [bugfix: #元Issue番号] エラーや不具合の修正

# 機能追加（3フェーズ）
@claude [enhance: #元Issue番号] 新機能追加や既存機能の拡張

# リファクタリング（3-4フェーズ）
@claude [refactor: #元Issue番号] コード構造の改善、技術的負債の解消

# 依存関係更新（2-3フェーズ）
@claude [update: #元Issue番号] ライブラリやフレームワークの更新

# セキュリティ対応（2-3フェーズ）
@claude [security: #元Issue番号] 脆弱性修正、セキュリティ強化

# ドキュメント整備（1-2フェーズ）
@claude [docs: #元Issue番号] README更新、APIドキュメント作成

# テスト追加（2フェーズ）
@claude [test: #元Issue番号] テストカバレッジ向上

# パフォーマンス改善（3フェーズ）
@claude [perf: #元Issue番号] 処理速度向上、最適化
```

### ブランチ戦略

継続開発では、プロジェクトメインブランチから新しい作業ブランチを作成します：

```
# 元のプロジェクトブランチ
project/{project-name}

# 継続開発用ブランチ（タスクタイプでもフェーズ別に作成）
project/{project-name}-{新Issue番号}-phase{フェーズ番号}
```

例：
- `project/pdf-compressor-67-phase1`
- `project/pdf-compressor-68-phase1`
- `project/pdf-compressor-69-phase2`

### タスクタイプ別フェーズ構成

#### fix（軽微な修正）- 1フェーズ
- **Phase 1 (100%)**: 修正と確認

#### bugfix（バグ修正）- 2フェーズ
- **Phase 1 (40%)**: 原因分析と修正計画
- **Phase 2 (100%)**: 修正実装とテスト

#### enhance（機能追加）- 3フェーズ
- **Phase 1 (30%)**: 設計と既存コードへの影響分析
- **Phase 2 (70%)**: 実装
- **Phase 3 (100%)**: 統合テストとドキュメント更新

#### refactor（リファクタリング）- 3-4フェーズ
- **Phase 1 (25%)**: 現状分析とリファクタリング計画
- **Phase 2 (50%)**: 基盤部分の変更
- **Phase 3 (75%)**: 機能部分の変更
- **Phase 4 (100%)**: 最終調整と検証（大規模な場合）

### 開発手順

1. **元プロジェクトの確認**
   ```bash
   # タグから元のIssue番号を特定
   # 元のプロジェクトディレクトリを確認
   cd {project-name}/
   ```

2. **作業ブランチの作成**
   ```bash
   # プロジェクトメインブランチから分岐
   git checkout project/{project-name}
   git pull origin project/{project-name}
   git checkout -b project/{project-name}-{新番号}-phase1
   ```

3. **既存コードの理解**
   - プロジェクトのREADMEを確認
   - 関連ファイルの構造を理解
   - 元のIssueとPRを参照

4. **タスクタイプに応じた開発**
   - 各フェーズで適切な作業を実施
   - `@claude-review-needed`タグで承認を求める

5. **各フェーズ完了時のPR作成**
   ```bash
   # 各フェーズでPRを作成（新規プロジェクトと同様）
   gh pr create --base project/{project-name} \
                --title "{タスクタイプ} Phase {N}: {説明} (#{issue-number})" \
                --body "## Phase {N}完了\n\n[変更内容]\n\nRelated to #元Issue番号"
   ```

### Issue作成時の必須事項

#### ラベルの設定
**新規プロジェクト**:
- `新規開発` ラベルを設定

**継続開発**:
- `継続開発` ラベルを設定
- タスクタイプに応じた追加ラベル:
  - [fix: #XX] → `軽微な修正`
  - [bugfix: #XX] → `バグ修正`
  - [enhance: #XX] → `機能追加`
  - [refactor: #XX] → `リファクタリング`
  - [update: #XX] → `依存関係更新`
  - [security: #XX] → `セキュリティ`
  - [docs: #XX] → `ドキュメント`
  - [test: #XX] → `テスト`
  - [perf: #XX] → `パフォーマンス`

#### 完了報告の形式
**新規プロジェクト完了時（Phase 4）**:
```
#### Final Status:
🎉 **PROJECT COMPLETED** - [プロジェクト名] is production-ready
**All PRs Merged**: Phase 1-4の全PRがマージ完了
```

**継続開発の各タスクタイプ最終フェーズ完了時**:
```
#### Final Status:
🎉 **PROJECT COMPLETED** - [タスク説明] 
**Pull Request Created**: [#PR番号](PRのURL)
```