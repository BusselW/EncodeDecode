param([string]$InputPath)
Add-Type -AssemblyName System.Drawing
$outputDir = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\output\text"
if (!(Test-Path $outputDir)) { md $outputDir -Force | Out-Null }

if ($InputPath -like "*.png") {
    $bitmap = [System.Drawing.Bitmap]::FromFile($InputPath)
    $moduleSize = [Math]::Floor($bitmap.Width / 25)
    $bits = ""; $chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ `$%*+-./:"
    for ($y = 0; $y -lt $bitmap.Height; $y += $moduleSize) {
        for ($x = 0; $x -lt $bitmap.Width; $x += $moduleSize) {
            $pixel = $bitmap.GetPixel($x + [Math]::Floor($moduleSize/2), $y + [Math]::Floor($moduleSize/2))
            $bits += if (($pixel.R + $pixel.G + $pixel.B) / 3 -lt 128) { "1" } else { "0" }
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
    $result | Out-File "$outputDir\$([System.IO.Path]::GetFileNameWithoutExtension($InputPath)).decoded.txt" -Encoding UTF8 -NoNewline
    Write-Host "Decoded QR"
} else {
    $files = if (Test-Path $InputPath -PathType Container) { Get-ChildItem $InputPath -Filter "*.txt" } else { Get-ChildItem (Split-Path $InputPath) -Filter "*$(([System.IO.Path]::GetFileNameWithoutExtension($InputPath) -replace '\.decoded$', ''))*.txt" }
    $chunks = @{}; $total = 0
    $files | % { 
        $content = (Get-Content $_.FullName -Raw) -replace "`r`n?", "`n"
        if ($content -match '^(\d+)/(\d+)\|(.*)$') {
            $chunks[[int]$matches[1]] = $matches[3].Trim()
            $total = [Math]::Max($total, [int]$matches[2])
        }
    }
    $merged = ""; 1..$total | % { if ($chunks[$_]) { $merged += $chunks[$_] } }
    $merged | Out-File "$outputDir\merged.decoded.txt" -Encoding UTF8 -NoNewline
    Write-Host "Merged chunks"
}