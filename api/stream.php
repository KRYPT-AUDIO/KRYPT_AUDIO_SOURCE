<?php
declare(strict_types=1);

require_once __DIR__ . '/config.php';

apiCors();
header('Access-Control-Allow-Headers: Range, Content-Type');
header('Access-Control-Expose-Headers: Accept-Ranges, Content-Length, Content-Range, Content-Type');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$id = trim((string)($_GET['id'] ?? ''));
if (!preg_match('/^[A-Za-z0-9_-]{6,32}$/', $id)) {
    apiJson(['error' => 'A valid YouTube video id is required.'], 400);
}

$resolverBase = rtrim(envValue('KRYPT_RESOLVER_URL'), '/');
$resolverToken = envValue('KRYPT_RESOLVER_TOKEN');
if ($resolverBase === '' || $resolverToken === '') {
    apiJson(['error' => 'The KRYPT Cloud audio resolver is not configured.'], 503);
}

$query = http_build_query([
    'id' => $id,
    'live' => (($_GET['live'] ?? '') === '1') ? '1' : '0',
]);
$target = $resolverBase . '/stream?' . $query;
$method = strtoupper((string)($_SERVER['REQUEST_METHOD'] ?? 'GET'));
$forwardHeaders = [
    'Accept: */*',
    'User-Agent: KRYPT-AUDIO-PHP/2.1',
    'X-Krypt-Resolver-Token: ' . $resolverToken,
];
if (!empty($_SERVER['HTTP_RANGE'])) {
    $forwardHeaders[] = 'Range: ' . $_SERVER['HTTP_RANGE'];
}

$ch = curl_init($target);
if ($ch === false) apiJson(['error' => 'Unable to initialise the Cloud audio request.'], 500);
curl_setopt_array($ch, [
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_RETURNTRANSFER => false,
    CURLOPT_HEADER => false,
    CURLOPT_HTTPHEADER => $forwardHeaders,
    CURLOPT_CONNECTTIMEOUT => 15,
    CURLOPT_TIMEOUT => 0,
    CURLOPT_CUSTOMREQUEST => $method,
    CURLOPT_NOBODY => $method === 'HEAD',
    CURLOPT_BUFFERSIZE => 65536,
    CURLOPT_HEADERFUNCTION => static function ($ch, string $header): int {
        $parts = explode(':', $header, 2);
        $name = strtolower(trim($parts[0] ?? ''));
        if (in_array($name, ['content-type', 'content-length', 'content-range', 'accept-ranges', 'etag', 'last-modified'], true)) {
            header(trim($header));
        }
        return strlen($header);
    },
    CURLOPT_WRITEFUNCTION => static function ($ch, string $chunk): int {
        echo $chunk;
        flush();
        return strlen($chunk);
    },
]);

$ok = curl_exec($ch);
$status = (int)curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($ok === false || $status < 200 || $status >= 400) {
    if (!headers_sent()) {
        apiJson([
            'error' => 'Cloud audio resolver request failed.',
            'status' => $status,
            'detail' => $error,
        ], 502);
    }
    exit;
}

http_response_code($status);
exit;
