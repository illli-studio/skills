---
name: ui2v-api
description: Use when generating videos or posters with the local UI2V HTTP API. Covers text-to-video, text-to-poster, custom dimensions, quality tiers, optional styles, and the async job flow used by this workstation where `POST /video` and `POST /poster` can return job metadata that must be followed via `/status/:requestId` and `/result/:requestId`.
---

# UI2V HTTP API Skill

Use the local UI2V server at `http://127.0.0.1:5125`.

## Use this skill for

- Text-to-video generation
- Text-to-poster generation
- Custom dimensions
- Optional styles
- Async job submission, polling, and result download on this workstation
- Reusable PowerShell scripts instead of ad hoc one-off terminal code

## Output types

UI2V supports two primary generation modes:

- Video generation: animated output such as `mp4` or `webm`
- Poster generation: static output such as `png` or `jpg`

Both flows can behave asynchronously on this workstation. Do not assume posters are always synchronous just because they are images.

## Use this workflow

1. Ensure UI2V is reachable at `http://127.0.0.1:5125`.
2. Treat `GET /` returning `404` as acceptable. On this machine that still means the service is up.
3. Submit either `POST /video` or `POST /poster` with the correct payload.
4. Inspect the submit response:
   - If the content type is `video/*` or `image/*`, save the stream directly.
   - If the response body is JSON and contains `requestId`, switch to async polling.
5. Poll `GET /status/:requestId` until the job reaches `completed` or `failed`.
6. When status becomes `completed`, download `GET /result/:requestId` to the final output path with the expected extension.
7. If status becomes `failed`, report the full status payload and retry only the failed job.

## Use the bundled resources

- `scripts/ui2v-common.ps1`: Shared submit, poll, download, and liveness helpers used by both entry scripts.
- `scripts/invoke-ui2v-video.ps1`: Thin entry script for one video request.
- `scripts/invoke-ui2v-poster.ps1`: Thin entry script for one poster request.
- `references/async-media-flow.md`: Detailed async response shapes, endpoints, and operational notes.

Prefer the scripts over ad hoc terminal one-liners whenever the task involves actual delivery work.

## Request shapes

Video request body:

```json
{
  "prompt": "Educational motion graphic with floating equations",
  "format": "mp4",
  "width": 1080,
  "height": 1080,
  "quality": "medium",
  "style": "optional-style-name"
}
```

Poster request body:

```json
{
  "prompt": "Educational poster with books, globe, and bold title area",
  "format": "png",
  "width": 1080,
  "height": 1080,
  "style": "optional-style-name"
}
```

## Quality tiers

- `low`: fastest preview quality
- `medium`: default balance for day-to-day generation
- `high`: stronger final quality
- `ultra`: slower, higher fidelity
- `cinema`: slowest, premium video output when available

Only video requests use `quality`. Poster requests do not require it.

## Handle statuses deliberately

- `queued`: The task is accepted and waiting. Keep polling.
- `generating`: Rendering or export is still in progress. Keep polling.
- `completed`: Download from `/result/:requestId`.
- `failed`: Stop, capture the error payload, and decide whether to resubmit.

## Work with both media types safely

- If an `.mp4` file is only a few hundred bytes, it is probably JSON job metadata that was mistakenly written straight to disk. Open the file, parse the `requestId`, then poll and download the real result.
- If a `.png` or `.jpg` file is only a few hundred bytes, handle it the same way. It may contain queued-job JSON rather than image bytes.
- If the status payload contains `Export already in progress for this project`, too many jobs reached export at the same time. Re-run the failed request after another export finishes, or serialize the batch.
- If the API returns `429 Busy`, wait and retry rather than changing prompts or dimensions.
- If polling times out, show the last status JSON in the final response so the user can see what stalled.

## Batch safely

For multiple videos or posters, prefer sequential execution. Submitting several jobs at once can work, but downloading and exporting them in parallel is less reliable on this machine.

Video batch example:

```powershell
$jobs = @(
  @{ Prompt = "Math lesson motion graphics"; Output = ".\\math.mp4" },
  @{ Prompt = "Science lab motion graphics"; Output = ".\\science.mp4" }
)

foreach ($job in $jobs) {
  powershell -ExecutionPolicy Bypass -File .\skills\ui2v-api\scripts\invoke-ui2v-video.ps1 `
    -Prompt $job.Prompt `
    -OutputFile $job.Output `
    -Width 1080 `
    -Height 1080 `
    -Quality medium `
    -Overwrite
}
```

Poster batch example:

```powershell
$jobs = @(
  @{ Prompt = "Back to school poster"; Output = ".\\poster-1.png" },
  @{ Prompt = "STEM workshop poster"; Output = ".\\poster-2.png" }
)

foreach ($job in $jobs) {
  powershell -ExecutionPolicy Bypass -File .\skills\ui2v-api\scripts\invoke-ui2v-poster.ps1 `
    -Prompt $job.Prompt `
    -OutputFile $job.Output `
    -Width 1080 `
    -Height 1080 `
    -Format png `
    -Overwrite
}
```

## Start UI2V if needed

If the API is not reachable, start the desktop app first.

```powershell
Start-Process "C:\Program Files\UI2V\UI2V.exe"
```

## Poster note

Poster generation is a first-class capability of this skill, not a footnote. Keep its request format, output extension, and downstream usage distinct from video generation, but handle its async job lifecycle with the same care.
