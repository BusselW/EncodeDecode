param([string]$InputPath)

function Generate-QRCode {
    param([string]$Data, [string]$OutputPath)
    
    Add-Type -AssemblyName System.Web
    
    $encodedData = [System.Web.HttpUtility]::UrlEncode($Data)
    $qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=$encodedData"
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($qrUrl, $OutputPath)
        $webClient.Dispose()
        return $true
    } catch {
        Write-Host "Primary QR service failed, trying backup..."
        try {
            $backupUrl = "https://chart.googleapis.com/chart?chs=400x400&cht=qr&chl=$encodedData"
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($backupUrl, $OutputPath)
            $webClient.Dispose()
            return $true
        } catch {
            Write-Host "All QR services failed, creating text file with data..."
            $Data | Out-File -FilePath ($OutputPath -replace '\.png$', '.txt') -Encoding UTF8 -NoNewline
            return $false
        }
    }
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

$successCount = 0
foreach ($file in $chunkFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $chunkNum = if ($file.Name -match '\.compressed\.(\d+)\.txt$') { $matches[1] } else { "1" }
    $qrPath = Join-Path $outputDir "$baseName.qr.$chunkNum.png"
    
    Write-Host "Generating QR for chunk $chunkNum..."
    if (Generate-QRCode $content $qrPath) {
        Write-Host "Generated QR: $qrPath"
        $successCount++
    } else {
        Write-Host "Failed to generate QR for chunk $chunkNum"
    }
}

Write-Host "QR code generation complete. Successfully created $successCount of $($chunkFiles.Count) QR code(s)."