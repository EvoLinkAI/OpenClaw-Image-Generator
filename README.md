# OpenClaw-Image-Generator

A Claude Code skill for generating images via the [Evolink Z-Image-Turbo](https://evolink.ai) API. Cross-platform, zero dependencies — works natively on Windows, macOS, and Linux.

## Features

- Cross-platform: uses `curl` (natively available on all modern OS)
- No shell escaping issues: user prompts are passed via bash heredoc, no temp files needed
- Auto-download: images saved locally as `evolink-{timestamp}.webp`
- Configurable size, seed, and polling parameters
- Standard Skill structure with progressive disclosure

## Skill Structure

```
generate-z-image/
├── SKILL.md                 # Main skill file (YAML frontmatter + instructions)
├── scripts/
│   └── generate.sh          # Bash script template
└── references/
    └── api-reference.md     # API documentation
```

## Installation

Copy the `generate-z-image/` folder to your project's Claude Code commands directory:

```bash
# In your project root
mkdir -p .claude/commands
cp -r generate-z-image .claude/commands/
```

## Prerequisites

You need an Evolink API Key. If you don't have one:

1. Register at https://evolink.ai/signup
2. Go to https://evolink.ai/dashboard/keys to create a key

Set it as a system environment variable so the skill can auto-detect it:

```bash
# Windows (PowerShell, requires restart terminal)
[System.Environment]::SetEnvironmentVariable('EVOLINK_API_KEY', 'your-key-here', 'User')

# macOS / Linux
echo 'export EVOLINK_API_KEY="your-key-here"' >> ~/.bashrc && source ~/.bashrc
```

If not set, Claude will prompt you for the key on first use.

## Usage

In Claude Code, type:

```
/generate-z-image a cat sitting on the moon
```

Or simply `/generate-z-image` and Claude will ask for your prompt.

### Examples

```
# Basic usage — just describe what you want
/generate-z-image a cyberpunk city at night with neon lights

# Specify aspect ratio in your prompt
/generate-z-image a portrait photo of a woman, size 9:16

# Request a specific seed for reproducibility
/generate-z-image a watercolor landscape, seed 42
```

### How It Works

1. Claude checks for your `EVOLINK_API_KEY` environment variable (prompts you if not set)
2. Submits your prompt to the Evolink Z-Image-Turbo API
3. Polls the task status every 10 seconds (up to 200 retries)
4. Downloads the generated image as `evolink-{timestamp}.webp` to your working directory

## Parameters

| Parameter | Required | Default | Description |
|---|---|---|---|
| prompt | Yes | — | Image description |
| size | No | `1:1` | Aspect ratio: `1:1`, `2:3`, `3:2`, `3:4`, `4:3`, `9:16`, `16:9`, `1:2`, `2:1`, or custom `WxH` (376-1536px) |
| seed | No | random | Random seed for reproducibility |
| nsfw_check | No | `false` | Enable stricter NSFW content filtering |

## Notes

- Image URLs expire in **72 hours** — images are auto-downloaded locally as `evolink-{timestamp}.webp`
- First-time use will prompt for your API key; set `EVOLINK_API_KEY` as a system environment variable to skip this step