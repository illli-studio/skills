# Narrative Short-Film Workflow

This production workflow is adapted from MiniMax AI's official [3D Animation Short Generator](https://github.com/MiniMax-AI/MiniMax-H3/tree/main/skills/3d-animation-short-generator). Its story-first sequence, continuity planning, per-shot timing, storyboard-first generation, and final quality checks are retained. MiniMax Hub canvas nodes, choice cards, image/video Hub tools, fixed Pixar-style requirements, and Seedance fallback are Hub-specific and are not assumed here. This version uses ordinary chat/files and the configured H3 video API.

## 1. Scope and brief

Use this workflow when the user wants a story-led short with multiple shots. First establish the requested deliverable: story plan, production package, video clips, or an assembled film. Do not expand a single-clip request into a full production.

Capture or infer from the brief:

- Working title and one-line premise / “what if”.
- Format and target total runtime.
- Aspect ratio or output size.
- Genre, tone, visual style, and audience feeling.
- Protagonist, want/need, core conflict, world rule, and emotional payoff.
- Dialogue / narration preference and language. Preserve user-supplied lines exactly; do not invent a dialogue language when it matters.
- Required references and things that must stay consistent.
- Desired outputs: outline, script, character/location sheets, shot plan, prompts, generated clips, or assembly.

Ask only for missing choices that materially change the film. Otherwise state reasonable assumptions briefly and proceed. Do not impose the official skill's default stylized 3D look; follow the user's style, and suggest a style only when none is implied.

## 2. Story plan

Write a concise project brief with the premise, emotional center, target audience feeling, runtime, aspect ratio, dialogue mode, deliverables, and known risks. Then draft a causal story spine. For short runtimes, compress the beats rather than adding scenes solely to hit a fixed count. An eight-beat structure is a useful option:

1. Opening image / hook.
2. Protagonist's ordinary situation and want.
3. Inciting disruption.
4. First attempt and complication.
5. Escalation / pressure.
6. Crisis and decisive action.
7. Climax / choice.
8. Resolution that pays off an earlier image, prop, or emotional anchor.

Check that the protagonist acts, the conflict escalates causally, coincidence does not solve the central problem, and the ending pays off something planted earlier. Dialogue should reveal action or relationship; it should not explain the theme. Match story complexity to runtime.

Present the story plan for review before committing to detailed production when the user has not already approved a script or outline. Preserve the user's requested changes and the latest approved version as the source of truth.

## 3. Continuity bible and visual references

Before shot prompts, establish stable identifiers and concise visual anchors for each recurring character, location, and important prop. Record identity traits that must not drift: age range, face/hair, silhouette, costume, color palette, signature props, and relevant movement traits. For each location, record fixed landmarks, layout, screen-relative positions, and the lighting baseline. Keep character and environment reference images free of extra labels if they will be fed into video generation; put names and notes in the written bible.

If reference images are requested, create or request character/location reference images with available image tools. If no image tool is available or the user only needs planning, return image prompts instead. Do not imply the configured video endpoint generated reference cards.

## 4. Shot plan

Divide the runtime into shots that each have one clear dramatic purpose and a manageable action. Prefer one main subject action, one camera behavior, and one important environmental motion per clip. Use varied framing only when it advances the story. Each shot should specify:

| Column | What to record |
|---|---|
| Shot ID & Duration | Ordered ID and clip duration, e.g. `S03 / 6s` |
| Continuity Handoff | Opening state inherited from the prior shot and ending state that leads to the next |
| Reference Anchors | Exact character/location IDs, positions, eyelines, prop state, landmarks, and lighting |
| Story Beat | Hook, reveal, reversal, suspense, tenderness, chase, callback, or other story function |
| Shot Description / Timed Actions | Framing, camera, action, pose, expression, and timed progression |
| Audio & Dialogue | Dialogue, narration, sound effects, ambience, music intent, or intentional silence with timing |

For action-heavy shots, state the progression in one-second intervals (use sub-second marks only for a critical beat). Each interval should say what changes in the action or expression, how the camera behaves, where the subject/prop is, what is heard, and what state carries forward. All intervals must cover the full clip without gaps.

Use individual video clips for each shot. Plan most clips at 5–15 seconds; split complex beats rather than packing a whole short into one prompt. This API accepts a per-clip duration of 1–30 seconds, so a longer total film is a sequence of clip requests. Make shot durations sum to the approved total runtime, including any planned transitions. Mark first-frame and last-frame image anchors explicitly when available.

Before moving from shot planning to clip requests, check:

- Shot durations sum to the intended total runtime.
- Every shot has a story purpose, timed actions, camera, audio intent, and continuity handoff.
- Character count and action complexity are manageable for each clip.
- Repeated characters, props, screen direction, eyeline, positions, landmarks, and lighting remain consistent or have explicit transitions.
- The opening establishes the film and the ending resolves/payoffs its central emotional anchor.

Show the user the shot plan and a text storyboard (one section per shot) before a batch of paid generation if the user has not already approved a complete shot package. Text storyboard is the default. Generate visual storyboard panels only when requested or useful for a specific high-risk shot; they are for review and must never appear in the final clip.

## 5. Compile each shot for the H3 video API

For every approved shot, produce a clean model prompt from its storyboard section, exact character/location anchors, and audio intent. Keep internal production notes and storyboard labels out of the submitted visual prompt. Use the relevant T2VA/I2VA/FL2VA/L2VA/Ref2VA structure from `h3-prompt-format.md`.

Put `[duration:N]` at the very beginning of the `prompt` for every API request, where `N` is that shot's duration in seconds. Do not put the project's total runtime in each individual request. Send image anchors in the user-intended order: one image for the first frame, or two for first and last frames. Reuse stable character/location references where they help. Do not invent a model-switch fallback: use the configured H3 video backend unless the user asks to use another available tool.

Before starting an unapproved generation batch, state how many clips will be submitted and the planned duration/size for each; get the user's go-ahead because these are external generation requests that can incur cost. If the user explicitly asks for the finished short and approves the production plan, proceed with the approved batch. Set at least a five-minute request timeout, wait on each pending request, and do not resend a still-pending job.

Track each result by shot ID and URL. Review the returned clip against its shot purpose, anchors, framing, action, timing, and audible content. If it drifts, make a targeted prompt correction or simplify/split that shot. Do not silently replace an approved asset with a stale version or mix unreviewed clips into the final sequence.

## 6. Assembly and final review

When the user wants a finished film and local media tools are available, assemble the latest approved clips in shot order, using the planned cuts/transitions and total runtime. Preserve useful generated clip audio unless replacement is requested. Plan one continuous music bed across the whole film rather than separate unrelated music per shot; keep it below dialogue and important effects. Do not add subtitles, title cards, or on-screen text unless requested. If no usable assembly/audio tool is available, provide an edit decision list with clip order, in/out points, transition notes, and music/SFX cues instead of claiming to have rendered a final composite.

Final review checklist:

- Shot order, runtime, and transitions follow the approved plan.
- Character identity, costume, prop state, geography, eyeline, and lighting are coherent across cuts.
- Each shot has a clear dramatic purpose and action is readable.
- Dialogue and key effects are intelligible and synchronized; music does not mask them.
- No storyboard marks, planning labels, generation artifacts, or unintended text remain in the final image.
- Ending pays off the established emotional anchor.

Deliver the finished file when actually rendered; otherwise clearly label the production package or edit plan as such.
