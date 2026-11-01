# KRYPT AUDIO PHP Web API

Upload the contents of this directory to:

```text
https://synapselabs.uk/krypt-audio/api/
```

The frontend expects these endpoints:

```text
GET https://synapselabs.uk/krypt-audio/api/health.php
GET/POST/HEAD https://synapselabs.uk/krypt-audio/api/proxy.php?url=<encoded-upstream-url>
```

The proxy is intentionally allow-listed. It accepts only YouTube, YouTube image, Google Video and related media hosts. It forwards YouTube JSON/page requests and supports HTTP Range requests so browser audio playback can seek and buffer correctly.

Requirements:

- PHP 8.0 or newer.
- PHP cURL extension enabled.
- HTTPS enabled on the domain.
- `proxy.php` must be allowed to make outbound HTTPS requests.
- No PHP login or rewrite rule is required for the initial version.

After uploading, open `health.php`. It should return JSON with `ok: true` and `curl: true`.

Do not expose arbitrary proxying by removing the host allow-list. Do not add API keys to this directory. The bridge forwards the existing public YouTube requests made by the app.
