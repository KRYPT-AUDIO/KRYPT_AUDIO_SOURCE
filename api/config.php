<?php
declare(strict_types=1);

/** Load a small .env file without exposing it to the browser. */
function loadEnvFile(string $path): void {
    if (!is_file($path) || !is_readable($path)) return;
    foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) continue;
        [$key, $value] = explode('=', $line, 2);
        $key = trim($key);
        $value = trim($value);
        if ($value !== '' && (($value[0] ?? '') === '"' || ($value[0] ?? '') === "'")) {
            $value = trim($value, "\"'");
        }
        if ($key !== '' && getenv($key) === false) putenv($key . '=' . $value);
    }
}

loadEnvFile(__DIR__ . '/.env');

function envValue(string $key, string $default = ''): string {
    $value = getenv($key);
    return $value === false ? $default : trim($value);
}

function apiCors(): void {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    $allowed = envValue('ALLOWED_ORIGIN', '*');
    header('Access-Control-Allow-Origin: ' . ($allowed === '*' ? '*' : ($origin === $allowed ? $origin : $allowed)));
    header('Access-Control-Allow-Methods: GET, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Accept');
    header('Vary: Origin');
}

function apiJson(array $payload, int $status = 200): never {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

function googleApiKey(): string {
    return envValue('YOUTUBE_DATA_API_KEY');
}
