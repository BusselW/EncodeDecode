param([string]$InputPath)

function Read-QRImage {
    param([string]$ImagePath)
    
    Add-Type -AssemblyName System.Drawing
    $bitmap = [System.Drawing.Bitmap]::FromFile($ImagePath)
    $width = $bitmap.Width
    $height = $bitmap.Height
    $moduleSize = [Math]::Floor($width / 25)
    
    $bits = ""
    $chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ `$%*+-./:"
    
    for ($y = 0; $y -lt $height; $y += $moduleSize) {
        for ($x = 0; $x -lt $width; $x += $moduleSize) {
            $pixel = $bitmap.GetPixel($x + [Math]::Floor($moduleSize/2), $y + [Math]::Floor($moduleSize/2))
            $brightness = ($pixel.R + $pixel.G + $pixel.B) / 3
            $bits += if ($brightness -lt 128) { "1" } else { "0" }
        }
    }
    
    $bitmap.Dispose()
    
    $result = ""
    for ($i = 0; $i -lt $bits.Length; $i += 6) {
        if ($i + 6 -le $bits.Length) {
            $val = [Convert]::ToInt32($bits.Substring($i, 6), 2)
            if ($val -lt $chars.Length) { $result += $chars[$val] }
        }
    }
    
    return $result
}

function Process-Chunks {
    param([string[]]$ChunkFiles)
    
    $chunks = @{}
    $totalChunks = 0
    
    foreach ($file in $ChunkFiles) {
        $content = Get-Content -Path $file -Raw -Encoding UTF8
        $content = $content -replace "`r`n", "`n" -replace "`r", "`n"
        
        if ($content -match '^(\d+)/(\d+)\|(.*)$') {
            $chunkNum = [int]$matches[1]
            $total = [int]$matches[2]
            $data = $matches[3].Trim()
            $chunks[$chunkNum] = $data
            $totalChunks = [Math]::Max($totalChunks, $total)
        }
    }
    
    $merged = ""
    for ($i = 1; $i -le $totalChunks; $i++) {
        if ($chunks.ContainsKey($i)) {
            $merged += $chunks[$i]
        }
    }
    
    return $merged
}

$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$outputDir = Join-Path $scriptDir "output\text"
if (!(Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

if (Test-Path $InputPath -PathType Container) {
    $files = Get-ChildItem -Path $InputPath -Filter "*.txt" | Sort-Object Name
    if ($files.Count -gt 0) {
        $merged = Process-Chunks $files.FullName
        $outputFile = Join-Path $outputDir "merged.decoded.txt"
        $merged | Out-File -FilePath $outputFile -Encoding UTF8 -NoNewline
        Write-Host "Merged chunks: $outputFile"
    }
} elseif ($InputPath -like "*.png") {
    $result = Read-QRImage $InputPath
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
    $outputFile = Join-Path $outputDir "$baseName.decoded.txt"
    $result | Out-File -FilePath $outputFile -Encoding UTF8 -NoNewline
    Write-Host "Decoded QR: $outputFile"
} elseif ($InputPath -like "*.txt") {
    $dir = Split-Path $InputPath -Parent
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath) -replace '\.decoded$', ''
    $files = Get-ChildItem -Path $dir -Filter "$baseName*.decoded.txt" | Sort-Object Name
    if ($files.Count -gt 0) {
        $merged = Process-Chunks $files.FullName
        $outputFile = Join-Path $outputDir "$baseName.merged.txt"
        $merged | Out-File -FilePath $outputFile -Encoding UTF8 -NoNewline
        Write-Host "Merged chunks: $outputFile"
    }
}