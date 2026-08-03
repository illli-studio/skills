# YouTube Transcript via browser-act + saveanyyoutube.com

## Verified Working Method (2026-07-07)

This method uses browser-act to intercept the subtitle API call from saveanyyoutube.com.

### Prerequisites
- browser-act installed: `uv tool install browser-act-cli --python 3.12`
- API Key configured: `browser-act auth set <KEY>`
- Browser created: `browser-act browser create --type chrome --name "yt" --desc "YouTube"`

### Step-by-step

```bash
# 1. Open saveanyyoutube.com with the video URL
browser-act --session yt browser open <browser_id> "https://www.saveanyyoutube.com/watch?v={VIDEO_ID}"

# 2. Wait for page to load
browser-act --session yt wait stable

# 3. Scroll down to find subtitle section
browser-act --session yt scroll down

# 4. Find the subtitle download button (look for "Subtitle" → "SRT" → "Download")
# Use state to find the button index, then click it

# 5. Intercept the API call
browser-act --session yt network requests --filter subtitle --type xhr,fetch

# 6. Get the subtitle URL from the API response
browser-act --session yt network request <request_id>

# 7. The response contains subtitles[0].url — this is the YouTube timedtext URL
# Fetch it with Python requests to get the transcript
```

### Python code to fetch transcript

```python
import requests
import json

subtitle_url = "https://www.youtube.com/api/timedtext?v={VIDEO_ID}&...&fmt=json3"
resp = requests.get(subtitle_url, timeout=15)
data = resp.json()

# Extract transcript
events = data.get('events', [])
transcript_parts = []
for event in events:
    if 'segs' in event:
        for seg in event['segs']:
            text = seg.get('utf8', '')
            if text.strip():
                transcript_parts.append(text.strip())

full_transcript = ' '.join(transcript_parts)
```

### API Details

**saveanyyoutube.com subtitle API:**
- Endpoint: `https://service.saveanyyoutube.com./api/video/subtitles`
- Method: POST
- Body: `{"url": "https://www.youtube.com/watch?v={VIDEO_ID}"`
- Response: `{"subtitles": [{"languageName": "English (auto-generated)", "url": "..."}]}`

**YouTube timedtext API:**
- Returns JSON3 format when `fmt=json3` parameter is included
- Contains `events[].segs[].utf8` text segments
- URL expires (has `expire` parameter) — fetch promptly

### Pitfalls

1. **browser-act requires API Key** — register at https://www.browseract.com
2. **Subtitle URL expires** — the timedtext URL has an expiration timestamp
3. **Page may need scrolling** — subtitle section is below the fold
4. **Network monitoring** — use `network requests` to capture the API call, not `network request` directly
