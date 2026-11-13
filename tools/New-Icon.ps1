#requires -Version 5.1
<#
.SYNOPSIS
    Generates the application icon (FormatFAT32.ico) and the README logo (docs/logo.png).

.DESCRIPTION
    Draws an SD card with a green check on a blue rounded tile, at several
    resolutions, and packs them into a single PNG-compressed ICO file.

.EXAMPLE
    .\New-Icon.ps1
#>
[CmdletBinding()]
param(
    [string]$OutputDir
)

$ErrorActionPreference = 'Stop'
if (-not $OutputDir) { $OutputDir = Split-Path -Parent (Split-Path -Parent $PSCommandPath) }
Add-Type -AssemblyName System.Drawing

function New-IconBitmap {
    param([int]$Size)

    $scale = $Size / 256.0
    $bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    # Rounded background tile
    $radius = [float](56 * $scale)
    $diameter = $radius * 2
    $tile = New-Object System.Drawing.Drawing2D.GraphicsPath
    $tile.AddArc(0, 0, $diameter, $diameter, 180, 90)
    $tile.AddArc($Size - $diameter, 0, $diameter, $diameter, 270, 90)
    $tile.AddArc($Size - $diameter, $Size - $diameter, $diameter, $diameter, 0, 90)
    $tile.AddArc(0, $Size - $diameter, $diameter, $diameter, 90, 90)
    $tile.CloseFigure()

    $gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point 0, 0),
        (New-Object System.Drawing.Point $Size, $Size),
        [System.Drawing.Color]::FromArgb(255, 51, 132, 245),
        [System.Drawing.Color]::FromArgb(255, 12, 58, 132))
    $g.FillPath($gradient, $tile)

    # SD card silhouette
    $cardWidth = [float](104 * $scale)
    $cardHeight = [float](132 * $scale)
    $cardX = [float](($Size - $cardWidth) / 2 - 8 * $scale)
    $cardY = [float](($Size - $cardHeight) / 2 - 6 * $scale)
    $notch = [float](30 * $scale)

    $card = New-Object System.Drawing.Drawing2D.GraphicsPath
    $points = [System.Drawing.PointF[]]@(
        (New-Object System.Drawing.PointF $cardX, $cardY),
        (New-Object System.Drawing.PointF ($cardX + $cardWidth - $notch), $cardY),
        (New-Object System.Drawing.PointF ($cardX + $cardWidth), ($cardY + $notch)),
        (New-Object System.Drawing.PointF ($cardX + $cardWidth), ($cardY + $cardHeight)),
        (New-Object System.Drawing.PointF $cardX, ($cardY + $cardHeight))
    )
    $card.AddPolygon($points)
    $g.FillPath([System.Drawing.Brushes]::White, $card)

    if ($Size -ge 48) {
        # Contact strip
        $stripBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 196, 210, 228))
        $stripWidth = [float](10 * $scale)
        $stripHeight = [float](46 * $scale)
        $gap = [float](8 * $scale)
        $stripX = [float]($cardX + 14 * $scale)
        $stripY = [float]($cardY + 14 * $scale)
        for ($i = 0; $i -lt 3; $i++) {
            $g.FillRectangle($stripBrush, $stripX, $stripY, $stripWidth, $stripHeight)
            $stripX += $stripWidth + $gap
        }
        $stripBrush.Dispose()
    }

    # Green badge with a check mark
    $badgeSize = [float](104 * $scale)
    $badgeX = [float]($Size - $badgeSize - 14 * $scale)
    $badgeY = [float]($Size - $badgeSize - 14 * $scale)
    $badgeBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 32, 168, 84))
    $g.FillEllipse($badgeBrush, $badgeX, $badgeY, $badgeSize, $badgeSize)
    $badgeBrush.Dispose()

    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), ([float](16 * $scale))
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $checkPoints = [System.Drawing.PointF[]]@(
        (New-Object System.Drawing.PointF ($badgeX + $badgeSize * 0.26), ($badgeY + $badgeSize * 0.53)),
        (New-Object System.Drawing.PointF ($badgeX + $badgeSize * 0.44), ($badgeY + $badgeSize * 0.71)),
        (New-Object System.Drawing.PointF ($badgeX + $badgeSize * 0.76), ($badgeY + $badgeSize * 0.31))
    )
    $g.DrawLines($pen, $checkPoints)
    $pen.Dispose()

    $card.Dispose()
    $tile.Dispose()
    $gradient.Dispose()
    $g.Dispose()

    return $bmp
}

function Get-PngBytes {
    param([System.Drawing.Bitmap]$Bitmap)
    $stream = New-Object System.IO.MemoryStream
    $Bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $stream.ToArray()
    $stream.Dispose()
    return $bytes
}

function Write-IcoFile {
    param(
        [string]$Path,
        [int[]]$Sizes
    )

    $images = @()
    foreach ($size in $Sizes) {
        $bmp = New-IconBitmap -Size $size
        $images += [pscustomobject]@{ Size = $size; Bytes = [byte[]](Get-PngBytes -Bitmap $bmp) }
        $bmp.Dispose()
    }

    $stream = New-Object System.IO.MemoryStream
    $writer = New-Object System.IO.BinaryWriter $stream
    $writer.Write([uint16]0)               # reserved
    $writer.Write([uint16]1)               # type: icon
    $writer.Write([uint16]$images.Count)   # image count

    $offset = 6 + (16 * $images.Count)
    foreach ($image in $images) {
        $dimension = if ($image.Size -ge 256) { 0 } else { $image.Size }
        $writer.Write([byte]$dimension)    # width
        $writer.Write([byte]$dimension)    # height
        $writer.Write([byte]0)             # palette
        $writer.Write([byte]0)             # reserved
        $writer.Write([uint16]1)           # color planes
        $writer.Write([uint16]32)          # bits per pixel
        $writer.Write([uint32]$image.Bytes.Length)
        $writer.Write([uint32]$offset)
        $offset += $image.Bytes.Length
    }
    foreach ($image in $images) {
        $writer.Write([byte[]]$image.Bytes)
    }

    $writer.Flush()
    [System.IO.File]::WriteAllBytes($Path, $stream.ToArray())
    $writer.Dispose()
    $stream.Dispose()
}

$iconPath = Join-Path $OutputDir 'FormatFAT32.ico'
Write-IcoFile -Path $iconPath -Sizes @(16, 24, 32, 48, 64, 128, 256)
Write-Host ("Icon written: {0}" -f $iconPath)

$docsDir = Join-Path $OutputDir 'docs'
if (-not (Test-Path -LiteralPath $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
}
$logo = New-IconBitmap -Size 512
$logoPath = Join-Path $docsDir 'logo.png'
$logo.Save($logoPath, [System.Drawing.Imaging.ImageFormat]::Png)
$logo.Dispose()
Write-Host ("Logo written: {0}" -f $logoPath)
