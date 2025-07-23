param([string]$InputPath)
$outputDir = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\output\text"
if (!(Test-Path $outputDir)) { md $outputDir -Force | Out-Null }

$files = if (Test-Path $InputPath -PathType Container) { Get-ChildItem $InputPath -Filter "*.txt" } else { @(Get-Item $InputPath) }

$files | % {
    $content = Get-Content $_.FullName -Raw
    if ($content -match '^(\d+)/(\d+)\|(.*)$') {
        $chunks = @{}; $total = [int]$matches[2]
        $dir = Split-Path $_.FullName; $base = $_.BaseName -replace '\.\d+$', ''
        Get-ChildItem $dir -Filter "$base*.txt" | % {
            $c = Get-Content $_.FullName -Raw
            if ($c -match '^(\d+)/(\d+)\|(.*)$') { $chunks[[int]$matches[1]] = $matches[3].Trim() }
        }
        $merged = ""; 1..$total | % { if ($chunks[$_]) { $merged += $chunks[$_] } }
        $content = $merged
    }
    
    try {
        $compressed = [Convert]::FromBase64String($content)
        $stream = New-Object System.IO.MemoryStream(,$compressed)
        $gzip = New-Object System.IO.Compression.GzipStream($stream, [System.IO.Compression.CompressionMode]::Decompress)
        $reader = New-Object System.IO.StreamReader($gzip)
        $text = $reader.ReadToEnd()
        $reader.Close(); $gzip.Close(); $stream.Close()
        
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $text | Out-File "$outputDir\$baseName.restored.txt" -Encoding UTF8 -NoNewline
        Write-Host "Decoded: $baseName.restored.txt"
    } catch {
        Write-Host "Failed to decode: $($_.Name)"
    }
}