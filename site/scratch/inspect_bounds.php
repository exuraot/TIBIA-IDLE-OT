<?php
$file = __DIR__ . '/templates/tibiacom/images/header/exura-logo.png';
$img = imagecreatefrompng($file);
$w = imagesx($img);
$h = imagesy($img);

$minX = $w; $minY = $h; $maxX = 0; $maxY = 0;

for ($x = 0; $x < $w; $x += 4) {
    for ($y = 0; $y < $h; $y += 4) {
        $rgba = imagecolorat($img, $x, $y);
        $alpha = ($rgba & 0x7F000000) >> 24;
        if ($alpha < 120) { // non-transparent
            if ($x < $minX) $minX = $x;
            if ($x > $maxX) $maxX = $x;
            if ($y < $minY) $minY = $y;
            if ($y > $maxY) $maxY = $y;
        }
    }
}

echo "Bounds: X: $minX to $maxX, Y: $minY to $maxY\n";
