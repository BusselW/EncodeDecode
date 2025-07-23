param([string]$InputPath, [string]$OutputFile)

function Decompress-Text {
    param([string]$CompressedText)
    
    $compressed = [Convert]::FromBase64String($CompressedText)
    $stream = New-Object System.IO.MemoryStream(,$compressed)
    $gzip = New-Object System.IO.Compression.GzipStream($stream, [System.IO.Compression.CompressionMode]::Decompress)
    $reader = New-Object System.IO.StreamReader($gzip)
    $text = $reader.ReadToEnd()
    $reader.Close()
    $gzip.Close()
    $stream.Close()
    
    return $text
}

function Merge-Chunks {
    param([string[]]$ChunkFiles)
    
    $chunks = @{}
    $totalChunks = 0
    
    foreach ($file in $ChunkFiles) {
        $content = Get-Content -Path $file -Raw -Encoding UTF8
        if ($content -match '^(\d+)/(\d+)\|(.*)$') {
            $chunkNum = [int]$matches[1]
            $total = [int]$matches[2]
            $data = $matches[3]
            $chunks[$chunkNum] = $data
            $totalChunks = [Math]::Max($totalChunks, $total)
        }
    }
    
    $merged = ""
    for ($i = 1; $i -le $totalChunks; $i++) {
        if ($chunks.ContainsKey($i)) {
            $merged += $chunks[$i]
        } else {
            throw "Missing chunk $i of $totalChunks"
        }
    }
    
    return $merged
}

if (-not $InputPath) {
    Write-Host "Usage: .\Decompress.ps1 -InputPath 'path\to\chunks' -OutputFile 'output.txt'"
    Write-Host "       .\Decompress.ps1 -InputPath 'single.compressed.1.txt' -OutputFile 'output.txt'"
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

try {
    $merged = Merge-Chunks $chunkFiles.FullName
    $decompressed = Decompress-Text $merged
    
    if (-not $OutputFile) {
        $firstFile = $chunkFiles[0].Name
        $baseName = $firstFile -replace '\.compressed\.1\.txt$', ''
        $OutputFile = Join-Path (Split-Path $chunkFiles[0].FullName -Parent) "$baseName.restored.txt"
    }
    
    $decompressed | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline
    Write-Host "Decompression complete: $OutputFile"
    
} catch {
    Write-Host "Error during decompression: $($_.Exception.Message)"
    exit 1
}