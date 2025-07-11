#!/bin/bash

# テスト用のIssueを作成
echo "テスト用Issueを作成しています..."

# GitHub CLIを使用
gh issue create \
  --title "テスト用Issue（削除可）" \
  --body "Slack開発制御システムのテスト用。テスト後削除してください。" \
  --label "test"

echo "作成されたIssue番号を使ってテストを実行してください。"