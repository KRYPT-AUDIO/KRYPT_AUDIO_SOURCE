# syntax=docker/dockerfile:1

# Build stage: compile the Flutter Android release APK.
FROM ghcr.io/cirruslabs/flutter:3.47.7 AS builder

ARG APP_VERSION=1.0.4
ARG APP_BUILD_NUMBER=6

WORKDIR /workspace
COPY . .

# Cloud builds should never depend on a private signing key. Generate an
# ephemeral key only for this container image; production distribution should
# use the project's permanent release keystore outside this Docker build.
RUN apt-get update \
    && apt-get install -y --no-install-recommends openjdk-17-jdk-headless python3 \
    && rm -rf /var/lib/apt/lists/* \
    && export JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")" \
    && keytool -genkeypair -v \
         -keystore android/app/key.jks \
         -storepass changeit \
         -keypass changeit \
         -alias krypt-cloud-build \
         -keyalg RSA \
         -keysize 2048 \
         -validity 10000 \
         -dname "CN=KRYPT AUDIO Cloud Build, O=Synapse Labs UK Ltd, C=GB" \
    && printf '%s\n' \
         'storePassword=changeit' \
         'keyPassword=changeit' \
         'keyAlias=krypt-cloud-build' \
         'storeFile=key.jks' \
         > android/key.properties \
    && sed -i -E "s/^version: .*/version: ${APP_VERSION}+${APP_BUILD_NUMBER} # Cloud Build/" pubspec.yaml \
    && flutter pub get \
    && flutter build apk --flavor github --release

# Runtime stage: Cloud Run requires a process listening on $PORT.
FROM python:3.12-slim AS runtime

ENV PORT=8080
WORKDIR /srv

COPY --from=builder /workspace/build/app/outputs/apk/github/release/app-github-release.apk /srv/KRYPT-AUDIO.apk
COPY --from=builder /workspace/pubspec.yaml /srv/pubspec.yaml

RUN cat > /srv/server.py <<'PY'
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path('/srv')
APK = ROOT / 'KRYPT-AUDIO.apk'

try:
    version_line = next(
        line for line in (ROOT / 'pubspec.yaml').read_text().splitlines()
        if line.startswith('version:')
    )
    version = version_line.split(':', 1)[1].strip().split('#', 1)[0].strip()
except Exception:
    version = 'unknown'

class Handler(BaseHTTPRequestHandler):
    def _send(self, status, content_type, body):
        if isinstance(body, str):
            body = body.encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path in ('/', '/healthz'):
            self._send(200, 'application/json; charset=utf-8', json.dumps({
                'service': 'KRYPT AUDIO Cloud Build artifact server',
                'status': 'ok',
                'version': version,
                'apk': '/KRYPT-AUDIO.apk',
            }))
            return
        if self.path == '/metadata.json':
            self._send(200, 'application/json; charset=utf-8', json.dumps({
                'name': 'KRYPT AUDIO',
                'version': version,
                'artifact': 'KRYPT-AUDIO.apk',
                'download': '/KRYPT-AUDIO.apk',
            }))
            return
        if self.path == '/KRYPT-AUDIO.apk':
            if not APK.exists():
                self._send(404, 'text/plain; charset=utf-8', 'APK not found')
                return
            data = APK.read_bytes()
            self.send_response(200)
            self.send_header('Content-Type', 'application/vnd.android.package-archive')
            self.send_header('Content-Disposition', 'attachment; filename="KRYPT-AUDIO.apk"')
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        self._send(404, 'application/json; charset=utf-8', json.dumps({'error': 'not found'}))

    def log_message(self, format, *args):
        print('%s - - [%s] %s' % (self.address_string(), self.log_date_time_string(), format % args), flush=True)

port = int(os.environ.get('PORT', '8080'))
ThreadingHTTPServer(('0.0.0.0', port), Handler).serve_forever()
PY

EXPOSE 8080
CMD ["python3", "/srv/server.py"]
