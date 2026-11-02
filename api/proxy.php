<?php
/**
 * KRYPT AUDIO Web API bridge
 *
 * Upload this file to: https://synapselabs.uk/krypt-audio/api/proxy.php
 * Requires PHP 8.0+ with the cURL extension enabled.
 *
 * This is intentionally an allow-listed proxy, not an open proxy. It forwards
 * only YouTube API/pages, YouTube image hosts, and Google Video media URLs.
 * It supports JSON requests and HTTP Range requests used by web audio players.
 */
declare(strict_types=1);

const MAX_TARGET_URL_LENGTH = 8192;
const CONNECT_TIMEOUT_SECONDS = 15;
const REQUEST_TIMEOUT_SECONDS = 90;

function cors(): void {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, HEAD, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Range, Accept, Origin, Referer, User-Agent, X-Youtube-Client-Name, X-Youtube-Client-Version');
    header('Access-Control-Expose-Headers: Content-Length, Content-Range, Accept-Ranges, Content-Type, ETag, Last-Modified');
    header('Vary: Origin');
}

function fail(int $status, string $message): never {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['error' => $message], JSON_UNESCAPED_SLASHES);
    exit;
}

function targetUrl(): string {
    $value = $_GET['url'] ?? '';
    if (!is_string($value) || $value === '' || strlen($value) > MAX_TARGET_URL_LENGTH) {
        fail(400, 'A valid url query parameter is required.');
    }
    if (!filter_var($value, FILTER_VALIDATE_URL)) {
        fail(400, 'The target URL is invalid.');
    }
    return $value;
}

function allowedHost(string $host): bool {
    $host = strtolower(rtrim($host, '.'));
    $allowed = [
        'youtube.com', 'www.youtube.com', 'm.youtube.com', 'music.youtube.com',
        'youtube-nocookie.com', 'www.youtube-nocookie.com',
        'googlevideo.com', 'rr*.googlevideo.com',
        'ytimg.com', 'i.ytimg.com', 's.ytimg.com',
        'ggpht.com', 'yt3.ggpht.com', 'googleusercontent.com',
    ];
    foreach ($allowed as $suffix) {
        if (str_starts_with($suffix, 'rr*.')) {
            if (str_ends_with($host, substr($suffix, 3))) return true;
        } elseif ($host === $suffix || str_ends_with($host, '.' . $suffix)) {
            return true;
        }
    }
    return false;
}

function requestHeaders(): array {
    $headers = [
        'Accept: ' . ($_SERVER['HTTP_ACCEPT'] ?? '*/*'),
        'Accept-Language: ' . ($_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? 'en-US,en;q=0.8'),
        'User-Agent: ' . ($_SERVER['HTTP_USER_AGENT'] ?? 'KRYPT-AUDIO-Web/1.0'),
    ];
    foreach ([
        'HTTP_RANGE' => 'Range',
        'HTTP_CONTENT_TYPE' => 'Content-Type',
        'HTTP_ORIGIN' => 'Origin',
        'HTTP_REFERER' => 'Referer',
        'HTTP_COOKIE' => 'Cookie',
        'HTTP_X_YOUTUBE_CLIENT_NAME' => 'X-Youtube-Client-Name',
        'HTTP_X_YOUTUBE_CLIENT_VERSION' => 'X-Youtube-Client-Version',
    ] as $serverKey => $headerName) {
        if (!empty($_SERVER[$serverKey])) $headers[] = $headerName . ': ' . $_SERVER[$serverKey];
    }
    return $headers;
}

cors();
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$url = targetUrl();
$parts = parse_url($url);
if (!is_array($parts) || empty($parts['host']) || !allowedHost($parts['host'])) {
    fail(403, 'The target host is not allowed.');
}

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
if (!in_array($method, ['GET', 'POST', 'HEAD'], true)) fail(405, 'Method not allowed.');

$ch = curl_init($url);
if ($ch === false) fail(500, 'Unable to initialise the upstream request.');
$body = file_get_contents('php://input');
$sentHeaders = false;

curl_setopt_array($ch, [
    CURLOPT_CUSTOMREQUEST => $method,
    CURLOPT_HTTPHEADER => requestHeaders(),
    CURLOPT_FOLLOWLOCATION => false,
    CURLOPT_CONNECTTIMEOUT => CONNECT_TIMEOUT_SECONDS,
    CURLOPT_TIMEOUT => REQUEST_TIMEOUT_SECONDS,
    CURLOPT_RETURNTRANSFER => false,
    CURLOPT_HEADER => false,
    CURLOPT_SSL_VERIFYPEER => true,
    CURLOPT_SSL_VERIFYHOST => 2,
    CURLOPT_HEADERFUNCTION => static function ($curl, string $line) use (&$sentHeaders): int {
        $trimmed = trim($line);
        if (str_starts_with($trimmed, 'HTTP/')) {
            if (preg_match('/\s(\d{3})\s/', $trimmed, $match)) {
                http_response_code((int) $match[1]);
            }
            return strlen($line);
        }
        if ($trimmed === '') return strlen($line);
        [$name, $value] = array_pad(explode(':', $trimmed, 2), 2, '');
        $name = strtolower(trim($name));
        $value = trim($value);
        $forward = [
            'content-type', 'content-length', 'content-range', 'accept-ranges',
            'cache-control', 'etag', 'last-modified', 'expires',
        ];
        if (in_array($name, $forward, true)) {
            header($name . ': ' . $value);
            $sentHeaders = true;
        }
        return strlen($line);
    },
    CURLOPT_WRITEFUNCTION => static function ($curl, string $chunk): int {
        echo $chunk;
        if (function_exists('ob_flush')) @ob_flush();
        flush();
        return strlen($chunk);
    },
]);
if ($method === 'POST') curl_setopt($ch, CURLOPT_POSTFIELDS, $body ?: '');
if ($method === 'HEAD') curl_setopt($ch, CURLOPT_NOBODY, true);

$result = curl_exec($ch);
if ($result === false) {
    $error = curl_error($ch);
    curl_close($ch);
    fail(502, 'Upstream request failed: ' . $error);
}
$status = curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
if (!$sentHeaders && $method !== 'HEAD') header('Content-Type: application/octet-stream');
http_response_code($status > 0 ? $status : 200);
curl_close($ch);
