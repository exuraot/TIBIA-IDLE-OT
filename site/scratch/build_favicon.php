<?php
$sourcePath = '/tmp/ex_icon.jpg';
if (!file_exists($sourcePath)) {
    die("Source file $sourcePath does not exist\n");
}

$src = imagecreatefromjpeg($sourcePath);
$w = imagesx($src);
$h = imagesy($src);

echo "Loaded image: {$w}x{$h}\n";

// Let's create an image with truecolor and alpha transparency
$img = imagecreatetruecolor($w, $h);
imagealphablending($img, false);
imagesavealpha($img, true);

// Create transparent color
$transparent = imagecolorallocatealpha($img, 0, 0, 0, 127);
imagefill($img, 0, 0, $transparent);

// Detect outer black background via breadth-first search / flood fill from the 4 corners
$visited = array_fill(0, $w * $h, false);
$queue = [[0, 0], [$w - 1, 0], [0, $h - 1], [$w - 1, $h - 1]];

// Also sample along the outer border
for ($x = 0; $x < $w; $x += 10) {
    $queue[] = [$x, 0];
    $queue[] = [$x, $h - 1];
}
for ($y = 0; $y < $h; $y += 10) {
    $queue[] = [0, $y];
    $queue[] = [$w - 1, $y];
}

$isBg = array_fill(0, $w * $h, false);
$threshold = 28; // Darkness threshold for black background

while (!empty($queue)) {
    [$qx, $qy] = array_pop($queue);
    $idx = $qy * $w + $qx;
    if ($visited[$idx]) continue;
    $visited[$idx] = true;

    $rgb = imagecolorat($src, $qx, $qy);
    $r = ($rgb >> 16) & 0xFF;
    $g = ($rgb >> 8) & 0xFF;
    $b = $rgb & 0xFF;
    $brightness = max($r, $g, $b);

    if ($brightness <= $threshold) {
        $isBg[$idx] = true;

        // Add 4-neighbors
        if ($qx > 0 && !$visited[$qy * $w + ($qx - 1)]) $queue[] = [$qx - 1, $qy];
        if ($qx < $w - 1 && !$visited[$qy * $w + ($qx + 1)]) $queue[] = [$qx + 1, $qy];
        if ($qy > 0 && !$visited[($qy - 1) * $w + $qx]) $queue[] = [$qx, $qy - 1];
        if ($qy < $h - 1 && !$visited[($qy + 1) * $w + $qx]) $queue[] = [$qx, $qy + 1];
    }
}

// Now copy pixels to $img: if isBg, alpha=127; if near border of isBg, smooth alpha; else opaque
for ($y = 0; $y < $h; $y++) {
    for ($x = 0; $x < $w; $x++) {
        $idx = $y * $w + $x;
        if ($isBg[$idx]) {
            imagesetpixel($img, $x, $y, $transparent);
        } else {
            $rgb = imagecolorat($src, $x, $y);
            $r = ($rgb >> 16) & 0xFF;
            $g = ($rgb >> 8) & 0xFF;
            $b = $rgb & 0xFF;

            // Check if adjacent to background for soft anti-aliased edge
            $adjCount = 0;
            if ($x > 0 && $isBg[$idx - 1]) $adjCount++;
            if ($x < $w - 1 && $isBg[$idx + 1]) $adjCount++;
            if ($y > 0 && $isBg[$idx - $w]) $adjCount++;
            if ($y < $h - 1 && $isBg[$idx + $w]) $adjCount++;

            $alpha = 0;
            if ($adjCount > 0) {
                $brightness = max($r, $g, $b);
                if ($brightness < 60) {
                    $alpha = (int)(127 * (1.0 - ($brightness / 60.0)));
                }
            }

            $col = imagecolorallocatealpha($img, $r, $g, $b, $alpha);
            imagesetpixel($img, $x, $y, $col);
        }
    }
}

// Generate multiple sizes
$sizes = [16, 32, 48, 64, 180, 192];
$pngBuffers = [];

foreach ($sizes as $sz) {
    $dst = imagecreatetruecolor($sz, $sz);
    imagealphablending($dst, false);
    imagesavealpha($dst, true);
    imagefill($dst, 0, 0, $transparent);

    imagecopyresampled($dst, $img, 0, 0, 0, 0, $sz, $sz, $w, $h);

    $outPng = "/var/www/myaac/images/favicon-{$sz}.png";
    imagepng($dst, $outPng, 9);
    echo "Saved {$outPng}\n";

    if (in_array($sz, [16, 32, 48])) {
        ob_start();
        imagepng($dst, null, 9);
        $pngBuffers[$sz] = ob_get_clean();
    }
    imagedestroy($dst);
}

// Save main favicon.png (32x32)
copy("/var/www/myaac/images/favicon-32.png", "/var/www/myaac/images/favicon.png");
copy("/var/www/myaac/images/favicon-180.png", "/var/www/myaac/images/apple-touch-icon.png");

// Build multi-resolution ICO file (16x16, 32x32, 48x48)
$icoHeader = pack('vvv', 0, 1, count($pngBuffers));
$icoDir = '';
$icoData = '';
$offset = 6 + (count($pngBuffers) * 16);

foreach ($pngBuffers as $sz => $data) {
    $len = strlen($data);
    $bWidth = ($sz == 256) ? 0 : $sz;
    $bHeight = ($sz == 256) ? 0 : $sz;
    $icoDir .= pack('CCCCvvVV', $bWidth, $bHeight, 0, 0, 1, 32, $len, $offset);
    $icoData .= $data;
    $offset += $len;
}

$finalIco = $icoHeader . $icoDir . $icoData;
file_put_contents("/var/www/myaac/images/favicon.ico", $finalIco);
echo "Multi-resolution favicon.ico generated (" . strlen($finalIco) . " bytes)!\n";
