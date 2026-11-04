from __future__ import annotations

import json
import os
import re
import subprocess
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any
from urllib.parse import parse_qs, urlencode, urlparse
from urllib.request import Request, urlopen

VIDEO_ID = re.compile(r"^[A-Za-z0-9_-]{6,32}$")
PORT = int(os.environ.get("PORT", "8080"))
TOKEN = os.environ.get("KRYPT_RESOLVER_TOKEN", "")
CACHE_TTL = int(os.environ.get("KRYPT_RESOLVER_CACHE_TTL", "7200"))
cache: dict[str, tuple[float, dict[str, Any]]] = {}


def json_bytes(payload: dict[str, Any]) -> bytes:
    return json.dumps(payload, separators=(",", ":")).encode("utf-8")


def resolve(video_id: str, live: bool) -> dict[str, Any] | None:
    key = f"{video_id}:{int(live)}"
    cached = cache.get(key)
    if cached and time.time() - cached[0] < CACHE_TTL:
        return cached[1]

    fmt = "best[acodec!=none]/best" if live else "bestaudio[ext=m4a]/bestaudio/best"
    command = [
        "yt-dlp", "--no-playlist", "--no-warnings", "--no-progress",
        "--skip-download", "--format", fmt,
        "--print", "%(url)s\\t%(duration)s\\t%(ext)s",
        f"https://www.youtube.com/watch?v={video_id}",
    ]
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=45, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0 or not result.stdout.strip():
        return None
    parts = result.stdout.strip().splitlines()[0].split("\t")
    if not parts or not parts[0].startswith(("http://", "https://")):
        return None
    item = {
        "url": parts[0],
        "duration": float(parts[1]) if len(parts) > 1 and parts[1].replace(".", "", 1).isdigit() else None,
        "mime": "audio/webm" if len(parts) > 2 and parts[2] == "webm" else "audio/mp4",
    }
    cache[key] = (time.time(), item)
    return item


class Handler(BaseHTTPRequestHandler):
    server_version = "KRYPT-AUDIO-Resolver/1.0"

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Range, X-Krypt-Resolver-Token")
        self.end_headers()

    def do_HEAD(self) -> None:
        self.handle_request(False)

    def do_GET(self) -> None:
        self.handle_request(True)

    def handle_request(self, include_body: bool) -> None:
        parsed = urlparse(self.path)
        query = parse_qs(parsed.query)
        if parsed.path == "/health":
            self.write_json({"ok": True, "service": "krypt-audio-resolver", "version": "1.0.0"}, include_body)
            return
        if TOKEN and self.headers.get("X-Krypt-Resolver-Token", "") != TOKEN:
            self.write_json({"error": "Unauthorized"}, include_body, 401)
            return
        if parsed.path not in ("/resolve", "/stream"):
            self.write_json({"error": "Not found"}, include_body, 404)
            return
        video_id = query.get("id", [""])[0].strip()
        if not VIDEO_ID.fullmatch(video_id):
            self.write_json({"error": "A valid YouTube video id is required"}, include_body, 400)
            return
        live = query.get("live", ["0"])[0] == "1"
        resolved = resolve(video_id, live)
        if resolved is None:
            self.write_json({"error": "Unable to resolve audio"}, include_body, 502)
            return
        if parsed.path == "/resolve":
            self.write_json({"ok": True, "id": video_id, **resolved}, include_body)
            return
        self.proxy_audio(resolved, include_body)

    def proxy_audio(self, resolved: dict[str, Any], include_body: bool) -> None:
        headers = {"User-Agent": "KRYPT-AUDIO/2.1", "Accept": "*/*"}
        if self.headers.get("Range"):
            headers["Range"] = self.headers["Range"]
        request = Request(resolved["url"], headers=headers, method="GET" if include_body else "HEAD")
        try:
            with urlopen(request, timeout=45) as upstream:
                status = getattr(upstream, "status", 200)
                self.send_response(status)
                self.send_header("Content-Type", upstream.headers.get("Content-Type", resolved["mime"]))
                for name in ("Content-Length", "Content-Range", "Accept-Ranges", "ETag", "Last-Modified"):
                    value = upstream.headers.get(name)
                    if value:
                        self.send_header(name, value)
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                if include_body:
                    while True:
                        chunk = upstream.read(65536)
                        if not chunk:
                            break
                        self.wfile.write(chunk)
                        self.wfile.flush()
        except Exception:
            if not self.wfile.closed:
                self.send_error(502, "Upstream audio request failed")

    def write_json(self, payload: dict[str, Any], include_body: bool, status: int = 200) -> None:
        body = json_bytes(payload)
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        if include_body:
            self.wfile.write(body)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
