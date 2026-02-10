#!/usr/bin/env bash
# Evolink Z-Image-Turbo generation script
# Usage: Called by Claude with placeholders replaced

API_KEY="{{API_KEY}}"
OUT_FILE="{{OUTPUT_FILE}}"

# Submit — heredoc passes JSON via stdin, no temp files needed
RESP=$(curl -s -X POST "https://api.evolink.ai/v1/images/generations" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d @- <<'EVOLINK_END'
{
  "model": "z-image-turbo",
  "prompt": "{{USER_PROMPT}}",
  "size": "{{SIZE}}",
  "nsfw_check": {{NSFW_CHECK}}
}
EVOLINK_END
)
TASK_ID=$(echo "$RESP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "Task submitted: $TASK_ID"

if [ -z "$TASK_ID" ]; then
  echo "Error: Failed to submit task. Response: $RESP"
  exit 1
fi

# Poll
MAX_RETRIES=200
for i in $(seq 1 $MAX_RETRIES); do
  sleep 10
  TASK=$(curl -s "https://api.evolink.ai/v1/tasks/$TASK_ID" \
    -H "Authorization: Bearer $API_KEY")
  STATUS=$(echo "$TASK" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
  echo "[$i] Status: $STATUS"

  if [ "$STATUS" = "completed" ]; then
    URL=$(echo "$TASK" | grep -o '"results":\["[^"]*"\]' | grep -o 'https://[^"]*')
    echo "Image URL: $URL"
    curl -s -o "$OUT_FILE" "$URL"
    echo "Downloaded to: $OUT_FILE"
    break
  fi
  if [ "$STATUS" = "failed" ]; then
    echo "Generation failed: $TASK"
    break
  fi
done
if [ "$i" -eq "$MAX_RETRIES" ]; then echo "Timed out after max retries."; fi
