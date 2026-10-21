# Device helper. Usage: Device.ps1 install | start | stop | log-start <name> | log-stop | front | bindings
param([Parameter(Mandatory)][string]$Cmd, [string]$Arg = '')
$hdc = 'D:\SJTU-Hub-Tools\DevEcoStudio-26.0.0.851\sdk\default\openharmony\toolchains\hdc.exe'
$bundle = 'com.lcz.nfclauncher'
$root = Split-Path $PSScriptRoot -Parent
$ev = Join-Path $root 'evidence\device'; New-Item -ItemType Directory -Force $ev | Out-Null
$pidFile = Join-Path $ev '.hilog.pid'
switch ($Cmd) {
  'install' {
    $hap = 'D:\NfcLauncher-Build\entry\build\default\outputs\default\entry-default-signed.hap'
    & $hdc install -r $hap
  }
  'start' { & $hdc shell "aa start -b $bundle -a EntryAbility" }
  'stop' { & $hdc shell "aa force-stop $bundle" }
  'log-start' {
    & $hdc shell 'hilog -r' | Out-Null
    $f = Join-Path $ev ("hilog-$Arg-" + (Get-Date -Format 'HHmmss') + '.txt')
    $p = Start-Process -FilePath $hdc -ArgumentList 'shell','hilog' -RedirectStandardOutput $f -NoNewWindow -PassThru
    "$($p.Id)|$f" | Set-Content $pidFile
    Write-Output "capturing to $f"
  }
  'log-stop' {
    $parts = (Get-Content $pidFile) -split '\|'
    Stop-Process -Id ([int]$parts[0]) -ErrorAction SilentlyContinue
    Remove-Item $pidFile
    Write-Output $parts[1]
  }
  'front' { & $hdc shell 'aa dump -l' | Select-String -Pattern 'bundle name|state #' | Select-Object -First 8 }
}
