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
- While it's working, **Send** turns into **Stop** — tap it to cancel the current run.
  Collapse, drag, Copy/Speak and quit keep working during a run.
- **Copy / Speak** the last answer, **Reset** the conversation, **▽** collapse, **✕** quit.
- **Mic** dictates into the input box (Termux:API speech recognition).
- **M** switches the model between `deepseek-flash` and `deepseek-v4-pro`.
- Answers stream in as they are generated, and the console auto-scrolls to the newest line.
- The conversation is saved to `~/.config/deepseek-bubble/history.json` and restored on the
  next launch; **Reset** clears it.

## Configuration

Everything lives in `~/.config/deepseek-bubble/config` (created on first save, `chmod 600`):

| Key | Default | Meaning |
|---|---|---|
| `DEEPSEEK_API_KEY` | — | your key (an env var of the same name wins) |
| `DEEPSEEK_MODEL` | `deepseek-flash` | model id; `deepseek-v4-pro` is the bigger one |
| `DEEPSEEK_API_URL` | `https://api.deepseek.com/chat/completions` | any OpenAI-compatible endpoint |
| `DEEPSEEK_MAX_TOKENS` | `8000` | output cap per reply |
| `DEEPSEEK_THINKING` | `off` | `off` (fast), `on`, or `default` (server decides) |
| `BASH_CONFIRM` | `0` | `1` = risky commands wait for a **Run** tap |

Only `DEEPSEEK_API_KEY` is required. Every command the model runs is appended to
`~/.config/deepseek-bubble/cmd.log` with a timestamp, whether or not `BASH_CONFIRM` is on.

Because the endpoint is configurable, the bubble also works with a local or LAN model server
(llama.cpp, vLLM, Ollama, OpenRouter, …) as long as it speaks the OpenAI chat-completions API
and supports tool calling.

## License

GPL-3.0 — see [LICENSE](LICENSE).
