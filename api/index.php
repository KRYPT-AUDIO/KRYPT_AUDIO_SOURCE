<?php
declare(strict_types=1);
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');
echo json_encode([
    'service' => 'KRYPT AUDIO Web API',
    'status' => 'online',
    'health' => 'health.php',
    'proxy' => 'proxy.php?url=<encoded-url>',
    'version' => '1.0.0',
], JSON_UNESCAPED_SLASHES);
