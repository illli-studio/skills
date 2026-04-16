# Async media flow

Use this reference when `POST /video` or `POST /poster` does not return binary media directly.

## Endpoints

- Video submit: `POST http://127.0.0.1:5125/video`
- Poster submit: `POST http://127.0.0.1:5125/poster`
- Status poll: `GET http://127.0.0.1:5125/status/<requestId>`
- Result download: `GET http://127.0.0.1:5125/result/<requestId>`

## Expected submit payloads

Video payload fields:

- `prompt`
- `format`
- `width`
- `height`
- `quality`
- `style`

Poster payload fields:

- `prompt`
- `format`
- `width`
- `height`
- `style`

## Observed async responses

Video requests can return:

```json
{
  "requestId": "video-1776341339696-5ecf0a33",
  "status": "generating",
  "message": "Task queued. Poll GET /status/:requestId for progress, then GET /result/:requestId to download."
}
```

Poster requests can return:

```json
{
  "requestId": "poster-1776345482543-0d7c91bf",
  "status": "generating",
  "message": "Task queued. Poll GET /status/:requestId for progress, then GET /result/:requestId to download."
}
```

## Polling guidance

Poll every 5 to 10 seconds.

Useful states:

- `queued`
- `generating`
- `completed`
- `failed`

Example failure:

```json
{
  "requestId": "video-1776341161580-f28a6d6e",
  "type": "video",
  "status": "failed",
  "progress": 63,
  "progressMessage": "start exporting video",
  "error": "Export already in progress for this project",
  "resultConsumed": false
}
```

## Binary-vs-JSON detection

- If submit returns `video/*`, write the response directly to the output file.
- If submit returns `image/*`, write the response directly to the output file.
- If submit returns JSON with `requestId`, switch to polling mode.
- If a tiny output file appears where a real asset should be, inspect it before deleting it. It may contain the queued-job JSON.

## Operational notes

- Treat `GET /` returning `404` as acceptable service liveness for this local UI2V install.
- Prefer sequential batches. Parallel export is more likely to trigger `Export already in progress for this project`.
- Retry only the failed job after the current export finishes.
