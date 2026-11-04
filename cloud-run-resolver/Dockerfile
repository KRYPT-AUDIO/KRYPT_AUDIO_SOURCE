FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir --disable-pip-version-check yt-dlp

WORKDIR /app
COPY main.py /app/main.py

ENV PORT=8080
EXPOSE 8080
CMD ["python", "/app/main.py"]
