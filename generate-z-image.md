Use the Bash tool to generate an image via the Evolink Z-Image-Turbo API.

## Prerequisites — API Key

Before generating, check if the environment variable `EVOLINK_API_KEY` is set:
- Windows: `echo %EVOLINK_API_KEY%`
- Unix: `echo $EVOLINK_API_KEY`

- If it is **empty or not set**, ask the user to provide their Evolink API Key.
- If the user **does not have a key**, tell them to register at: https://evolink.ai/signup , then go to https://evolink.ai/dashboard/keys to create an API Key.
- Once the user provides the key, save it as a variable in your context for use in subsequent steps. Do NOT use `set` or `export` — they will not persist across Bash calls.

## Instructions

The user wants to generate an image. **If the user did not provide a prompt, ask them first before proceeding.**

Extract the following from their request:
- **prompt**: The image description (required — must ask if missing, max 2000 characters)
- **size**: Image aspect ratio (optional, default "1:1"). Options: "1:1", "2:3", "3:2", "3:4", "4:3", "9:16", "16:9", "1:2", "2:1", or custom "WxH" (376-1536px)
- **seed**: Random seed for reproducibility (optional, range: 1-2147483647)
- **nsfw_check**: Enable stricter NSFW content filtering (optional, default false). Ask the user if they want to enable it.

## Execution

All HTTP operations use `curl`, which is natively available on Windows 10+, macOS, and Linux. User input (prompt) is written to a file via the Write tool to avoid shell escaping issues entirely.

### Step 1: Write the request body to a file

Use the **Write tool** (not Bash) to create a `evolink-request-<TIMESTAMP>.json` file in the current working directory:

```json
{
  "model": "z-image-turbo",
  "prompt": "<USER_PROMPT>",
  "size": "<SIZE>",
  "nsfw_check": <true|false>
}
```

This completely avoids shell escaping — the prompt goes directly into the file, no matter what special characters it contains.

### Step 2: Submit + Poll + Download (single script)

Check the `Platform` field from your environment info, then run the corresponding script in a **single Bash call**.

Replace `<API_KEY>` with the actual key, `<REQUEST_FILE>` with the filename from Step 1, and `<OUTPUT_FILE>` with `evolink-<TIMESTAMP>.webp`.

#### Windows (Platform: `win32`)

```powershell
powershell -Command "
$apiKey = '<API_KEY>'
$reqFile = '<REQUEST_FILE>'
$outFile = '<OUTPUT_FILE>'
$headers = @{Authorization=\"Bearer $apiKey\"; 'Content-Type'='application/json'}
$body = Get-Content $reqFile -Raw

# Submit
$resp = Invoke-RestMethod -Uri 'https://api.evolink.ai/v1/images/generations' -Method Post -Headers $headers -Body $body
$taskId = $resp.id
Write-Host \"Task submitted: $taskId\"

# Poll
$maxRetries = 200
for ($i = 0; $i -lt $maxRetries; $i++) {
    Start-Sleep -Seconds 10
    $task = Invoke-RestMethod -Uri \"https://api.evolink.ai/v1/tasks/$taskId\" -Headers @{Authorization=\"Bearer $apiKey\"}
    Write-Host \"[$i] Status: $($task.status) | Progress: $($task.progress)%\"
    if ($task.status -eq 'completed') {
        $url = $task.results[0]
        Write-Host \"Image URL: $url\"
        Invoke-WebRequest -Uri $url -OutFile $outFile
        Write-Host \"Downloaded to: $outFile\"
        break
    }
    if ($task.status -eq 'failed') {
        Write-Host \"Generation failed: $($task | ConvertTo-Json)\"
        break
    }
}
if ($i -eq $maxRetries) { Write-Host 'Timed out after max retries.' }
"
```

#### Unix / macOS (Platform: `darwin` or `linux`)

```bash
API_KEY="<API_KEY>"
REQ_FILE="<REQUEST_FILE>"
OUT_FILE="<OUTPUT_FILE>"

# Submit
RESP=$(curl -s -X POST "https://api.evolink.ai/v1/images/generations" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d @"$REQ_FILE")
TASK_ID=$(echo "$RESP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "Task submitted: $TASK_ID"

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
```

## Result Handling

After completion, respond to the user:

- **completed**: Show the image URL and confirm the file was downloaded as `evolink-<TIMESTAMP>.webp`. Remind them the URL expires in **72 hours**.
- **failed**: Report the error message from the API.
- **timed out** (200 polls): Inform the user and provide the task ID for manual follow-up.
- **cleanup**: Delete the `evolink-request-<TIMESTAMP>.json` temp file after the task is done.