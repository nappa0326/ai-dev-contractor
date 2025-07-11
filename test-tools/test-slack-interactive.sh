#!/bin/bash

# Slack開発制御システムの直接テスト
# 使用方法: ./test-slack-interactive.sh <action> <pr_number>
# action: continue または revise

ACTION=${1:-continue}
PR_NUMBER=${2:-42}

# Slackのインタラクティブペイロードを模擬
PAYLOAD='{
  "type": "block_actions",
  "user": {
    "id": "U12345678",
    "name": "test_user"
  },
  "channel": {
    "id": "C094LNGF8H5"
  },
  "message": {
    "ts": "1234567890.123456"
  },
  "actions": [{
    "value": "'$ACTION'_'$PR_NUMBER'"
  }],
  "response_url": "https://hooks.slack.com/actions/test/test/test",
  "team": {
    "id": "T12345678"
  }
}'

# URLエンコード
ENCODED_PAYLOAD=$(echo -n "$PAYLOAD" | jq -sRr @uri)

# Webhookに送信
curl -X POST https://n8n.oppy-ai.com/webhook-test/slack-interactive \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "payload=$ENCODED_PAYLOAD"

echo -e "\n\nテスト送信完了："
echo "- アクション: $ACTION"
echo "- PR番号: $PR_NUMBER"
echo "n8nの実行履歴を確認してください。"