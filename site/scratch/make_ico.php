<?php
$pngData = file_get_contents(__DIR__ . '/images/favicon-32.png');
$pngLen = strlen($pngData);

// ICO Header
$ico = pack('vvv', 0, 1, 1); // Reserved=0, Type=1 (ICO), Image count=1

// Directory Entry: Width, Height, ColorCount, Reserved, Planes, BitCount, BytesInRes, ImageOffset
$ico .= pack('CCCCvvVV', 32, 32, 0, 0, 1, 32, $pngLen, 22);

// Append raw PNG data
$ico .= $pngData;

file_put_contents(__DIR__ . '/images/favicon.ico', $ico);
echo "favicon.ico successfully generated!\n";
