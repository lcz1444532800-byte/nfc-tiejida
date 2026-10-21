# Reads launchable third-party apps from the connected HarmonyOS phone and prints catalog
# lines for app/entry/src/main/ets/common/AppCatalog.ets. Only package metadata is read
# (bm dump); no app is opened. Run only on a phone whose owner agreed.
# Usage: Collect-Apps.ps1 [-Only com.tencent.tmgp.sgame,...]
param([string[]]$Only = @())
$ErrorActionPreference = 'Stop'
$deveco = 'D:\SJTU-Hub-Tools\DevEcoStudio-26.0.0.851'
$hdc = Join-Path $deveco 'sdk\default\openharmony\toolchains\hdc.exe'
$node = Join-Path $deveco 'tools\node\node.exe'
$root = Split-Path $PSScriptRoot -Parent
$tmp = Join-Path $root 'work\tmp\dumps'
New-Item -ItemType Directory -Force $tmp | Out-Null

# bm dump output has trailing commas and keys that differ only by case (metaData/metadata),
# which Windows PowerShell's ConvertFrom-Json rejects, so the launcher ability is found with Node.
$finder = @'
const t = require('fs').readFileSync(process.argv[1], 'utf8').replace(/,\s*([}\]])/g, '$1');
const j = JSON.parse(t); const info = j.bundleInfo || j;
for (const m of info.hapModuleInfos || []) for (const a of m.abilityInfos || []) for (const s of a.skills || []) {
  const acts = s.actions || [], ents = s.entities || [];
  if ((acts.includes('ohos.want.action.home') || acts.includes('action.system.home')) && ents.includes('entity.system.home')) {
    console.log(a.name); process.exit(0);
  }
}
'@

$bundles = if ($Only.Count) { $Only } else {
  (& $hdc shell 'bm dump -a') | ForEach-Object { $_.Trim() } |
    Where-Object { $_ -match '^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$' -and $_ -notmatch '^(com\.huawei|com\.ohos|ohos\.|com\.hmos|com\.atomicservice\.)' }
}
$catalog = Get-Content (Join-Path $root 'app\entry\src\main\ets\common\AppCatalog.ets') -Raw
foreach ($b in $bundles) {
  $raw = (& $hdc shell "bm dump -n $b") -join "`n"
  $i = $raw.IndexOf('{')
  if ($i -lt 0) { Write-Output "// $b : not installed"; continue }
  $file = Join-Path $tmp "$b.json"
  [IO.File]::WriteAllText($file, $raw.Substring($i), (New-Object Text.UTF8Encoding($false)))
  $launcher = & $node -e $finder $file
  Remove-Item $file
  if (-not $launcher) { Write-Output "// $b : no launcher ability (service or widget only)"; continue }
  $known = if ($catalog.Contains("'$b'")) { '  // already in catalog' } else { '' }
  Write-Output ("  { name: '<NAME>', bundle: '$b', ability: '$launcher', category: '<CATEGORY>', keywords: '<pinyin initials>' },$known")
}
