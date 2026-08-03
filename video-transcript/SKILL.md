---
name: video-transcript
description: "Extract transcripts from video platforms (Bilibili, YouTube, etc.) by downloading audio and running ASR. User preference: always use this approach when given a video link."
platforms: [macos, linux]
triggers:
  - User shares a video URL (Bilibili, YouTube, etc.)
  - User asks to extract/download/transcribe video text or script
  - User says "识别文案" or "下载文案" for a video
---

# Video Transcript Extraction

## When to use
User shares a video URL and wants the spoken content transcribed to text. Works for Bilibili, YouTube, and other platforms by downloading audio and running ASR.

## User Preference
**Always use this workflow when the user shares a video link.** The user explicitly requested: "以后我给你视频你就按照这样识别出给我". Do NOT ask which method to use — just do it.

## Workflow

### Step 1: Get video info
For Bilibili short URLs (b23.tv), resolve first:
```bash
curl -sL -o /dev/null -w "%{url_effective}" "https://b23.tv/xxx"
```
Extract BV ID from the redirect URL.

Get cid:
```bash
curl -s "https://api.bilibili.com/x/web-interface/view?bvid=BVxxx" \
  -H "Referer: https://www.bilibili.com" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  | python3 -c "import json,sys; d=json.load(sys.stdin)['data']; print(d['cid'])"
```

### Step 2: Download audio
Get audio stream URL from Bilibili playurl API:
```bash
curl -s "https://api.bilibili.com/x/player/playurl?bvid=BVxxx&cid=XXX&fnval=16&qn=64" \
  -H "Referer: https://www.bilibili.com" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  | python3 -c "import json,sys; a=json.load(sys.stdin)['data']['dash']['audio']; print(sorted(a,key=lambda x:x['bandwidth'],reverse=True)[0]['baseUrl'])"
```

Download and convert:
```bash
curl -L -o /tmp/bili_audio.m4s "$AUDIO_URL" \
  -H "Referer: https://www.bilibili.com" \
  -H "User-Agent: Mozilla/5.0 ..."
ffmpeg -i /tmp/bili_audio.m4s -vn -acodec libmp3lame -q:a 2 /tmp/bili_audio.mp3 -y
```

**Pitfall**: yt-dlp does NOT work with Bilibili — returns 412 Precondition Failed. Always use the Bilibili API directly.

### For Douyin (抖音)

**Pitfall**: yt-dlp does NOT work with Douyin — requires fresh cookies and still fails. Douyin web also blocks bots aggressively. Use SnapAny as primary method.

**See also:** `references/douyin-transcript-workflow.md` for full validated workflow.

#### PRIMARY: SnapAny + MiMo ASR (most reliable)

SnapAny (snapany.com) parses Douyin links and provides direct download URLs.

1. Navigate to `https://snapany.com/zh/tiktok`
2. Paste the Douyin URL into textbox (both `v.douyin.com` short links AND full `douyin.com/video/` URLs work — do NOT waste time converting to short links)
3. Click "提取视频图片", wait for results to load (button re-enables, download links appear)
4. Extract download URLs via `browser_console`:
   ```javascript
   const dl = [];
   document.querySelectorAll('a').forEach(l => {
       if (l.href && (l.href.includes('douyinvod') || l.href.includes('douyinstatic') || l.href.includes('douyinpic')))
           dl.push({text: l.textContent.trim(), href: l.href});
   });
   JSON.stringify(dl);
   ```
5. **Fast path — direct audio link**: If you see a "下载音频" link pointing to `douyinstatic.com` (e.g. `lf9-music-east.douyinstatic.com/obj/ies-music-hj/*.mp3`), download it directly — no video download or ffmpeg needed:
   ```bash
   curl -L -o /tmp/douyin_audio.mp3 "$AUDIO_CDN_URL"
   ```
   **⚠️ SSL pitfall**: Some audio CDN domains (e.g. `sf6-cdn-tos.douyinstatic.com`) may fail with `SSL_ERROR_SYSCALL` from certain networks. If curl hangs or fails, fall back to the video download path immediately — don't retry the same URL.
