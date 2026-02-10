---
name: generate-z-image
description: >
  Generate images using the Evolink Z-Image-Turbo API. Use when the user asks
  to create, generate, or produce an AI image, illustration, or artwork.
  Trigger phrases: "generate an image", "create a picture", "make an illustration",
  "draw", "image of", "picture of".
allowed-tools: "Bash(curl:*)"
metadata:
  author: OpenClaw
  version: 1.0.0
  category: image-generation
  tags: [ai-image, evolink, z-image-turbo, text-to-image]
---

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

Use the script at `scripts/generate.sh` as a template. Read it, replace the `{{...}}` placeholders with actual values, then run the entire script in a **single Bash call**.

**Placeholder replacements:**
- `{{API_KEY}}` → the actual API key
- `{{OUTPUT_FILE}}` → `evolink-{{TIMESTAMP}}.webp`
- `{{USER_PROMPT}}` → the user's prompt (apply **JSON escaping**: escape `"` with `\"`, escape `\` with `\\`)
- `{{SIZE}}` → the chosen aspect ratio (default `1:1`)
- `{{NSFW_CHECK}}` → `true` or `false`

**Notes:**
- The Bash tool runs bash on all platforms (including Windows), so no platform-specific scripts are needed.
- The user's prompt is embedded in a single-quoted heredoc (EVOLINK_END), which prevents all shell interpretation. Only JSON escaping is needed.

## Result Handling

After completion, respond to the user:

- **completed**: Show the image URL and confirm the file was downloaded as `evolink-{{TIMESTAMP}}.webp`. Remind them the URL expires in **72 hours**.
- **failed**: Report the error message from the API.
- **timed out** (200 polls): Inform the user and provide the task ID for manual follow-up.

## Example Usage

- "Generate an image of a sunset over the ocean"
- "Create a 16:9 wallpaper of a cyberpunk city at night"
- "Draw a cute cat in watercolor style, portrait ratio"
- "Make an illustration of a forest with seed 42"

## Performance Notes

- Always confirm the prompt with the user before calling the API.
- Prefer downloading the image locally so the user has a permanent copy (URL expires in 72 hours).
- For detailed API parameters, see `references/api-reference.md`.
