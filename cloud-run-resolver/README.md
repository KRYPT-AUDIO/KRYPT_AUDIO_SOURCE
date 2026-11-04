# KRYPT AUDIO Cloud Run resolver

This service is the workaround for pure-PHP hosting. The shared PHP host does not install Composer, Node, or yt-dlp; Cloud Run runs the resolver container and the PHP API forwards browser audio requests to it.

The service is designed for the existing Google Cloud project `krypt-audio-main` (the project display name may be KRYPT-AUDIO-ANDROID). It uses no Google AI service or Composer. Cloud Run charges are subject to Google Cloud free allowances and the project billing configuration.

## Deploy from Google Cloud Shell

```bash
gcloud config set project krypt-audio-main
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com
export KRYPT_RESOLVER_TOKEN="replace-with-a-long-random-token"
gcloud run deploy krypt-audio-resolver \
  --source . \
  --project krypt-audio-main \
  --region europe-west2 \
  --allow-unauthenticated \
  --set-env-vars KRYPT_RESOLVER_TOKEN="$KRYPT_RESOLVER_TOKEN"
```

Copy the deployed Cloud Run URL into the PHP host environment as `KRYPT_RESOLVER_URL`, and set the same value for `KRYPT_RESOLVER_TOKEN`. The PHP API sends the token in `X-Krypt-Resolver-Token`, so the resolver is not an unauthenticated open proxy even though Cloud Run accepts the request at the network layer.

Endpoints:

```text
GET /health
GET /resolve?id=VIDEO_ID
GET /stream?id=VIDEO_ID
```

`/stream` supports GET, HEAD and HTTP Range forwarding. The service resolves short-lived provider URLs in memory and never exposes yt-dlp command parameters to callers.