6. **Fallback — video download + extract**: Get "下载视频" URL (from `douyinvod.com`), download and extract audio:
   ```bash
   curl -L -o /tmp/douyin_video.mp4 "$VIDEO_URL" -H "Referer: https://www.douyin.com/"
   ffmpeg -i /tmp/douyin_video.mp4 -vn -acodec libmp3lame -q:a 2 /tmp/douyin_audio.mp3 -y
   ```
   Note: the `-H "Referer: https://www.douyin.com/"` header is sometimes needed for douyinvod.com URLs.
7. Proceed to MiMo ASR section below

**Pitfall**: Douyin web page may show "你要观看的视频不存在" — this means the video is mobile-app-only, NOT deleted. SnapAny can still parse it.

#### FALLBACK: browser-act network interception

If SnapAny fails, try browser-act:
1. Open `https://www.douyin.com/video/{VIDEO_ID}` in browser-act
2. If page shows "视频不存在" or "视频数据加载中" forever → switch back to SnapAny
3. Otherwise intercept video URLs from network requests

Then proceed to MiMo ASR section below.

### Step 3: Verify API key (CRITICAL — do this before ASR)
MiMo API keys can expire. Always verify before starting a long transcription:
```bash
curl -s "https://token-plan-cn.xiaomimimo.com/v1/models" -H "api-key: YOUR_KEY...
```
If this returns `Invalid API Key`, ask the user for a fresh key immediately. Do NOT proceed with transcription attempts that will all fail.

### Step 4: ASR with MiMo

**⚠️ CRITICAL: Always chunk audio first!** MiMo ASR truncates transcripts for files >2MB MP3 (~3min). A 7-minute video returned only ~500 chars without chunking. See `references/douyin-transcript-workflow.md` Method 3 for chunking commands.

Use `execute_code` to call MiMo ASR API:
- Endpoint: `https://token-plan-cn.xiaomimimo.com/v1/chat/completions`
- Model: `mimo-v2.5-asr`
- API Key: stored in memory (MiMo ASR key)
- Audio format: base64-encoded MP3 in `input_audio` content block
- Header: `Authorization: Bearer <key>` (also works with `api-key: <key>`)
- Base64 size limit: 10MB

ASR payload structure:
```python
{
    "model": "mimo-v2.5-asr",
    "messages": [{
        "role": "user",
        "content": [{
            "type": "input_audio",
            "input_audio": {
                "data": f"data:audio/mpeg;base64,{audio_b64}",
                "format": "mp3"
            }
        }]
    }]
}
```

**Pitfall**: Omit `asr_options.language` on retry if first attempt has repetition issues — removing the language hint sometimes improves accuracy.

**Pitfall**: MiMo ASR uses `/v1/chat/completions` endpoint, NOT a dedicated `/audio/transcriptions` endpoint. Trying `/audio/transcriptions` returns 404.

