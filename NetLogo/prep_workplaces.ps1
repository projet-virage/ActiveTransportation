# One-off preprocessing for the NetLogo port.
#
# workplaces.shp holds 1,303,891 points but its .dbf weighs 705 MB (names,
# descriptions, postal codes) that the model never uses. NetLogo's GIS
# extension would load every attribute into memory, so we read only the point
# geometry straight from the .shp binary and write "x y" (MTM-8 metres) lines.
#
# No Python / GDAL needed. Usage (from the NetLogo folder):
#   powershell -ExecutionPolicy Bypass -File prep_workplaces.ps1
# Optional: -Shp <path to workplaces.shp> -Out <output file>

param(
  [string]$Shp = (Join-Path $PSScriptRoot '..\data\Transportation_UrbanHealth\workplaces.shp'),
  [string]$Out = (Join-Path $PSScriptRoot 'derived\workplaces_xy.txt')
)

$ErrorActionPreference = 'Stop'
$Shp = (Resolve-Path $Shp).Path
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null

function Read-BigEndianInt32([IO.BinaryReader]$r) {
  $b = $r.ReadBytes(4); [Array]::Reverse($b); [BitConverter]::ToInt32($b, 0)
}

$inv = [Globalization.CultureInfo]::InvariantCulture
$fs = [IO.File]::OpenRead($Shp)
$br = New-Object IO.BinaryReader($fs)
$sw = New-Object IO.StreamWriter($Out, $false, (New-Object Text.UTF8Encoding($false)))

try {
  $fs.Position = 32
  $shapeType = $br.ReadInt32()
  if ($shapeType -ne 1) { throw "Expected a Point shapefile (type 1), got type $shapeType" }
  $fs.Position = 100

  $n = 0; $skipped = 0
  while ($fs.Position -lt $fs.Length) {
    [void](Read-BigEndianInt32 $br)                  # record number
    $contentBytes = 2 * (Read-BigEndianInt32 $br)    # content length (16-bit words)
    $start = $fs.Position
    $type = $br.ReadInt32()
    if ($type -eq 1) {
      $x = $br.ReadDouble(); $y = $br.ReadDouble()
      $sw.Write($x.ToString('R', $inv)); $sw.Write(' '); $sw.WriteLine($y.ToString('R', $inv))
      $n++
    } else {
      $skipped++                                     # null shape
    }
    $fs.Position = $start + $contentBytes
  }
} finally {
  $sw.Close(); $br.Close()
}

Write-Host "Wrote $n workplace points to $Out (skipped $skipped null shapes)"
