Add-Type -AssemblyName System.Drawing

# Create a 1024x1024 bitmap
$size = 1024
$bitmap = New-Object System.Drawing.Bitmap($size, $size)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

# Fill with blue background
$blueBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(33, 150, 243))
$graphics.FillRectangle($blueBrush, 0, 0, $size, $size)

# Create white rectangle for barcode area
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$graphics.FillRectangle($whiteBrush, 112, 262, 800, 500)

# Draw barcode lines
$blackBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(33, 150, 243))
$barPositions = @(162, 222, 302, 362, 422, 502, 562, 622, 702, 762, 842)
$barWidths = @(30, 50, 30, 30, 50, 30, 30, 50, 30, 50, 30)

for ($i = 0; $i -lt $barPositions.Length; $i++) {
    $graphics.FillRectangle($blackBrush, $barPositions[$i], 312, $barWidths[$i], 400)
}

# Save the bitmap
$bitmap.Save("$PSScriptRoot\assets\icon.png", [System.Drawing.Imaging.ImageFormat]::Png)

# Create foreground icon (transparent background with barcode)
$bitmapFg = New-Object System.Drawing.Bitmap($size, $size)
$graphicsFg = [System.Drawing.Graphics]::FromImage($bitmapFg)

# White rectangle
$graphicsFg.FillRectangle($whiteBrush, 112, 262, 800, 500)

# Barcode lines
for ($i = 0; $i -lt $barPositions.Length; $i++) {
    $graphicsFg.FillRectangle($blackBrush, $barPositions[$i], 312, $barWidths[$i], 400)
}

$bitmapFg.Save("$PSScriptRoot\assets\icon_foreground.png", [System.Drawing.Imaging.ImageFormat]::Png)

Write-Host "Icons created successfully!"

# Cleanup
$graphics.Dispose()
$graphicsFg.Dispose()
$bitmap.Dispose()
$bitmapFg.Dispose()
$blueBrush.Dispose()
$whiteBrush.Dispose()
$blackBrush.Dispose()
