# KRYPT AUDIO PHP audio API

This directory is the server-side browser audio bridge for KRYPT AUDIO. Upload it to the Synapse Labs host, for example:

```text
public_html/api/krypt-audio/index.php
public_html/api/krypt-audio/.htaccess
```

The server must provide PHP 8.1+, cURL, and `yt-dlp` on the PATH. If `yt-dlp` is installed somewhere else, set `KRYPT_YTDLP_BIN` in the hosting environment. The API does not store credentials or require a billable cloud service.

Health check:

```text
GET https://synapselabs.uk/api/krypt-audio/?action=health
```

Resolve a track:

```text
GET https://synapselabs.uk/api/krypt-audio/?action=resolve&id=VIDEO_ID
```

The browser player uses the range-capable proxy endpoint:

```text
GET https://synapselabs.uk/api/krypt-audio/?action=stream&id=VIDEO_ID
```

The cache directory is created automatically and stores only short-lived stream metadata. Do not make `php-api/cache` publicly browseable. Configure `KRYPT_ALLOWED_ORIGINS` if the web app is hosted on a different origin.

This endpoint is intended for tracks the user is permitted to access. Respect the source platform’s terms, copyright, rate limits, and applicable law. Do not expose `yt-dlp` command execution as a user-controlled parameter.
