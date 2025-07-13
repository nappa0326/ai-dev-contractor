# ブランチ継続性検証レポート

## 実装された対策の総括

### 1. GitHub Actions (.github/workflows/claude.yml)

#### 強化ポイント:
- **事前ブランチ検出**: Actionの実行前に既存ブランチを検出してチェックアウト
- **環境変数の活用**: `CLAUDE_EXISTING_BRANCH`で現在のブランチをClaude Codeに伝達
- **direct_prompt**: 明確なブランチ継続指示
- **custom_instructions**: 詳細なブランチ管理ルール

#### 実装内容:
```yaml
# 新規追加: Setup branch tracking
- name: Setup branch tracking
  run: |
    git fetch --all --prune
    ISSUE_NUMBER="${{ github.event.issue.number }}"
    EXISTING_BRANCH=$(git branch -a | grep -E "remotes/origin/.*issue-${ISSUE_NUMBER}" | head -1 | sed 's/remotes\/origin\///')
    
    if [ -n "$EXISTING_BRANCH" ]; then
      echo "Found existing branch: $EXISTING_BRANCH"
      git checkout -b "$EXISTING_BRANCH" "origin/$EXISTING_BRANCH" || git checkout "$EXISTING_BRANCH"
      echo "CLAUDE_EXISTING_BRANCH=$EXISTING_BRANCH" >> $GITHUB_ENV
    fi
```

### 2. Slack開発制御システム（ブランチ指示版）

#### 強化ポイント:
- **ブランチ名抽出の改善**: 正規表現でドット(.)も含むブランチ名に対応
- **具体的なコマンド提供**: `@claude continue`メッセージに実行すべきgitコマンドを明記
- **視覚的な強調**: ❌と✅でやるべきこと・やってはいけないことを明確化

#### 実装内容:
```javascript
// 改善された正規表現
const branchMatch = comment.match(/branch:\s*([\w\/-._]+)/i);

// 強化されたメッセージ
'**開始前の必須手順:**\n' +
'```bash\n' +
'# 1. リモートの最新情報を取得\n' +
'git fetch --all\n\n' +
'# 2. 既存ブランチの確認\n' +
'git branch -a | grep "' + $json.branchName + '"\n\n' +
'# 3. ブランチに切り替え\n' +
'git checkout ' + $json.branchName + '\n\n' +
'# 4. 前のフェーズのコミット履歴を確認\n' +
'git log --oneline -10\n\n' +
'# 5. 前のフェーズで作成・編集したファイルを確認\n' +
'git diff --name-only HEAD~5..HEAD\n' +
'```'
```

### 3. プロジェクトドキュメント

#### 実装ファイル:
- `/mnt/c/usr/projects/ai-development-company/CLAUDE.md`: フェーズ型開発ルール
- `/mnt/c/usr/projects/ai-development-company/.github/claude-code-rules.md`: ブランチ管理専用ルール

## 残存リスクと追加対策案

### リスク1: Claude Code Actionの内部動作
Claude Code Action自体が新しいブランチを作成する可能性がある場合、外部からの制御には限界があります。

**追加対策案**:
```yaml
# .github/workflows/claude.yml に追加
- name: Post-execution branch check
  if: always()
  run: |
    CURRENT_BRANCH=$(git branch --show-current)
    if [[ ! "$CURRENT_BRANCH" =~ issue-${{ github.event.issue.number }} ]]; then
      echo "::error::Claude created a new branch: $CURRENT_BRANCH"
      exit 1
    fi
```

### リスク2: allowed_toolsの制限
現在はgit操作を全て許可していますが、`git checkout -b`を制限することも検討できます。

**追加対策案**:
```yaml
allowed_tools: >-
  Bash(git:add|commit|status|log|diff|fetch|pull|push|branch|checkout|merge|rebase)
  # git checkout -b を明示的に除外
```

### リスク3: フェーズ間の状態管理
キャッシュが失われた場合、Claudeが前のフェーズの作業を認識できない可能性があります。

**追加対策案**:
- プロジェクトルートに`.claude-state.json`ファイルを作成
- 各フェーズ完了時に状態を記録
- Claude Codeが最初に読み込むファイルとして指定

## 検証結果

### ✅ 実装済みの対策
1. **多層防御**: GitHub Actions、n8nワークフロー、ドキュメントで重層的に指示
2. **明示的な指示**: 具体的なgitコマンドを提供
3. **状態の永続化**: キャッシュとブランチ情報の保存
4. **エラーの可視化**: ブランチ違反時の通知システム

### ⚠️ 考慮事項
1. Claude Code Actionの内部動作は完全には制御できない
2. ユーザーが`@claude continue`メッセージをカスタマイズした場合の対応
3. 複数のIssueで同時開発する場合の衝突管理

## 推奨事項

1. **現在の対策をテスト**: 次回の開発案件で効果を確認
2. **ログの監視**: GitHub Actionsのログを確認してClaude Codeの動作を把握
3. **段階的な強化**: 問題が続く場合は、上記の追加対策を順次実装

## まとめ

現在実装されている対策は、Claude Codeに対して可能な限り明確にブランチ継続の指示を与えています。特に：

- GitHub Actionsでの事前ブランチ設定
- Slackからの具体的なgitコマンド指示
- 複数の場所での重複した指示

これらの対策により、Claude Codeが新しいブランチを作成する可能性は大幅に減少すると考えられます。