# Opens the build copy in the already-deployed DevEco Studio (IDE data stays on D:).
# Needed once for account login + automatic signing of com.lcz.nfclauncher.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$ide = 'D:\SJTU-Hub-Tools\DevEcoStudio-26.0.0.851'
$data = 'D:\SJTU-Hub-Tools\user-data'
$properties = Join-Path $data 'devecostudio.properties'
if (-not (Test-Path -LiteralPath $properties)) { throw "Missing $properties (created by SJTU-Hub Start-DevEco.ps1)" }
$settings = @{
  DEVECOSTUDIO_PROPERTIES = $properties
  DEVECO_SDK_HOME = (Join-Path $ide 'sdk'); NODE_HOME = (Join-Path $ide 'tools\node'); JAVA_HOME = (Join-Path $ide 'jbr')
  HVIGOR_USER_HOME = (Join-Path $root 'caches\hvigor'); npm_config_cache = (Join-Path $root 'caches\npm')
  npm_config_registry = 'https://repo.huaweicloud.com/repository/npm/'
  TEMP = (Join-Path $data 'tmp'); TMP = (Join-Path $data 'tmp')
  PATH = ((Join-Path $ide 'jbr\bin') + ';' + (Join-Path $ide 'tools\node') + ';' + $env:PATH)
}
foreach ($k in $settings.Keys) { [Environment]::SetEnvironmentVariable($k, $settings[$k], 'Process') }
$p = Start-Process -FilePath (Join-Path $ide 'bin\devecostudio64.exe') -ArgumentList 'D:\NfcLauncher-Build' -WindowStyle Normal -PassThru
Write-Output ('DevEco Studio PID: ' + $p.Id)
