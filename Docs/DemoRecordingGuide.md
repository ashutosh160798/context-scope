# Demo Recording Guide

This guide explains how to capture a compelling 30-second screen recording of ContextScope's Context Pressure River animation for use in README screenshots, the project website, and launch posts.

---

## Prerequisites

- ContextScope built and running locally (see `CONTRIBUTING.md` — Development Setup)
- macOS Screen Recording permission granted to QuickTime Player or your capture tool
- Display resolution: 2560x1600 or 1920x1200 recommended for crisp screenshots

---

## Setup (do once)

1. Build and launch the app: `open App/ContextScopeApp/ContextScopeApp.xcworkspace` then Run
2. Click **Play Demo** on the welcome screen
3. Select the **Bloated Context** scenario — it produces the most visually striking river with high pressure warnings

---

## Recording the Context Pressure River (30-second clip)

1. Open QuickTime Player > File > New Screen Recording
2. Select the ContextScope window only (not full screen)
3. Start recording
4. On the welcome screen, click **Play Demo** > **Bloated Context**
5. Watch the river animate for ~25 seconds — the pressure warnings should fire automatically
6. Stop recording

**What to capture:**
- The river filling from left as context items stream in
- Color-coded lanes (blue = system prompt, orange = tool definitions dominating)
- The yellow (85%) and red (95%) pressure threshold lines activating
- The warning badge appearing in the sidebar

---

## Capturing a Static Screenshot

For the README hero image:

1. Pause Demo Mode at the moment of peak pressure (when the red 95% line activates)
2. Press Cmd+Shift+4 then Space to capture the window
3. Save to `Docs/screenshots/context-river-peak-pressure.png`

---

## Post-processing

- Trim the clip to 30 seconds or less
- Convert to GIF with `ffmpeg` for inline README use:

```bash
ffmpeg -i demo.mov -vf "fps=12,scale=1200:-1:flags=lanczos" -loop 0 demo.gif
```

- Aim for under 3 MB GIF for fast loading on GitHub

---

## Checklist before publishing

- [ ] No real API keys or credentials visible in any frame
- [ ] No real user data visible — Demo Mode uses only fictional content
- [ ] No third-party copyrighted content in any visible text
