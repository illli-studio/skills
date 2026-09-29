# H3 Video Prompt Format

Use this as a compact working guide for H3's five video modes. The field names below are part of the model's prompt interface; shape their contents to the scene rather than copying a stock example.

## Text and keyframe modes

- **T2VA (text to video):** Build a complete audiovisual timeline using three sections, in this order: `integrated_multimodal_description`, `overall_soundscape`, `non_diegetic_music`.
- **I2VA (first frame):** Begin with a short instruction binding the supplied picture to time 0. Then describe how the scene develops from the composition, identity, and layout in that image.
- **FL2VA (first and last frames):** Begin by mapping the first picture to 0 seconds and the last picture to the end of the clip. Describe a continuous, plausible path that reaches the final image; do not treat them as two unrelated stills.
- **L2VA (last frame):** Begin by mapping the supplied picture to the clip's end time. Infer a compatible earlier state and guide the scene toward the ending frame.

For the keyframe modes, follow the frame-binding instruction with the same three core sections as T2VA. Keep each cut timestamp increasing and inside the requested runtime. Identify shots as `[Shot 1]`, `[Shot 2]`, and so on; explain camera motion as an action with a clear direction and pace. Maintain stable character IDs for speakers, put only spoken words inside `<d>...</d>`, and preserve user-supplied dialogue and visible text verbatim. Describe concrete ambience and physical sounds in `overall_soundscape`; use `non_diegetic_music` for audience-only score, or `N/A` if none is wanted.

## Full-reference mode (Ref2VA)

Use six sections in this order:

1. `subject_definitions` — define each reusable person, setting, visual source, or audio source and give it one stable label.
2. `summary` — state the task type and how the references relate to the target.
3. `retention_analysis` — say where each reference appears and what is preserved, changed, transferred, or only used loosely.
4. `detailed_description` — describe each shot in playback order with composition, identity, environment, action, camera, sound, and reference timing.
5. `overall_soundscape` — summarize ambience and physical sounds.
6. `non_diegetic_music` — describe audience-only music, or `N/A`.

Keep labels such as `<Subject 1>`, `<Picture 1>`, `<Video 1>`, and `<Audio 1>` stable across all sections. Use a picture label as a standalone entry when it anchors a frame or composition; when it only supplies a character's appearance, cite it in that subject's definition. Do not introduce undefined labels or imply that a source video is directly edited when it only provides visual guidance.

## Prompt checks

- Make the described timeline fit the requested clip duration.
- State what the first and last frame should look like when anchors are supplied.
- Prefer visible, filmable actions and specific camera behavior over abstract mood words.
- Keep descriptions in English, except user-supplied dialogue, lyrics, and visible scene text, which remain in their original language.
- For this skill's API workflow, prefix the submitted prompt with `[duration:N]`; this tag belongs before any mode-specific text.

The official source skills are available from [MiniMax-AI/MiniMax-H3](https://github.com/MiniMax-AI/MiniMax-H3/tree/main/skills/h3-prompt-writing); this file is an original concise operational summary.
