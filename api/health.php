<?php
declare(strict_types=1);
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');
echo json_encode([
    'ok' => true,
    'service' => 'KRYPT AUDIO Web API',
    'version' => '1.0.0',
    'php' => PHP_VERSION,
    'curl' => extension_loaded('curl'),
    'timestamp' => gmdate('c'),
], JSON_UNESCAPED_SLASHES);
