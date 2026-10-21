# Builds the signed release package (.app) for AppGallery upload.
# The key store password is read from D:\NfcLauncher-Release\keystore-password.txt, put into
# the build copy's build-profile.json5 only for this run, and the original file is restored
# afterwards. It is never printed or written to the source tree or the build log folder.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$rel = 'D:\NfcLauncher-Release'
$build = 'D:\NfcLauncher-Build'
$deveco = 'D:\SJTU-Hub-Tools\DevEcoStudio-26.0.0.851'
foreach ($f in 'nfctiejida.p12', 'nfctiejida.cer', 'nfctiejida.p7b', 'keystore-password.txt') {
  if (-not (Test-Path (Join-Path $rel $f))) { throw "Missing $rel\$f" }
}
$pwdLine = (Get-Content (Join-Path $rel 'keystore-password.txt') -Encoding UTF8) | Where-Object { $_ -match ':\s*([A-Za-z0-9]{20})\s*$' } | Select-Object -First 1
if (-not ($pwdLine -match ':\s*([A-Za-z0-9]{20})\s*$')) { throw 'Password not found in keystore-password.txt' }
$plain = $Matches[1]

# Hvigor only accepts passwords encrypted with the signing "material" next to the key store.
# Reuse the material DevEco generated on this PC (copied; C: is not modified).
$material = Join-Path $rel 'material'
if (-not (Test-Path $material)) { Copy-Item -Recurse 'C:\Users\14445\.ohos\config\material' $material }
$env:NFCL_PWD = $plain
$pwd = & (Join-Path $deveco 'tools\node\node.exe') (Join-Path $PSScriptRoot 'encrypt-signing-pwd.js') $rel
$encOk = ($LASTEXITCODE -eq 0)
Remove-Item Env:NFCL_PWD
if (-not $encOk -or $pwd -notmatch '^[0-9a-f]{64,}$') { throw 'Password encryption failed' }

# Sync sources into the build copy first (same as debug builds), without building yet.
& (Join-Path $PSScriptRoot 'Build.ps1') -Tasks @('clean') | Out-Null

$profilePath = Join-Path $build 'build-profile.json5'
$original = [IO.File]::ReadAllText($profilePath)
$esc = { param($p) $p.Replace('\', '\\') }
$release = @"
      {
        "name": "release",
        "type": "HarmonyOS",
        "material": {
          "certpath": "$(& $esc (Join-Path $rel 'nfctiejida.cer'))",
          "keyAlias": "release",
          "keyPassword": "$pwd",
          "profile": "$(& $esc (Join-Path $rel 'nfctiejida.p7b'))",
          "signAlg": "SHA256withECDSA",
          "storeFile": "$(& $esc (Join-Path $rel 'nfctiejida.p12'))",
          "storePassword": "$pwd"
        }
      },
"@
$patched = $original -replace '("signingConfigs"\s*:\s*\[)', "`$1`n$release"
$patched = $patched -replace '"signingConfig"\s*:\s*"default"', '"signingConfig": "release"'
if ($patched -eq $original -or $patched -notmatch '"signingConfig": "release"') { throw 'Could not patch build-profile.json5' }

$out = Join-Path $rel 'out'
New-Item -ItemType Directory -Force $out | Out-Null
$log = Join-Path $out ('release-build-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
$settings = @{
  HVIGOR_USER_HOME = (Join-Path $root 'caches\hvigor'); DEVECO_SDK_HOME = (Join-Path $deveco 'sdk')
  NODE_HOME = (Join-Path $deveco 'tools\node'); JAVA_HOME = (Join-Path $deveco 'jbr')
  PATH = ((Join-Path $deveco 'jbr\bin') + ';' + (Join-Path $deveco 'tools\node') + ';' + $env:PATH)
  TEMP = (Join-Path $root 'work\tmp'); TMP = (Join-Path $root 'work\tmp')
}
foreach ($k in $settings.Keys) { [Environment]::SetEnvironmentVariable($k, $settings[$k], 'Process') }
try {
  [IO.File]::WriteAllText($profilePath, $patched, (New-Object Text.UTF8Encoding($false)))
  Push-Location $build
  $ErrorActionPreference = 'Continue'
  & (Join-Path $deveco 'tools\node\node.exe') (Join-Path $deveco 'tools\hvigor\bin\hvigorw.js') `
    --mode project -p product=default -p buildMode=release assembleApp --no-daemon 2>&1 |
    ForEach-Object { "$_".Replace($plain, '***').Replace($pwd, '***') } | Tee-Object -FilePath $log | Out-Null
  $code = $LASTEXITCODE
} finally {
  Pop-Location
  [IO.File]::WriteAllText($profilePath, $original, (New-Object Text.UTF8Encoding($false)))
}
$app = Get-ChildItem (Join-Path $build 'build\outputs\default') -Filter '*.app' -ErrorAction SilentlyContinue
foreach ($a in $app) { Copy-Item $a.FullName $out -Force }
Get-ChildItem $out -Filter '*.app' | Select-Object Name, Length
Write-Output "Hvigor exit code: $code. Log: $log"
exit $code
