param([string]$InputFile)

function Compress-Text {
    param([string]$Text)
    
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $stream = New-Object System.IO.MemoryStream
    $gzip = New-Object System.IO.Compression.GzipStream($stream, [System.IO.Compression.CompressionMode]::Compress)
    $gzip.Write($bytes, 0, $bytes.Length)
    $gzip.Close()
    $compressed = $stream.ToArray()
    $stream.Close()
    
    return [Convert]::ToBase64String($compressed)
}

function Split-ForQR {
    param([string]$Data, [int]$MaxLength = 2800)
    
    $chunks = @()
    $totalChunks = [Math]::Ceiling($Data.Length / $MaxLength)
    
    for ($i = 0; $i -lt $totalChunks; $i++) {
        $start = $i * $MaxLength
        $length = [Math]::Min($MaxLength, $Data.Length - $start)
        $chunk = $Data.Substring($start, $length)
        $header = "$($i + 1)/$totalChunks|"
        $chunks += $header + $chunk
    }
    
    return $chunks
}

if (-not $InputFile) {
    Write-Host "Usage: .\Compress.ps1 -InputFile 'path\to\file.txt'"
    exit 1
}

if (-not (Test-Path $InputFile)) {
    Write-Host "File not found: $InputFile"
    exit 1
}

$content = Get-Content -Path $InputFile -Raw -Encoding UTF8
$compressed = Compress-Text $content
$chunks = Split-ForQR $compressed

$outputDir = Split-Path $InputFile -Parent
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)

for ($i = 0; $i -lt $chunks.Count; $i++) {
    $outputFile = Join-Path $outputDir "$baseName.compressed.$($i + 1).txt"
    $chunks[$i] | Out-File -FilePath $outputFile -Encoding UTF8 -NoNewline
    Write-Host "Created: $outputFile"
}

Write-Host "Compression complete. Created $($chunks.Count) chunk(s)."