---
name: h3-video
description: Develop a narrative short film from idea to shot plan, then write prompts and generate individual clips with the configured H3 video API. Use for short-film development, storyboards, continuity planning, or multi-shot H3 video production; use a single-clip workflow for standalone clips.
---

# H3 Video and Short-Film Production

This skill combines MiniMax H3 prompt writing with an adapted story-first short-film workflow. For a full short, read [references/short-film-workflow.md](references/short-film-workflow.md). For a single clip or prompt-only request, follow the prompt-writing and API guidance below without expanding it into a film pipeline.

## H3 prompt writing

1. Identify the input mode: T2VA (text), I2VA (first-frame image), FL2VA (first and last frames), L2VA (last-frame image), or full-reference Ref2VA.
2. Read `references/h3-prompt-format.md` and use its mode-specific structure.
4. Preserve the guide's section order, reference labels, and timing notation. Write prompt sections in English while preserving user-provided dialogue, lyrics, and visible text in their original language.
5. Describe concrete composition, subjects, location, actions, camera, and sound. For keyframes, explain how the scene starts from and/or lands on the supplied frame.

## Configured H3 video API

- Endpoint: `https://new.huajunshi.com/v1/images/generations`
- Model: `huajunshi-h3`
- Authenticate with `Authorization: Bearer <API_KEY>`. Read the key from a secure user-provided secret or environment variable such as `HUAJUNSHI_API_KEY`; never write it into this skill, source files, logs, or prompts.
- The body requires `model` and `prompt`. Supported options: `size` (e.g. `1280x720`, automatically aligned to multiples of 32), `megapixels` (0.1–16 when `size` is omitted), `aspect_ratio` (`1:1`, `2:3`, `3:2`, `3:4`, `4:3`, `9:16`, `16:9`, `21:9`), and reference images.
- **Put the duration tag at the very beginning of `prompt`**, e.g. `[duration:5]`. Valid duration is 1–30 seconds; default is 10 and 5–15 is recommended. Do not rely on a separate `duration` or `seconds` body field for this new-api. Keep the tag in the submitted prompt; do not claim the server stripped it unless that is verified.
- One image is the first frame; two images are the first and last frames. Image input supports repeated `images` fields, a base64 array, or an `image` field. Preserve order and use the selected client's accepted encoding.
- Example body:

  ```json
  {
    "model": "huajunshi-h3",
    "prompt": "[duration:5] A continuous cinematic shot of a red apple rotating slowly on a white studio surface.",
    "size": "1280x720"
  }
  ```

- Generation can take several minutes. Set a request timeout of at least 5 minutes and wait on the same request while it is pending. Do not submit duplicate generation requests because the response is still empty. On success, report the status and return `data[0].url`; if it times out, report that and do not retry automatically.
- Do not assume support for unlisted provider-specific parameters or separate audio generation. If a parameter or image encoding is rejected, use the response to guide a specific correction.
