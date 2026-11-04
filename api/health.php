<?php
declare(strict_types=1);
require_once __DIR__ . '/config.php';
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');
echo json_encode([
    'ok' => true,
    'service' => 'KRYPT AUDIO Web API',
    'version' => '1.0.0',
    'php' => PHP_VERSION,
    'curl' => extension_loaded('curl'),
    'google_api_key_configured' => googleApiKey() !== '',
    'timestamp' => gmdate('c'),
], JSON_UNESCAPED_SLASHES);
