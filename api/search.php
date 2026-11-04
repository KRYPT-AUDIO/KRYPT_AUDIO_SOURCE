<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';

apiCors();
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') apiJson(['error' => 'Method not allowed.'], 405);

$key = googleApiKey();
if ($key === '') {
    apiJson(['error' => 'YOUTUBE_DATA_API_KEY is not configured on the server.'], 503);
}

$query = trim((string) ($_GET['q'] ?? ''));
$type = (string) ($_GET['type'] ?? 'video');
$maxResults = max(1, min(50, (int) ($_GET['maxResults'] ?? 25)));
$pageToken = trim((string) ($_GET['pageToken'] ?? ''));
if ($query === '' || strlen($query) > 200) apiJson(['error' => 'A search query between 1 and 200 characters is required.'], 400);
if (!in_array($type, ['video', 'channel', 'playlist'], true)) apiJson(['error' => 'Invalid search type.'], 400);

$params = [
    'part' => 'snippet',
    'q' => $query,
    'type' => $type,
    'maxResults' => (string) $maxResults,
    'key' => $key,
];
if ($pageToken !== '') $params['pageToken'] = $pageToken;
$url = 'https://www.googleapis.com/youtube/v3/search?' . http_build_query($params);

$ch = curl_init($url);
if ($ch === false) apiJson(['error' => 'Unable to initialise Google API request.'], 500);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_FOLLOWLOCATION => false,
    CURLOPT_CONNECTTIMEOUT => 10,
    CURLOPT_TIMEOUT => 30,
    CURLOPT_HTTPHEADER => ['Accept: application/json', 'User-Agent: KRYPT-AUDIO-Web/1.0'],
]);
$body = curl_exec($ch);
$error = curl_error($ch);
$status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
curl_close($ch);
if ($body === false) apiJson(['error' => 'Google API request failed.', 'detail' => $error], 502);
$data = json_decode($body, true);
if (!is_array($data)) apiJson(['error' => 'Google API returned invalid JSON.'], 502);
if ($status < 200 || $status >= 300) {
    apiJson(['error' => 'Google API returned an error.', 'google' => $data], $status >= 400 && $status < 600 ? $status : 502);
}
apiJson($data);
