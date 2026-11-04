<?php
declare(strict_types=1);

/*
 * KRYPT AUDIO browser audio bridge.
 *
 * Upload this directory to the server as /api/krypt-audio (or change the
 * frontend's KRYPT_AUDIO_API_BASE build define). It requires PHP 8.1+ and
 * yt-dlp installed on the server. No API key is required.
 */

const CACHE_TTL_SECONDS = 10800;
const MAX_AUDIO_RANGE = 5242880; // 5 MiB maximum single range request.

$allowedOrigins = array_values(array_filter(array_map(
    'trim',
    explode(',', getenv('KRYPT_ALLOWED_ORIGINS') ?: 'https://krypt-audio.github.io,https://krypt-audio.github.io/KRYPT_AUDIO_SOURCE,https://synapselabs.uk,https://www.synapselabs.uk')
)));
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($origin !== '' && in_array($origin, $allowedOrigins, true)) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Vary: Origin');
} else {
    header('Access-Control-Allow-Origin: https://synapselabs.uk');
}
header('Access-Control-Allow-Methods: GET, HEAD, OPTIONS');
header('Access-Control-Allow-Headers: Range, Content-Type');
header('Access-Control-Expose-Headers: Accept-Ranges, Content-Length, Content-Range, Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$action = 'stream';
$id = trim((string)($_GET['id'] ?? ''));

if ($action === 'health') {
    respondJson(['ok' => true, 'service' => 'krypt-audio-api', 'version' => '1.0.0']);
}

if (!preg_match('/^[A-Za-z0-9_-]{6,32}$/', $id)) {
    respondJson(['error' => 'A valid YouTube video id is required.'], 400);
}

if ($action === 'resolve') {
    $resolved = resolveAudio($id, isset($_GET['live']) && $_GET['live'] === '1');
    if ($resolved === null) {
        respondJson(['error' => 'The audio stream could not be resolved.'], 502);
    }
    respondJson([
        'ok' => true,
        'id' => $id,
        'url' => apiUrl('stream', $id),
        'directUrlExpiresSoon' => true,
        'duration' => $resolved['duration'] ?? null,
        'mime' => $resolved['mime'] ?? 'audio/mp4',
    ]);
}

if ($action === 'stream') {
    streamAudio($id, isset($_GET['live']) && $_GET['live'] === '1');
}

respondJson(['error' => 'Unknown action.'], 404);

function respondJson(array $payload, int $status = 200): never {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($payload, JSON_UNESCAPED_SLASHES);
    exit;
}

function cacheDir(): string {
    $dir = __DIR__ . DIRECTORY_SEPARATOR . 'cache';
    if (!is_dir($dir)) {
        @mkdir($dir, 0750, true);
    }
    return $dir;
}

function apiUrl(string $action, string $id): string {
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $base = $scheme . '://' . ($_SERVER['HTTP_HOST'] ?? 'localhost') . ($_SERVER['SCRIPT_NAME'] ?? '/');
    return $base . '?action=' . rawurlencode($action) . '&id=' . rawurlencode($id);
}

function runYtDlp(string $id, bool $live): ?array {
    $binary = getenv('KRYPT_YTDLP_BIN') ?: 'yt-dlp';
    $format = $live ? 'best[acodec!=none]/best' : 'bestaudio[ext=m4a]/bestaudio/best';
    $url = 'https://www.youtube.com/watch?v=' . rawurlencode($id);
    $command = escapeshellcmd($binary)
        . ' --no-playlist --no-warnings --no-progress --skip-download'
        . ' --format ' . escapeshellarg($format)
        . ' --print ' . escapeshellarg('%(url)s\t%(duration)s\t%(ext)s')
        . ' ' . escapeshellarg($url) . ' 2>/dev/null';
    $output = trim((string)@shell_exec($command));
    if ($output === '') return null;
    $line = trim(explode("\n", $output)[0]);
    $parts = explode("\t", $line);
    if (count($parts) < 1 || !filter_var($parts[0], FILTER_VALIDATE_URL)) return null;
    return [
        'url' => $parts[0],
        'duration' => isset($parts[1]) && is_numeric($parts[1]) ? (float)$parts[1] : null,
        'mime' => ($parts[2] ?? '') === 'webm' ? 'audio/webm' : 'audio/mp4',
        'createdAt' => time(),
    ];
}

function resolveAudio(string $id, bool $live): ?array {
    $file = cacheDir() . DIRECTORY_SEPARATOR . hash('sha256', $id . ($live ? ':live' : ':audio')) . '.json';
    if (is_file($file) && (time() - (int)@filemtime($file)) < CACHE_TTL_SECONDS) {
        $cached = json_decode((string)@file_get_contents($file), true);
        if (is_array($cached) && filter_var($cached['url'] ?? null, FILTER_VALIDATE_URL)) return $cached;
    }
    $resolved = runYtDlp($id, $live);
    if ($resolved !== null) @file_put_contents($file, json_encode($resolved), LOCK_EX);
    return $resolved;
}

function streamAudio(string $id, bool $live): never {
    $resolved = resolveAudio($id, $live);
    if ($resolved === null) respondJson(['error' => 'Unable to resolve audio.'], 502);
    $url = $resolved['url'];
    $range = $_SERVER['HTTP_RANGE'] ?? '';
    $headers = [
        'User-Agent: KRYPT-AUDIO/2.1',
        'Accept: */*',
    ];
    if ($range !== '' && preg_match('/bytes=(\d+)-(\d*)/', $range, $match)) {
        $start = (int)$match[1];
        $end = $match[2] === '' ? $start + MAX_AUDIO_RANGE - 1 : (int)$match[2];
        $headers[] = 'Range: bytes=' . $start . '-' . min($end, $start + MAX_AUDIO_RANGE - 1);
    }
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_RETURNTRANSFER => false,
        CURLOPT_HEADER => false,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_TIMEOUT => 0,
        CURLOPT_BUFFERSIZE => 65536,
        CURLOPT_WRITEFUNCTION => static function ($ch, string $chunk): int {
            echo $chunk;
            flush();
            return strlen($chunk);
        },
        CURLOPT_HEADERFUNCTION => static function ($ch, string $header): int {
            $parts = explode(':', $header, 2);
            $name = strtolower(trim($parts[0] ?? ''));
            if (in_array($name, ['content-type', 'content-length', 'content-range', 'accept-ranges'], true)) {
                header(trim($header));
            }
            return strlen($header);
        },
    ]);
    if ($_SERVER['REQUEST_METHOD'] === 'HEAD') {
        curl_setopt($ch, CURLOPT_NOBODY, true);
    }
    $ok = curl_exec($ch);
    $status = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if ($ok === false || $status >= 400) {
        if (!headers_sent()) http_response_code(502);
        exit;
    }
    if (!headers_sent()) {
        http_response_code($status >= 200 && $status < 300 ? $status : 200);
        header('Content-Type: ' . ($resolved['mime'] ?? 'audio/mp4'));
        header('Accept-Ranges: bytes');
    }
    exit;
}
