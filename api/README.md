# KRYPT AUDIO PHP Web API

Upload the contents of this directory to:

```text
https://synapselabs.uk/krypt-audio/api/
```

The frontend expects these endpoints:

```text
GET https://synapselabs.uk/krypt-audio/api/health.php
GET/POST/HEAD https://synapselabs.uk/krypt-audio/api/proxy.php?url=<encoded-upstream-url>
GET https://synapselabs.uk/krypt-audio/api/search.php?q=<query>&type=video
```

The proxy is intentionally allow-listed. It accepts only YouTube, YouTube image, Google Video and related media hosts. It forwards YouTube JSON/page requests and supports HTTP Range requests so browser audio playback can seek and buffer correctly.

Requirements:

- PHP 8.0 or newer.
- PHP cURL extension enabled.
- HTTPS enabled on the domain.
- `proxy.php` must be allowed to make outbound HTTPS requests.
- No PHP login or rewrite rule is required for the initial version.

## Official Google search configuration

Copy `.env.example` to `.env` on the server and set a Google Cloud key with **YouTube Data API v3** enabled:

```env
YOUTUBE_DATA_API_KEY=your_key_here
ALLOWED_ORIGIN=https://krypt-audio.github.io
```

The key is read only by `search.php` and is never sent to the browser. The Web app uses this endpoint for official video, playlist and channel search when the key is configured. If the key is not configured, it falls back to the existing KRYPT API bridge.

Official YouTube Web playback uses the YouTube iframe player with the returned video ID. The Data API does not expose audio-only stream URLs.

After uploading, open `health.php`. It should return JSON with `ok: true` and `curl: true`.

Do not expose arbitrary proxying by removing the host allow-list. Do not add API keys to this directory. The bridge forwards the existing public YouTube requests made by the app.
