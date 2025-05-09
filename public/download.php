<?php

$shareDir = __DIR__ . '/../share';


$file = isset($_GET['file']) ? basename($_GET['file']) : null;


$filePath = $shareDir . '/' . $file;

if ($file && file_exists($filePath)) {
    header('Content-Description: File Transfer');
    header('Content-Type: application/octet-stream');
    header('Content-Disposition: attachment; filename="' . basename($filePath) . '"');
    header('Content-Length: ' . filesize($filePath));
    readfile($filePath);
    exit;
} else {
    echo "File not found.";
}
