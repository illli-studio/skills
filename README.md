# 🎬 illli-studio/skills

> Claude Code / Hermes / Codex Agent Skills Collection

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

### wechat-article-studio

**illli 风格微信公众号 AI 内容工作室**

把 AI 资讯、产品素材或 Markdown 稿件制作成微信公众号文章，支持：

- AI 周报、深度拆解、AI 工具评测模板
- 微信兼容 HTML 与桌面/移动端预览
- 亮色品牌封面、1:1 分享图和低频 GIF 动效
- 草稿箱 dry-run 与发送前确认

```text
使用 $wechat-article-studio，把这份素材制作成 illli 周报。
```

[查看完整文档 →](./wechat-article-studio/SKILL.md)

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

安装公众号文章 Skill：

```bash
cp -r illli-skills/wechat-article-studio ~/.codex/skills/wechat-article-studio
```

## 📁 项目结构

```
skills/
├── README.md
├── video-transcript/
    ├── SKILL.md                    # 主文档
    └── references/
        ├── douyin-transcript-workflow.md    # 抖音转录工作流
        ├── youtube-transcript-browser-act.md # YouTube 浏览器方案
        └── youtube-transcript-io-workaround.md # YouTube fallback
└── wechat-article-studio/
    ├── SKILL.md                    # 主文档
    ├── agents/openai.yaml
    ├── references/
    ├── templates/
    ├── scripts/
    └── assets/
```

## 🔧 依赖

- `ffmpeg` — 音频格式转换（macOS 预装）
- MiMo ASR API Key — 语音识别（可选，用于 Bilibili/抖音）

## 📄 License

MIT

---

*Built with ❤️ by [illli-studio](https://github.com/illli-studio)*
