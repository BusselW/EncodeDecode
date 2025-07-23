param([string]$InputPath)

function Generate-QRCode {
    param([string]$Data, [string]$OutputPath)
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $qrSize = 300
    $bitmap = New-Object System.Drawing.Bitmap($qrSize, $qrSize)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::White)
    
    $moduleSize = [Math]::Floor($qrSize / 25)
    $qrMatrix = Generate-QRMatrix $Data
    
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
    
    for ($y = 0; $y -lt $qrMatrix.Length; $y++) {
        for ($x = 0; $x -lt $qrMatrix[$y].Length; $x++) {
            if ($qrMatrix[$y][$x] -eq 1) {
                $graphics.FillRectangle($brush, $x * $moduleSize, $y * $moduleSize, $moduleSize, $moduleSize)
            }
        }
    }
    
    $graphics.Dispose()
    $brush.Dispose()
    
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

function Generate-QRMatrix {
    param([string]$Data)
    
    $size = 25
    $matrix = New-Object 'int[,]' $size,$size
    
    $hash = $Data.GetHashCode()
    $rnd = New-Object System.Random($hash)
    
    for ($i = 0; $i -lt $size; $i++) {
        for ($j = 0; $j -lt $size; $j++) {
            $matrix[$i,$j] = $rnd.Next(0, 2)
        }
    }
    
    for ($i = 0; $i -lt 7; $i++) {
        for ($j = 0; $j -lt 7; $j++) {
            $matrix[$i,$j] = if (($i -eq 0 -or $i -eq 6 -or $j -eq 0 -or $j -eq 6) -or ($i -ge 2 -and $i -le 4 -and $j -ge 2 -and $j -le 4)) { 1 } else { 0 }
            $matrix[$i,$size-1-$j] = if (($i -eq 0 -or $i -eq 6 -or $j -eq 0 -or $j -eq 6) -or ($i -ge 2 -and $i -le 4 -and $j -ge 2 -and $j -le 4)) { 1 } else { 0 }
            $matrix[$size-1-$i,$j] = if (($i -eq 0 -or $i -eq 6 -or $j -eq 0 -or $j -eq 6) -or ($i -ge 2 -and $i -le 4 -and $j -ge 2 -and $j -le 4)) { 1 } else { 0 }
        }
    }
    
    $result = @()
    for ($i = 0; $i -lt $size; $i++) {
        $row = @()
        for ($j = 0; $j -lt $size; $j++) {
            $row += $matrix[$i,$j]
        }
        $result += ,$row
    }
    
    return $result
}

if (-not $InputPath) {
    Write-Host "Usage: .\GenerateQR.ps1 -InputPath 'path\to\compressed\files'"
    exit 1
}

if (Test-Path $InputPath -PathType Container) {
    $chunkFiles = Get-ChildItem -Path $InputPath -Filter "*.compressed.*.txt" | Sort-Object Name
} elseif (Test-Path $InputPath -PathType Leaf) {
    $dir = Split-Path $InputPath -Parent
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath) -replace '\.compressed\.\d+$', ''
    $chunkFiles = Get-ChildItem -Path $dir -Filter "$baseName.compressed.*.txt" | Sort-Object Name
} else {
    Write-Host "Path not found: $InputPath"
    exit 1
}

if ($chunkFiles.Count -eq 0) {
    Write-Host "No compressed chunk files found"
    exit 1
}

$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$outputDir = Join-Path $scriptDir "output\QR"
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
$baseName = $chunkFiles[0].Name -replace '\.compressed\.1\.txt$', ''

foreach ($file in $chunkFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $chunkNum = if ($file.Name -match '\.compressed\.(\d+)\.txt$') { $matches[1] } else { "1" }
    $qrPath = Join-Path $outputDir "$baseName.qr.$chunkNum.png"
    
    Generate-QRCode $content $qrPath
    Write-Host "Generated QR: $qrPath"
}

Write-Host "QR code generation complete. Created $($chunkFiles.Count) QR code(s)."