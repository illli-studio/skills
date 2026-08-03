# Skills

Local Codex skills stored with this project.

## Available skills

### ui2v-api

Generate videos and posters through the local UI2V HTTP API.

Highlights:

- Covers both video generation and poster generation.
- Handles the async `POST /video` and `POST /poster` workflows observed on this workstation.
- Polls `GET /status/:requestId` until completion.
- Downloads the final asset from `GET /result/:requestId`.
- Documents export-conflict retries for batch generation.
- Includes reusable PowerShell helper scripts with a shared common layer.

[View skill](./ui2v-api/SKILL.md)


### video-transcript

Extract transcripts from video platforms (Bilibili, YouTube, Douyin) by downloading audio and running MiMo ASR.

Highlights:

- Supports Bilibili, YouTube, and Douyin (抖音).
- Uses MiMo ASR API for speech-to-text.
- Handles long videos with audio chunking.
- Includes proxy configuration for yt-dlp.
- Multiple fallback methods for YouTube transcripts.

[View skill](./video-transcript/SKILL.md)

## Install

```bash
npx skills add illli-studio/skills
```