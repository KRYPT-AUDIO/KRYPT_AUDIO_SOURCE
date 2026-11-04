# KRYPT AUDIO Cloud Run audio workaround

The shared `synapselabs.uk` plan remains pure PHP. It does not need Composer, Node, yt-dlp, or shell access. `api/stream.php` forwards the browser request to the Cloud Run resolver in `cloud-run-resolver/`, forwarding HTTP Range headers so browser seeking and buffering work.

Deploy the resolver from Google Cloud Shell using the instructions in [`cloud-run-resolver/README.md`](cloud-run-resolver/README.md), using the existing project `krypt-audio-main`. Set a long random `KRYPT_RESOLVER_TOKEN` on Cloud Run. Set the same token plus the deployed URL in the PHP host `.env` using [`api/.env.example`](api/.env.example).

The browser app continues to call `https://synapselabs.uk/krypt-audio/api/stream.php?id=...`; no Cloud Run URL or token is exposed in the frontend. Android remains unchanged and continues to use its native resolver.

Cloud Run is a Google Cloud service and may incur charges beyond the free allowance. Monitor the project billing budget and set an alert before enabling production traffic.
