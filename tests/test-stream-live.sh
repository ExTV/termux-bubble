#!/data/data/com.termux/files/usr/bin/bash
# Live test of api_stream_post against a local mock SSE endpoint (no real API).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="${1:-$HERE/../deepseek-bubble.sh}"
PORT=8899
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/livesstest.XXXXXX")"
SRV_PID=""
cleanup() { [ -n "$SRV_PID" ] && kill "$SRV_PID" 2>/dev/null; rm -rf "$TMP_DIR"; }
trap cleanup EXIT

cat >"$TMP_DIR/server.py" <<'PY'
import http.server, json, time, sys
DELAY = 0.12
class H(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    def log_message(self, *a): pass
    def do_POST(self):
        n = int(self.headers.get('Content-Length') or 0)
        body = self.rfile.read(n)
        try: req = json.loads(body)
        except Exception: req = {}
        if not req.get("stream"):
            out = json.dumps({"choices":[{"message":{"role":"assistant","content":"NONSTREAM"}}]}).encode()
            self.send_response(200); self.send_header("Content-Type","application/json")
            self.send_header("Content-Length", str(len(out))); self.end_headers()
            self.wfile.write(out); return
        self.send_response(200)
        self.send_header("Content-Type","text/event-stream")
        self.send_header("Cache-Control","no-cache")
        self.send_header("Connection","close")
        self.end_headers()
        def sse(obj):
            self.wfile.write(("data: " + json.dumps(obj) + "\n\n").encode()); self.wfile.flush()
        for piece in ["Hello", " from", " the", " mock", " server"]:
            sse({"choices":[{"delta":{"content":piece},"finish_reason":None}]})
            time.sleep(DELAY)
        sse({"choices":[{"delta":{},"finish_reason":"stop"}]})
        self.wfile.write(b"data: [DONE]\n\n"); self.wfile.flush()

http.server.ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
PY
python3 "$TMP_DIR/server.py" "$PORT" & SRV_PID=$!
sleep 1.5

API_URL="http://127.0.0.1:$PORT/v1/chat/completions"
API_KEY="test"
aid=0; answer=0; TRANSCRIPT_PRE=""
CANCEL=0; BUSY=1
renders=0; last_render=""
tg_view_text() { renders=$((renders+1)); last_render="$3"; }
scroll_bottom() { :; }
busy_pump() { :; }
send_btn=0

awk '/^# BEGIN STREAM BLOCK/{f=1} f{print} /^# END STREAM BLOCK/{f=0}' "$SCRIPT" >"$TMP_DIR/block.sh"
[ -s "$TMP_DIR/block.sh" ] || { echo "FAIL: stream block not found"; exit 1; }
# shellcheck disable=SC1090
source "$TMP_DIR/block.sh"

fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2] want [$3]"; fail=1; fi; }

BODY='{"model":"test","messages":[{"role":"user","content":"hi"}],"stream":true}'
POST_T0=0; POST_LASTT=0
api_stream_post "$BODY"; rc=$?
check "return code" "$rc" "0"
check "http code" "$HTTP_CODE" "200"
check "final text" "$STREAM_TEXT" "Hello from the mock server"
check "assembled message" "$(jq -r '.content' <<<"$STREAM_MSG")" "Hello from the mock server"
if [ "$renders" -ge 3 ]; then echo "ok   progressive renders ($renders renders)"; else echo "FAIL progressive renders: only $renders"; fail=1; fi
check "last render is complete" "$last_render" "Hello from the mock server"

# non-streaming fallback: server returns a plain JSON object
BODY2='{"model":"test","messages":[{"role":"user","content":"hi"}]}'
api_stream_post "$BODY2"; rc=$?
check "fallback rc" "$rc" "0"
check "fallback not sse" "$(stream_is_sse && echo yes || echo no)" "no"
check "fallback body" "$(jq -r '.choices[0].message.content' <<<"$API_RESP")" "NONSTREAM"

exit $fail
