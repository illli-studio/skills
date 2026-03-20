# Claude Code Skills

Collection of Claude Code skills for various tools and APIs.

## Available Skills

### ui2v-api

AI-powered video and poster generation via HTTP API.

- **POST /video** - Generate animated videos (MP4/WebM)
- **POST /poster** - Generate poster images (PNG/JPG)
- 5 quality tiers: low → cinema
- Custom dimensions and styles

[View Skill →](./ui2v-api/SKILL.md)

## Installation

Copy the skill folder to your Claude Code skills directory:

```bash
# macOS/Linux
cp -r ui2v-api ~/.claude/skills/

# Windows
xcopy /E /I ui2v-api "%USERPROFILE%\.claude\skills\ui2v-api"
```

## Usage

Skills are automatically loaded when relevant tasks are detected. No manual activation needed.