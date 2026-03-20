---
name: ui2v-api
description: Use when calling ui2v HTTP API for video/poster generation, integrating with external apps, or understanding ui2v's generative capabilities
---

# UI2V HTTP API

## Overview

**UI2V** is an AI-powered video and poster generation tool. Users input text prompts to generate high-quality animated videos or static poster images.

### Core Capabilities

| Feature | Description |
|---------|-------------|
| 🎬 **Video Generation** | Text-to-animation video, supports MP4/WebM formats |
| 🖼️ **Poster Generation** | Text-to-static image, supports PNG/JPG formats |
| 🎨 **Style System** | Preset styles or custom styles |
| 📐 **Custom Dimensions** | Customizable width/height |
| ⚡ **Quality Tiers** | 5 quality levels: low → cinema |

### Use Cases

- Product promotional video generation
- Social media content creation
- Dynamic poster design
- Educational demonstration animations
- Rapid prototype visualization

## HTTP API Endpoints

**Base URL**: `http://127.0.0.1:5125`

**Request Limit**: Max body size 2MB

---

### POST /video

Generate animated video.

**Request Body**:

```typescript
{
  prompt: string,                    // Required - describes the video content to generate
  format?: "mp4" | "webm",          // Output format, default "mp4"
  width?: number,                   // Video width (pixels)
  height?: number,                  // Video height (pixels)
  quality?: "low" | "medium" | "high" | "ultra" | "cinema",  // Quality, default "medium"
  style?: string                    // Style name (optional)
}
```

**Response Headers**:

| Header | Description |
|--------|-------------|
| `X-UI2V-Animation-Id` | Generated animation ID |
| `X-UI2V-Format` | Output format |
| `Content-Type` | `video/mp4` or `video/webm` |
| `Content-Length` | File size (bytes) |

**Status Codes**:

| Code | Meaning | Scenario |
|------|---------|----------|
| 200 | Success | Video generated, returns file stream |
| 400 | Bad Request | Missing prompt parameter |
| 413 | Payload Too Large | Request body exceeds 2MB |
| 429 | Busy | Currently processing another request |
| 500 | Server Error | Internal error |

**Example**:

```bash
curl -X POST http://127.0.0.1:5125/video \
  -H "Content-Type: application/json" \
  -d '{"prompt": "A glowing sphere rotating in darkness", "quality": "high"}' \
  --output video.mp4
```

---

### POST /poster

Generate static poster image.

**Request Body**:

```typescript
{
  prompt: string,               // Required - describes the poster content to generate
  format?: "png" | "jpg",      // Output format, default "png"
  width?: number,              // Width (pixels)
  height?: number,             // Height (pixels)
  style?: string               // Style name (optional)
}
```

**Response Headers**:

| Header | Description |
|--------|-------------|
| `X-UI2V-Poster-Id` | Generated poster ID |
| `Content-Type` | `image/png` or `image/jpeg` |
| `Content-Length` | File size (bytes) |

**Example**:

```bash
curl -X POST http://127.0.0.1:5125/poster \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Cyberpunk style city nightscape", "format": "png"}' \
  --output poster.png
```

---

## Quality Levels

| Level | Speed | Quality | Use Case |
|-------|-------|---------|----------|
| `low` | Fastest | Basic | Quick preview, prototype validation |
| `medium` | Fast | Standard | Daily use (default) |
| `high` | Medium | HD | Formal output |
| `ultra` | Slow | Ultra HD | High-quality requirements |
| `cinema` | Slowest | Cinema-grade | Professional production |

## Integration Examples

### Python

```python
import requests

def generate_video(prompt, quality="medium"):
    response = requests.post(
        "http://127.0.0.1:5125/video",
        json={"prompt": prompt, "quality": quality},
        stream=True
    )
    if response.status_code == 200:
        return response.content  # Video binary data
    raise Exception(f"Error: {response.status_code}")

# Usage
video_data = generate_video("Particles converging into company logo")
with open("output.mp4", "wb") as f:
    f.write(video_data)
```

### JavaScript

```javascript
async function generatePoster(prompt, format = 'png') {
  const response = await fetch('http://127.0.0.1:5125/poster', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ prompt, format })
  });

  if (!response.ok) throw new Error(`HTTP ${response.status}`);

  const blob = await response.blob();
  return blob;
}

// Usage
const poster = await generatePoster('Chinese ancient town in landscape painting style');
// Can be used as <img src={URL.createObjectURL(poster)} />
```

## CLI Startup

If UI2V is not running, start it from command line:

**Windows**:
```bash
# Foreground
"C:\Program Files\UI2V\UI2V.exe"

# Background
start "" "C:\Program Files\UI2V\UI2V.exe"
```

**macOS**:
```bash
open -a UI2V
```

**Linux**:
```bash
ui2v &
```

### Auto-Start Pattern

Before calling the API, check if UI2V is running and start if needed:

```bash
# Check and start on Windows
curl -s http://127.0.0.1:5125/video -X POST -d '{"prompt":"test"}' 2>/dev/null || start "" "C:\Program Files\UI2V\UI2V.exe"
```

```python
import subprocess
import requests
import time

def ensure_ui2v_running():
    try:
        requests.get("http://127.0.0.1:5125/", timeout=1)
    except:
        # Start UI2V on Windows
        subprocess.Popen(['C:\\Program Files\\UI2V\\UI2V.exe'])
        time.sleep(3)  # Wait for startup

ensure_ui2v_running()
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Connection refused | Start UI2V app first, or use auto-start pattern above |
| 429 Busy | Wait for current generation to complete, or cancel current task |
| Slow generation | Lower quality parameter, or reduce width/height |
| Style not applied | Verify style name is correct, use `styles:list` to query available styles |
| Video too large | Lower quality or reduce dimensions |