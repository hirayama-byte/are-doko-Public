Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null
Add-Type -AssemblyName System.Drawing | Out-Null

$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
  $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
})[0]
function Await($op, $resultType) {
  $m = $asTaskGeneric.MakeGenericMethod($resultType)
  $task = $m.Invoke($null, @($op)); $task.Wait(-1) | Out-Null; $task.Result
}
$asTaskAction = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
  $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction'
})[0]
function AwaitAction($action) {
  $task = $asTaskAction.Invoke($null, @($action)); $task.Wait(-1) | Out-Null
}

[Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime] | Out-Null
[Windows.Data.Pdf.PdfDocument,Windows.Data.Pdf,ContentType=WindowsRuntime] | Out-Null
[Windows.Storage.Streams.InMemoryRandomAccessStream,Windows.Storage.Streams,ContentType=WindowsRuntime] | Out-Null

$src = "G:\共有ドライブ\BOXからの移行データ\★媒体資料★\1.よく使う媒体資料"
$out = "C:\Users\c114059\AppData\Local\Temp\claude\C--Users-c114059\d9548507-e370-4d5d-831d-dea2f5660eac\scratchpad\thumbs"
if (-not (Test-Path $out)) { New-Item -ItemType Directory -Path $out | Out-Null }

$map = @(
  @{ row = 33; f = "SP事例集_ペライチver_K.pdf" }
  @{ row = 34; f = "★媒体資料_青色_2607.pdf" }
  @{ row = 35; f = "★媒体資料_黄_2507.pdf" }
  @{ row = 36; f = "アットカンパニー媒体資料_2604.pdf" }
  @{ row = 37; f = "ハイブリッド集客資料_K.pdf" }
  @{ row = 38; f = "情報誌の強みをご紹介(ポスティング需要).pdf" }
  @{ row = 39; f = "新LP商材_2604.pdf" }
  @{ row = 40; f = "新聞折り込み比較表_K.pdf" }
  @{ row = 41; f = "バイラルプラン資料_K.pdf" }
)

# JPEG エンコーダ（品質指定）
$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [int64]74)

foreach ($m in $map) {
  $path = Join-Path $src $m.f
  if (-not (Test-Path -LiteralPath $path)) { Write-Output ("MISSING=" + $m.f); continue }

  $file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($path)) ([Windows.Storage.StorageFile])
  $doc  = Await ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])
  $page = $doc.GetPage([uint32]0)

  $opts = New-Object Windows.Data.Pdf.PdfPageRenderOptions
  $opts.DestinationWidth = [uint32]1000
  $stream = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
  AwaitAction ($page.RenderToStreamAsync($stream, $opts))

  $reader = New-Object Windows.Storage.Streams.DataReader($stream.GetInputStreamAt(0))
  try { AwaitAction ($reader.LoadAsync([uint32]$stream.Size)) } catch {}
  $bytes = New-Object byte[] $stream.Size
  $reader.ReadBytes($bytes)

  # PNG バイト列 -> Bitmap -> 幅 620px にリサイズ -> JPEG
  $ms  = New-Object System.IO.MemoryStream(,$bytes)
  $img = [System.Drawing.Image]::FromStream($ms)
  $w   = 620
  $h   = [int][Math]::Round($img.Height * ($w / $img.Width))
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g   = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.Clear([System.Drawing.Color]::White)
  $g.DrawImage($img, 0, 0, $w, $h)

  $dest = Join-Path $out ("{0}.jpg" -f $m.row)
  $bmp.Save($dest, $jpegCodec, $encParams)

  $g.Dispose(); $bmp.Dispose(); $img.Dispose(); $ms.Dispose()
  $size = [int]((Get-Item -LiteralPath $dest).Length / 1024)
  Write-Output ("OK row=" + $m.row + " " + $w + "x" + $h + " " + $size + "KB pages=" + $doc.PageCount)
}
