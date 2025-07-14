# claude.ymlとCLAUDE.mdの矛盾・不整合箇所

## 1. Phase 4完了マーカー
**問題**: CLAUDE.mdに【PHASE4_COMPLETE】マーカーの記載がない
- claude.yml: ✅ 記載あり
- CLAUDE.md: ❌ 記載なし

## 2. git pullコマンド
**問題**: claude.ymlにgit pullの指示がない
- claude.yml: ❌ 記載なし
- CLAUDE.md: ✅ `git pull origin {既存ブランチ名}`

## 3. エラー時の対処
**問題**: CLAUDE.mdにエラー時の対処法が記載されていない
- claude.yml: ✅ 「ブランチが見つからない場合は、ユーザーに確認を求める」
- CLAUDE.md: ❌ 記載なし

## 4. 表記の不一致
**問題**: 変数名の表記が統一されていない
- claude.yml: `issue_number`（英語）
- CLAUDE.md: `issue番号`（日本語）

## 5. コミットメッセージの表記
**問題**: フェーズ番号の表記が異なる
- claude.yml: `Phase X`
- CLAUDE.md: `Phase {フェーズ番号}`

## 6. 重複している内容
- ブランチ管理ルール（両方に同じ内容）
- フェーズ型開発プロセス（両方に同じ内容）
- コミット・プッシュの手順（両方に同じ内容）

## 推奨される修正（実施済み）

### ✅ 実施した修正内容

1. **CLAUDE.mdへの追加**:
   - ✅ Phase 4完了マーカー【PHASE4_COMPLETE】の記載を追加
   - ✅ エラー時の対処法セクションを追加

2. **claude.ymlへの追加**:
   - ✅ git pullコマンドの指示を追加（2箇所）
   - ✅ Phase 4でのマーカー記載要件を追加

3. **表記の統一**:
   - ✅ コミットメッセージ形式を統一: `feat: Phase X implementation for Issue #XX`
   - ✅ レビュータグの記載例を明確化

4. **重複の解消**:
   - 詳細な手順はCLAUDE.mdに集約されている状態を維持
   - claude.ymlは実行時の具体的な指示に特化

### 修正の詳細

#### CLAUDE.md
- Phase 4の項目に【PHASE4_COMPLETE】マーカーの必須記載を追加
- 「エラー時の対処」セクションを新規追加
- コミットメッセージの表記を統一（変数名を具体例に変更）

#### claude.yml  
- Decision logicセクションにgit pullコマンドを追加
- custom_instructionsセクションにもgit pullを追加
- Phase 4の説明に【PHASE4_COMPLETE】マーカーの必須記載を追加
- レビュータグの記載例を更新
- コミットメッセージの表記を統一（${{ github.event.issue.number }}を使用）