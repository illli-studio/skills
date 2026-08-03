# 🎬 illli-studio/skills

> Claude Code / Hermes Agent Skills Collection

## 📦 Skills

### video-transcript

**从视频平台提取字幕/文案的 AI Skill**

支持 Bilibili、YouTube、抖音，自动下载音频并用 MiMo ASR 语音识别转文字。

| 平台 | 方案 | 说明 |
|------|------|------|
| **Bilibili** | Bilibili API + MiMo ASR | 直接调用内部 API 下载音频流 |
| **YouTube** | saveanyyoutube.com / yt-dlp | 多种 fallback 方案，应对反爬 |
| **抖音** | SnapAny + MiMo ASR | 绕过抖音反爬，支持短视频 |

**亮点：**
- 🎯 长视频自动分片，避免 ASR 截断
- 🔄 多平台 fallback，总有方案能用
- 🌐 代理配置支持（mihomo）
- 📝 直接发视频链接即可，无需手动操作

**安装：**
```bash
npx skills add illli-studio/skills
```

[查看完整文档 →](./video-transcript/SKILL.md)

---

## 🚀 快速开始

### 方式一：npx 一键安装
```bash
npx skills add illli-studio/skills
```

### 方式二：手动复制
```bash
cd ~/.hermes/skills/media
git clone https://github.com/illli-studio/skills.git illli-skills
cp -r illli-skills/video-transcript .
rm -rf illli-skills
```

## 📁 项目结构

```
skills/
├── README.md
└── video-transcript/
    ├── SKILL.md                    # 主文档
    └── references/
        ├── douyin-transcript-workflow.md    # 抖音转录工作流
        ├── youtube-transcript-browser-act.md # YouTube 浏览器方案
        └── youtube-transcript-io-workaround.md # YouTube fallback
```

## 🔧 依赖

- `ffmpeg` — 音频格式转换（macOS 预装）
- MiMo ASR API Key — 语音识别（可选，用于 Bilibili/抖音）

## 📄 License

MIT

---

*Built with ❤️ by [illli-studio](https://github.com/illli-studio)*
