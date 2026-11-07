# KRYPT AUDIO PHP Web API

This API is retained as an optional future integration. The `web` branch currently builds in self-contained demo mode and does not call this service.

Upload the contents of this directory to:

```text
https://synapselabs.uk/krypt-audio/api/
```

When live web-provider mode is explicitly enabled, the client can use these endpoints:

```text
GET https://synapselabs.uk/krypt-audio/api/health.php
GET/POST/HEAD https://synapselabs.uk/krypt-audio/api/proxy.php?url=<encoded-upstream-url>
GET https://synapselabs.uk/krypt-audio/api/search.php?q=<query>&type=video
GET/HEAD https://synapselabs.uk/krypt-audio/api/stream.php?id=<youtube-video-id>
```

The proxy is intentionally allow-listed. It accepts only YouTube, YouTube image, Google Video and related media hosts. It forwards YouTube JSON/page requests and supports HTTP Range requests so browser audio playback can seek and buffer correctly.

Requirements:

- PHP 8.0 or newer.
- PHP cURL extension enabled.
- HTTPS enabled on the domain.
- `proxy.php` must be allowed to make outbound HTTPS requests.
- `stream.php` requires PHP cURL and forwards to the separately deployed Cloud Run resolver; the PHP host does not need Composer, Node, yt-dlp, or shell access.
- No PHP login or rewrite rule is required for the initial version.

## Official Google search configuration

Copy `.env.example` to `.env` on the server and set a Google Cloud key with **YouTube Data API v3** enabled:

```env
YOUTUBE_DATA_API_KEY=your_key_here
ALLOWED_ORIGIN=https://krypt-audio.github.io
```

The key is read only by `search.php` and is never sent to the browser. The current web demo uses a bundled catalog and does not call this endpoint. A future search-provider integration can use the endpoint when configured.

When `KRYPT_WEB_DEMO_MODE=false` and `KRYPT_WEB_AUDIO_API_BASE_URL` points to this API, the browser audio player uses `stream.php`, which forwards to Cloud Run and proxies an audio stream with HTTP Range support. The Data API remains for search only.

After uploading, open `health.php`. It should return JSON with `ok: true` and `curl: true`.

Do not expose arbitrary proxying by removing the host allow-list. Do not add API keys to this directory. The bridge forwards the existing public YouTube requests made by the app.