### Step 5: Format and deliver
Present the transcript with:
- Video title as heading
- Clean paragraph breaks
- Bold section markers where the speaker numbers items (一、二、三...）

## For YouTube

YouTube is aggressively blocking automated transcript access. Multiple approaches fail:
- `youtube-transcript-api` Python package → `RequestBlocked` (IP banned)
- `yt-dlp --write-auto-sub` → `Sign in to confirm you're not a bot`
- Direct `youtube.com/api/timedtext` → Empty response
- Third-party services (downsub.com) → Cloudflare blocked

### PRIMARY: browser-act + saveanyyoutube.com (verified working)

This is the most reliable method. It uses browser-act to intercept the subtitle API call.

1. Start browser-act session: `browser-act --session yt browser open <browser_id> "https://www.saveanyyoutube.com/watch?v={VIDEO_ID}"`
2. Wait for page to load: `browser-act --session yt wait stable`
3. Scroll down to find subtitle section: `browser-act --session yt scroll down`
4. Find and click the SRT download button (look for "Subtitle" → "SRT" → "Download")
5. Intercept the API call via `browser-act --session yt network requests --filter subtitle --type xhr,fetch`
6. Get the subtitle URL from the API response: `browser-act --session yt network request <request_id>`
7. The response contains `subtitles[0].url` — this is the YouTube timedtext URL
8. Fetch the URL directly with Python requests to get the transcript
9. Parse JSON3 format: extract `events[].segs[].utf8` and join
10. Save to `~/youtube-scripts/{video_title}_字幕.txt`

**Key API details:**
- saveanyyoutube.com calls `https://service.saveanyyoutube.com./api/video/subtitles` with POST body `{"url": "https://www.youtube.com/watch?v={VIDEO_ID}"`
- Response contains `subtitles[0].url` which is a YouTube timedtext URL
- The timedtext URL returns JSON3 format with `events[].segs[].utf8` text segments

**Pitfall**: browser-act requires API Key. Run `browser-act auth set <KEY>` first.

### FALLBACK: youtube-transcript.io

If browser-act is unavailable, use the browser to extract transcripts via `youtube-transcript.io`:

1. `browser_navigate` to `https://www.youtube-transcript.io/?v={VIDEO_ID}`
2. Paste the YouTube URL and click "Extract transcript"
3. Wait for loading, then extract text via `browser_console` with `document.body.innerText`
4. Save to `~/youtube-scripts/{video_title}_字幕.txt`

### LAST RESORT: Ask user to download manually

If both methods fail, ask the user to:
1. Open saveanyyoutube.com in their browser
2. Paste the YouTube link
3. Click Caption Downloader → English (auto-generated) → SRT → Download
4. Save the SRT file to `~/youtube-scripts/`

### When to use which method
| Scenario | Method |
|----------|--------|
| YouTube video, transcript API works | `youtube-content` skill |
| YouTube video, transcript API blocked | `youtube-transcript.io` via browser |
| YouTube video, all APIs blocked | Ask user to download SRT manually |
| Bilibili video | Bilibili API + MiMo ASR (this skill) |
| Douyin video | SnapAny + MiMo ASR (this skill) — full URLs work fine |

## Dependencies
- `ffmpeg` (pre-installed on macOS)
- No Python packages needed (uses stdlib `urllib` + `base64`)

## ⚠️ Proxy Rule
When using mihomo for proxy, do NOT set system global proxy via `networksetup`. Use rule-based routing only. Global proxy causes other services to lose connection. User explicitly said: "开代理不要开全局，按规则连接，不然你会断开连接，不想失去你".

## Proxy Setup for yt-dlp (YouTube)

yt-dlp needs proxy to access YouTube from this machine. mihomo is installed but has **no launchd service** — must be started manually.

### Start mihomo (if not running)
```bash
# Check if already running
lsof -i :7890 2>/dev/null | head -3

# If not running, start in background
mihomo -d /Users/elham/.config/mihomo &>/dev/null &
sleep 2 && lsof -i :7890 2>/dev/null | head -3
```
- Config: `~/.config/mihomo/config.yaml`
- Mixed-port: `7890`
- Binary: `/opt/homebrew/bin/mihomo`

### Use proxy with yt-dlp
```bash
yt-dlp --proxy socks5://127.0.0.1:7890 <URL>
```

### yt-dlp YouTube download (ASR fallback)
When YouTube subtitles are unavailable, yt-dlp can download the video/audio for ASR transcription:
```bash
# Download audio only
yt-dlp --proxy socks5://127.0.0.1:7890 -x --audio-format mp3 -o "/tmp/%(title)s.%(ext)s" "URL"

# Download video (for audio extraction)
yt-dlp --proxy socks5://127.0.0.1:7890 -f "best[height<=720]" -o "/tmp/%(title)s.%(ext)s" "URL"
```
Then extract audio with ffmpeg and run MiMo ASR as usual.

## Output
Present the full transcript directly in chat. No need to save to file unless user asks.
