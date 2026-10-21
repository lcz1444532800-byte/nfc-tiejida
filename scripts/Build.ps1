# Sync source to an ASCII-path build copy (Hvigor rejects Chinese paths) and run Hvigor.
# Environment changes are process-scoped only. Signing config lives only in the build copy.
param([string[]]$Tasks = @('assembleHap'))
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root 'app'
$build = 'D:\NfcLauncher-Build'
$deveco = 'D:\SJTU-Hub-Tools\DevEcoStudio-26.0.0.851'
$marker = Join-Path $build '.nfclauncher-owned'
if (Test-Path -LiteralPath $build) {
  if (-not (Test-Path -LiteralPath $marker)) { throw "Refusing to modify unowned directory $build" }
} else {
  New-Item -ItemType Directory -Path $build | Out-Null
  [IO.File]::WriteAllText($marker, 'Build copy; authoritative source is D:\codex项目默认\NfcLauncher\app')
}
# Sources: everything under app except root build-profile.json5 when the copy already has
# one (it carries the IDE-generated signingConfig).
Get-ChildItem -LiteralPath $source -Recurse -File | ForEach-Object {
  $rel = $_.FullName.Substring($source.Length + 1)
  $dst = Join-Path $build $rel
  if ($rel -eq 'build-profile.json5' -and (Test-Path -LiteralPath $dst)) { return }
  New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
  Copy-Item -LiteralPath $_.FullName -Destination $dst -Force
}
$cache = Join-Path $root 'caches'; $tmp = Join-Path $root 'work\tmp'; $ev = Join-Path $root 'evidence\build'
foreach ($d in @($cache, $tmp, $ev)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
[IO.File]::WriteAllText((Join-Path $build '.ohpmrc'), ("cache=" + (Join-Path $cache 'ohpm').Replace('\','/') + "`n"), (New-Object Text.UTF8Encoding($false)))
$settings = @{
  HVIGOR_USER_HOME = (Join-Path $cache 'hvigor'); DEVECO_SDK_HOME = (Join-Path $deveco 'sdk')
  NODE_HOME = (Join-Path $deveco 'tools\node'); JAVA_HOME = (Join-Path $deveco 'jbr')
  PATH = ((Join-Path $deveco 'jbr\bin') + ';' + (Join-Path $deveco 'tools\node') + ';' + $env:PATH)
  npm_config_cache = (Join-Path $cache 'npm'); npm_config_registry = 'https://repo.huaweicloud.com/repository/npm/'
  TEMP = $tmp; TMP = $tmp
}
foreach ($k in $settings.Keys) { [Environment]::SetEnvironmentVariable($k, $settings[$k], 'Process') }
$log = Join-Path $ev ('build-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
Push-Location $build
$ErrorActionPreference = 'Continue'  # Hvigor writes warnings to stderr
try {
  & (Join-Path $deveco 'tools\node\node.exe') (Join-Path $deveco 'tools\hvigor\bin\hvigorw.js') --mode module -p product=default -p module=entry@default -p buildMode=debug @Tasks --no-daemon 2>&1 | Tee-Object -FilePath $log
  $code = $LASTEXITCODE
} finally { Pop-Location }
Get-ChildItem (Join-Path $build 'entry\build\default\outputs\default') -Filter *.hap -ErrorAction SilentlyContinue | Select-Object Name, Length
Write-Output "Hvigor exit code: $code. Log: $log"
exit $code
