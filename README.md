# ⚡ DeepSeek Bubble

A floating AI assistant for Android, running entirely in Termux. A tiny draggable
bubble sits over every app; tap it for clipboard quick‑actions (translate, summarize,
explain, fix, reply) and an **agentic chat** where DeepSeek can run shell commands on
your device to actually get things done.

## Requirements

**Three apps** — install all from the GitHub releases (*not* the Play Store builds,
which are outdated and incompatible):

- [Termux](https://github.com/termux/termux-app/releases)
- [Termux:GUI](https://github.com/termux/termux-gui/releases) — the overlay engine
- [Termux:API](https://github.com/termux/termux-api/releases) — clipboard, toast & text‑to‑speech

**Termux packages:**

```sh
pkg install termux-gui-bash jq curl termux-api
```

- `termux-gui-bash` — provides `tgui-bash`, which runs the script (required)
- `jq`, `curl` — API calls and JSON (required)
- `termux-api` — bridges to the Termux:API app for clipboard, toast, and speech

You also need a **DeepSeek API key** from <https://platform.deepseek.com>.

## Setup

1. Clone the repo:

   ```sh
   git clone https://github.com/ExTV/termux-bubble
   cd termux-bubble
   ```

2. Grant Termux:GUI the **"Display over other apps"** permission (the script opens this
   settings screen automatically if it's missing).
3. Run it:

   ```sh
   chmod +x deepseek-bubble.sh
   ./deepseek-bubble.sh
   ```

4. On first launch, paste your API key and tap **Save key**. It's stored privately at
   `~/.config/deepseek-bubble/config` (or set `DEEPSEEK_API_KEY` in the environment to
   skip this).

## Usage

- **Drag** the bubble anywhere; **tap** it to open the panel.
- **Clipboard actions** — copy text, then tap *Trans / Sum / Expl / Fix / Reply*.
- **Chat** — type a request and **Send**. The model can run bash commands on your phone
  (read files, fetch things, run programs) to complete the task.
- **Copy / Speak** the last answer, **Reset** the conversation, **▽** collapse, **✕** quit.

## License

See [LICENSE](LICENSE).
