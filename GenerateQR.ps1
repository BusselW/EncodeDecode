param([string]$InputPath)

function Generate-QRCode {
    param([string]$Data, [string]$OutputPath)
    
    try {
        $ie = New-Object -ComObject InternetExplorer.Application
        $ie.Visible = $false
        $ie.Navigate2("about:blank")
        
        while ($ie.Busy -or $ie.ReadyState -ne 4) {
            Start-Sleep -Milliseconds 100
        }
        
        $encodedData = [System.Web.HttpUtility]::UrlEncode($Data)
        $qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$encodedData"
        
        $doc = $ie.Document
        $doc.write("<html><body><img id='qrimg' src='$qrUrl' /></body></html>")
        $doc.close()
        
        Start-Sleep -Seconds 2
        
        $img = $doc.getElementById('qrimg')
        if ($img) {
            $canvas = $doc.createElement('canvas')
            $canvas.width = 300
            $canvas.height = 300
            $ctx = $canvas.getContext('2d')
            $ctx.drawImage($img, 0, 0)
            
            $dataUrl = $canvas.toDataURL('image/png')
            $base64 = $dataUrl.Split(',')[1]
            $bytes = [Convert]::FromBase64String($base64)
            [System.IO.File]::WriteAllBytes($OutputPath, $bytes)
        }
        
        $ie.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ie) | Out-Null
        
    } catch {
        Write-Host "Internet Explorer method failed, using fallback..."
        Generate-QRCodeFallback $Data $OutputPath
    }
}

function Generate-QRCodeFallback {
    param([string]$Data, [string]$OutputPath)
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Web
    
    $encodedData = [System.Web.HttpUtility]::UrlEncode($Data)
    $qrUrl = "https://chart.googleapis.com/chart?chs=300x300&cht=qr&chl=$encodedData"
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($qrUrl, $OutputPath)
        $webClient.Dispose()
    } catch {
        Write-Host "Online QR generation failed, creating text file instead..."
        $Data | Out-File -FilePath ($OutputPath -replace '\.png$', '.txt') -Encoding UTF8 -NoNewline
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

foreach ($file in $chunkFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $chunkNum = if ($file.Name -match '\.compressed\.(\d+)\.txt$') { $matches[1] } else { "1" }
    $qrPath = Join-Path $outputDir "$baseName.qr.$chunkNum.png"
    
    Generate-QRCode $content $qrPath
    Write-Host "Generated QR: $qrPath"
}

Write-Host "QR code generation complete. Created $($chunkFiles.Count) QR code(s)."