# Douyin Transcript Extraction Workflow

Validated working workflow for extracting full transcripts from Douyin videos.

## Method Priority

| Method | Reliability | When to use |
|--------|-------------|-------------|
| **SnapAny + MiMo ASR** | ⭐⭐⭐ High | Default — works even when Douyin web blocks |
| browser-act network intercept | ⭐⭐ Medium | When Douyin web loads normally |
| Douyin web API directly | ⭐ Low | Rarely works — anti-bot protection |

## Method 1: SnapAny + MiMo ASR (preferred)

SnapAny (snapany.com) can parse Douyin links and provide direct video/audio download URLs.

### Step 1: Navigate to SnapAny
Both `v.douyin.com` short links AND full `douyin.com/video/` URLs work on SnapAny. Do NOT waste time converting to short links.

```python
browser_navigate("https://snapany.com/zh/tiktok")
```

### Step 2: Paste URL and submit
1. Find the textbox "粘贴 APP 或网站中复制的链接"
2. Type the Douyin URL (full URL is fine)
3. Click "提取视频图片" button
4. Wait for result — button re-enables, title + download links appear below

### Step 3: Extract download URLs via browser_console
```javascript
const dl = [];
document.querySelectorAll('a').forEach(l => {
    if (l.href && (l.href.includes('douyinvod') || l.href.includes('douyinstatic') || l.href.includes('douyinpic')))
        dl.push({text: l.textContent.trim(), href: l.href});
});
JSON.stringify(dl);
```

Look for two types of links:
- **"下载音频"** → direct MP3 from `douyinstatic.com` (fastest path)
- **"下载视频"** → MP4 from `douyinvod.com` (needs ffmpeg extraction)

### Step 4a: Fast path — direct audio CDN (preferred)
If you see a "下载音频" link from `douyinstatic.com`, download directly:
```bash
curl -L -o /tmp/douyin_audio.mp3 "$AUDIO_CDN_URL"
```
⚠️ Some CDN domains (`sf6-cdn-tos.douyinstatic.com`) may have SSL issues — if curl fails with SSL_ERROR_SYSCALL, fall back to Step 4b.

### Step 4b: Fallback — video download + extract
```bash
curl -L -o /tmp/douyin_video.mp4 "$VIDEO_URL" -H "Referer: https://www.douyin.com/"
ffmpeg -i /tmp/douyin_video.mp4 -vn -acodec libmp3lame -q:a 2 /tmp/douyin_audio.mp3 -y
```
Note: `-H "Referer: https://www.douyin.com/"` is sometimes needed for douyinvod.com URLs.

### Step 6: Chunk and transcribe (see Method 2, Steps 5-7)

## Method 2: browser-act + MiMo ASR (fallback)

### Step 1: Open Douyin video in browser-act
```bash
browser-act --session dy browser open <browser_id> "https://www.douyin.com/video/{VIDEO_ID}"
browser-act --session dy wait stable
```

**Pitfall:** Douyin web often shows "你要观看的视频不存在" or "视频数据加载中" without loading. If page shows either message, switch to Method 1 (SnapAny).

### Step 2: Intercept audio URL from network requests
```bash
browser-act --session dy network requests --filter video --type xhr,fetch
```
Look for entries with `mime_type=video/mp4`. The audio URL contains `media-audio-und-mp4a` in the path.

### Step 3: Download audio
```python
import requests
resp = requests.get(audio_url, headers={'Referer': 'https://www.douyin.com/'}, stream=True)
with open('/tmp/douyin_audio.mp4', 'wb') as f:
    for chunk in resp.iter_content(8192):
        f.write(chunk)
```

### Step 4: Convert to mp3
```bash
ffmpeg -i /tmp/douyin_audio.mp4 -vn -acodec libmp3lame -q:a 2 /tmp/douyin_audio.mp3 -y
```

## Method 3: Chunk long audio (critical for all methods!)

MiMo ASR truncates transcripts for files >2MB MP3 (~3min). **Always check duration and chunk before ASR.**

```bash
# Check duration
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 audio.mp3

# Split into 120-second chunks
for i in $(seq 0 120 $TOTAL_DURATION); do
    ffmpeg -i audio.mp3 -ss $i -t 120 -acodec libmp3lame -q:a 4 chunk_$i.mp3 -y
done
```

## Method 4: Transcribe each chunk with MiMo ASR

API endpoint: `https://token-plan-cn.xiaomimimo.com/v1/chat/completions`
Header: `Authorization: Bearer <key>` (also works with `api-key: <key>`)
Model: `mimo-v2.5-asr`

```python
payload = {
    "model": "mimo-v2.5-asr",
    "messages": [{"role": "user", "content": [{
        "type": "input_audio",
        "input_audio": {"data": f"data:audio/mpeg;base64,{audio_b64}", "format": "mp3"}
    }}]
}
```

Typical yield: ~800 chars per 2-minute chunk for Chinese speech.

## Method 5: Concatenate and save
Join all chunk transcripts with `\n\n` separators. Save to `~/youtube-scripts/`.

## Pitfalls
- **yt-dlp does NOT work with Douyin** — requires fresh cookies, even with cookies from browser it fails
- **Douyin web blocks bots** — browser tools often can't load the video page. SnapAny is more reliable
- **Full Douyin URLs work fine on SnapAny** — no need to convert to short links
- **Some Douyin audio CDN domains have SSL issues** — `sf6-cdn-tos.douyinstatic.com` may fail with SSL_ERROR_SYSCALL; fall back to video download path
- **Audio URLs from network interception are temporary** (expire in ~2 hours)
- **Always chunk audio before ASR** — full 7min video returned only partial transcript (~500 chars) without chunking
- **MiMo ASR API uses chat/completions endpoint** — NOT a dedicated /audio/transcriptions endpoint
- **Douyin web page shows "视频不存在"** — this usually means the video can only be viewed in the mobile app, not that it's deleted. SnapAny can still parse it
- **Download video with Referer header** — some douyinvod.com URLs need `-H "Referer: https://www.douyin.com/"` or they return 403
