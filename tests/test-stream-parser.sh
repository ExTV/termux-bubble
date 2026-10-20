#!/data/data/com.termux/files/usr/bin/bash
# Offline test for the SSE parser block in deepseek-bubble.sh (no network).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="${1:-$HERE/../deepseek-bubble.sh}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/streamtest.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT
aid=0; answer=0; TRANSCRIPT_PRE="PRE|"
rendered=""
tg_view_text() { rendered="$3"; }
scroll_bottom() { :; }

awk '/^# BEGIN STREAM BLOCK/{f=1} f{print} /^# END STREAM BLOCK/{f=0}' "$SCRIPT" >"$TMP_DIR/block.sh"
[ -s "$TMP_DIR/block.sh" ] || { echo "FAIL: stream block not found"; exit 1; }
# shellcheck disable=SC1090
source "$TMP_DIR/block.sh"

fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2] want [$3]"; fail=1; fi; }

# ── fixture 1: plain content stream, delivered in bursts ────────────────────
stream_reset
printf '%s\n' \
 'data: {"choices":[{"delta":{"role":"assistant","content":""},"finish_reason":null}]}' \
 '' \
 'data: {"choices":[{"delta":{"content":"Hello"},"finish_reason":null}]}' \
 '' >>"$STREAM_FILE"
stream_pump 1
check "partial text" "$STREAM_TEXT" "Hello"
check "render uses prefix" "$rendered" "PRE|Hello"
printf '%s\n' \
 'data: {"choices":[{"delta":{"content":", world"},"finish_reason":null}]}' \
 '' \
 'data: {"choices":[{"delta":{},"finish_reason":"stop"}]}' \
 '' \
 'data: [DONE]' >>"$STREAM_FILE"
stream_pump 1
check "full text" "$STREAM_TEXT" "Hello, world"
check "render after burst" "$rendered" "PRE|Hello, world"
check "is sse" "$(stream_is_sse && echo yes || echo no)" "yes"
check "finalize content" "$(stream_finalize | jq -c .)" '{"role":"assistant","content":"Hello, world"}'

# ── fixture 2: incremental tool_calls ───────────────────────────────────────
stream_reset
printf '%s\n' \
 'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"run_bash","arguments":""}}]},"finish_reason":null}]}' \
 '' \
 'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\"comm"}}]},"finish_reason":null}]}' \
 '' \
 'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"and\":\"pwd\"}"}}]},"finish_reason":null}]}' \
 '' \
 'data: {"choices":[{"delta":{},"finish_reason":"tool_calls"}]}' \
 '' \
 'data: [DONE]' >>"$STREAM_FILE"
stream_pump 0
check "tool count" "$STREAM_TOOLS" "1"
check "tool message" "$(stream_finalize | jq -c .)" \
 '{"role":"assistant","tool_calls":[{"id":"call_1","type":"function","function":{"name":"run_bash","arguments":"{\"command\":\"pwd\"}"}}]}'
check "args reparse" "$(stream_finalize | jq -r '.tool_calls[0].function.arguments | fromjson | .command')" "pwd"

# ── fixture 3: two interleaved tool calls, no content ───────────────────────
stream_reset
printf '%s\n' \
 'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"a","type":"function","function":{"name":"run_bash","arguments":"{\"command\":\"ls\"}"}},{"index":1,"id":"b","type":"function","function":{"name":"run_bash","arguments":"{\"command\":\"df\"}"}}]},"finish_reason":"tool_calls"}]}' \
 '' \
 'data: [DONE]' >>"$STREAM_FILE"
stream_pump 0
check "two tools" "$(stream_finalize | jq -r '.tool_calls | length')" "2"
check "tool order" "$(stream_finalize | jq -r '[.tool_calls[].id] | join(",")')" "a,b"
check "no content key when empty" "$(stream_finalize | jq -r 'has("content")')" "false"

# ── fixture 4: non-SSE body must be detected ────────────────────────────────
stream_reset
printf '%s' '{"choices":[{"message":{"content":"plain"}}]}' >"$STREAM_FILE"
check "plain json is not sse" "$(stream_is_sse && echo yes || echo no)" "no"

# ── fixture 5: repeated pumps must not duplicate text ───────────────────────
stream_reset
printf '%s\n' 'data: {"choices":[{"delta":{"content":"abc"},"finish_reason":null}]}' '' >>"$STREAM_FILE"
stream_pump 0; stream_pump 0; stream_pump 0
check "idempotent pump" "$STREAM_TEXT" "abc"

exit $fail
