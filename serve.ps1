# IRONBLOOD browser version: a tiny local web server for Windows.
# Browsers will not run a game straight from a folder (file://), so this
# serves the files in this folder at http://localhost:8060/ and opens the
# game in your default browser. Close this window to stop it.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$types = @{
	'.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript'; '.wasm' = 'application/wasm';
	'.pck' = 'application/octet-stream'; '.png' = 'image/png'; '.svg' = 'image/svg+xml';
	'.ico' = 'image/x-icon'; '.json' = 'application/json'; '.txt' = 'text/plain; charset=utf-8'
}

$listener = $null
foreach ($port in 8060..8070) {
	$l = New-Object System.Net.HttpListener
	$l.Prefixes.Add("http://localhost:$port/")
	try { $l.Start(); $listener = $l; break } catch { $l.Close() }
}
if ($listener -eq $null) { Write-Host 'Could not open a local port (8060-8070).'; Read-Host 'Press Enter to close'; exit 1 }

$url = $listener.Prefixes | Select-Object -First 1
Write-Host "IRONBLOOD is being served at $url"
Write-Host 'Your browser opens by itself. Keep this window open while you play; close it to stop.'
try { Start-Process $url } catch { Write-Host "Open $url in your browser." }

while ($listener.IsListening) {
	$ctx = $listener.GetContext()
	$req = $ctx.Request
	$res = $ctx.Response
	try {
		$path = [Uri]::UnescapeDataString($req.Url.AbsolutePath.TrimStart('/'))
		if ($path -eq '') { $path = 'index.html' }
		$full = [IO.Path]::GetFullPath((Join-Path $root $path))
		if (-not $full.StartsWith($root) -or -not (Test-Path -LiteralPath $full -PathType Leaf)) {
			$res.StatusCode = 404
		} else {
			$ext = [IO.Path]::GetExtension($full).ToLower()
			$res.ContentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { 'application/octet-stream' }
			$res.AddHeader('Cache-Control', 'no-cache')
			$fs = [IO.File]::OpenRead($full)
			try {
				$res.ContentLength64 = $fs.Length
				if ($req.HttpMethod -ne 'HEAD') { $fs.CopyTo($res.OutputStream) }
			} finally { $fs.Close() }
		}
	} catch {
		# The browser closed the connection early; nothing to do.
	} finally {
		try { $res.Close() } catch {}
	}
}
