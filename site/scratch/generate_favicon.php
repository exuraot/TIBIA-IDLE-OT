<?php
$file = __DIR__ . '/templates/tibiacom/images/header/exura-logo.png';
$img = imagecreatefrompng($file);

// Ruby crystal + top crest is centered at X=512, Y from 16 to ~160.
// Let's crop a square region centered at (512, 85), size ~140x140
$cropSize = 140;
$cropX = 512 - ($cropSize / 2);
$cropY = 16;

$crop = imagecreatetruecolor($cropSize, $cropSize);
imagealphablending($crop, false);
imagesavealpha($crop, true);
$transparent = imagecolorallocatealpha($crop, 0, 0, 0, 127);
imagefill($crop, 0, 0, $transparent);

imagecopy($crop, $img, 0, 0, $cropX, $cropY, $cropSize, $cropSize);

// Resize to 32x32 and 64x64
foreach ([16, 32, 48, 64] as $sz) {
    $dst = imagecreatetruecolor($sz, $sz);
    imagealphablending($dst, false);
    imagesavealpha($dst, true);
    imagefill($dst, 0, 0, $transparent);
    imagecopyresampled($dst, $crop, 0, 0, 0, 0, $sz, $sz, $cropSize, $cropSize);
    imagepng($dst, __DIR__ . "/images/favicon-{$sz}.png");
}

// Also save 32x32 as favicon.png
copy(__DIR__ . "/images/favicon-32.png", __DIR__ . "/images/favicon.png");

echo "Favicons generated successfully!\n";
