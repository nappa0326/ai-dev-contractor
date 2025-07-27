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
- ❌ **発注内容を拡大解釈して追加機能を実装すること**
- ❌ **「ついでに」という理由で範囲外の改善を行うこと**

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
2. PRのbody（本文）に、**必ず最後に**以下の形式でプロジェクト完了を報告：
   ```
   #### Final Status:
   🎉 **PROJECT COMPLETED** - [プロジェクト名] is production-ready
   ```
3. Issueコメントでも同様にFinal Statusを含めた完了報告を行う
   
**重要**: 
- PR本文とIssueコメントの両方にFinal Statusセクションを含める
- Phase 4の`@claude-review-needed`タグの前に必ず含めること

### コミュニケーション

- 各フェーズの成果物を明確に説明する
- 次のフェーズで何を実装するか予告する
- 技術的な選択の理由を説明する

### 🎯 発注内容厳守の原則

**絶対的ルール**: 発注内容を拡大解釈せず、記載された問題のみを解決すること

#### 実装範囲の判断基準

**含める**:
- 発注文に明示的に記載された内容
- その問題を解決するために必須の最小限の変更
- 明示的に要求されたテストとドキュメント

**含めない**:
- 「ついでに」できる改善や最適化
- 「将来的に」役立つ機能追加
- 発見した他の問題の修正（報告のみ）
- 言及されていないエッジケースへの対応

#### 関連問題を発見した場合の対応

実装せずに、Final Statusセクションで「推奨される追加タスク」として報告：

```
#### Final Status:
🎉 **PROJECT COMPLETED** - [実装内容]

**推奨される追加タスク**:
- [発見した関連問題1]（別途タスクとして）
- [発見した関連問題2]（別途タスクとして）
```

## 🔧 開発の基本原則

### 必須確認事項（全プロジェクト共通）

1. **ビルドが通ること**
   - `npm run build` / `go build` / `pip install` などが成功すること
   - ビルドエラーは必ず解決してからPRを作成

2. **基本動作の確認**
   - アプリケーションが起動すること
   - 最低限の機能が動作すること
   - 明らかなランタイムエラーがないこと

3. **セキュリティの基本**
   - APIキーやパスワードをハードコードしない
   - 環境変数や設定ファイルを使用する

### よくある問題と対処法（参考）

経験上、以下の問題が発生しやすいです：

- **Electronアプリ**: レンダラープロセスで`require`使用 → preload.js経由にする
- **Reactアプリ**: useEffectの無限ループ → 依存配列を適切に設定
- **APIサーバー**: CORS未設定 → 適切なCORS設定を追加

ただし、これらは参考情報です。プロジェクトごとに適切に判断してください。

### 品質の考え方

- **Phase 2 (MVP)**: 動けばOK。完璧を求めない
- **Phase 3**: エラーハンドリングとテストを追加
- **Phase 4**: ドキュメント整備と最終調整

完璧なコードより、段階的に改善できるコードを目指してください。

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

#### フェーズ数の柔軟な運用

**標準フェーズ数**（目安）:
- 記載のフェーズ数は標準的なタスクを想定
- タスクの規模により、Phase 1で適切なフェーズ数を判断
- 標準を超える場合は、Phase 1完了時に理由とともに宣言

**フェーズ拡張が妥当な場合**:
- 影響ファイル数が10以上
- 複数モジュール間の連携が必要
- セキュリティ関連の慎重な対応が必要
- ただし、発注内容の範囲内に限る

#### fix（軽微な修正）- 1フェーズ
- **Phase 1 (100%)**: 修正と確認
**注意**: 軽微な修正のみ。スコープが大きい場合はbugfixまたはenhanceとして再発注を提案

#### bugfix（バグ修正）- 2フェーズ
- **Phase 1 (40%)**: 原因分析と修正計画
- **Phase 2 (100%)**: 修正実装とテスト
**注意**: 報告されたバグのみ修正。関連する問題は報告に留める

#### enhance（機能追加）- 3フェーズ
- **Phase 1 (30%)**: 設計と既存コードへの影響分析
- **Phase 2 (70%)**: 実装
- **Phase 3 (100%)**: 統合テストとドキュメント更新
**注意**: 要求された機能のみ実装。追加のアイデアは提案に留める

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
PR本文とIssueコメントの両方に：
```
#### Final Status:
🎉 **PROJECT COMPLETED** - [タスク説明]
```