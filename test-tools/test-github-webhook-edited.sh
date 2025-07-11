#!/bin/bash

# GitHub PR監視システムのテスト（editedイベント）
# 使用方法: ./test-github-webhook-edited.sh <Issue番号>

ISSUE_NUMBER=${1:-18}

curl -X POST https://n8n.oppy-ai.com/webhook/github-pr-comments \
  -H "Content-Type: application/json" \
  -d '{
    "action": "edited",
    "issue": {
      "number": "'$ISSUE_NUMBER'"
    },
    "comment": {
      "body": "Phase 1 が完了しました。\n\n**@claude-review-needed**\n\nレビューをお願いします。",
      "html_url": "https://github.com/nappa0326/ai-development-company/issues/'$ISSUE_NUMBER'#issuecomment-test",
      "user": {
        "login": "claude[bot]"
      }
    }
  }'

echo "editedイベントのテストWebhook送信完了。"