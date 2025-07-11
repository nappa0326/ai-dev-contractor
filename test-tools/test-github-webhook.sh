#!/bin/bash

# GitHub PR監視システムのテスト
# 使用方法: ./test-github-webhook.sh <PR番号>

PR_NUMBER=${1:-42}

curl -X POST https://n8n.oppy-ai.com/webhook-test/github-pr-comments \
  -H "Content-Type: application/json" \
  -d '{
    "action": "created",
    "issue": {
      "number": "'$PR_NUMBER'"
    },
    "comment": {
      "body": "Phase 2 が完了しました。レビューをお願いします。\n\n@claude-review-needed",
      "html_url": "https://github.com/nappa0326/ai-development-company/pull/'$PR_NUMBER'#issuecomment-test"
    }
  }'

echo "テストWebhook送信完了。Slackを確認してください。"