# YouTube Transcript Extraction via youtube-transcript.io

## Problem
YouTube aggressively blocks all automated transcript access:
- youtube-transcript-api: `RequestBlocked` (IP banned from cloud IPs)
- yt-dlp: `Sign in to confirm you're not a bot` (requires cookies)
- Direct API: Empty responses
- Third-party services: Cloudflare blocked

## Working Solution: youtube-transcript.io

### Browser-based extraction

1. Navigate to `https://www.youtube-transcript.io/?v={VIDEO_ID}`
2. Page auto-loads with a URL input form
3. Paste YouTube URL and click "Extract transcript"
4. Wait for loading dialog ("We are fetching the Transcript")
5. Full transcript appears with timestamps
6. Extract via `browser_console` → `document.body.innerText`

### Example JavaScript extraction
```javascript
// After transcript loads
const text = document.body.innerText;
// Clean up - remove navigation/header text
const transcript = text.split('Copy Transcript')[1]?.split('Autoscroll')[0] || text;
```

### Saving the transcript
```bash
# Save to ~/youtube-scripts/
echo "$TRANSCRIPT" > ~/youtube-scripts/{video_title}_字幕.txt
```

### Key details
- Service URL: `https://www.youtube-transcript.io`
- Free tier: 25 transcripts/month
- No login required for basic extraction
- Returns full transcript with timestamps
- Works with auto-generated English subtitles

### Fallback chain
1. Try youtube-transcript.io (browser)
2. If blocked → ask user to download SRT from saveanyyoutube.com
3. If all else fails → use MiMo ASR on downloaded audio

### Related tools
- saveanyyoutube.com: Can download SRT subtitles (Caption Downloader section)
- MiMo ASR: For audio transcription when no subtitles available
