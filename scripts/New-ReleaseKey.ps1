# Creates the release key store (.p12) and certificate signing request (.csr) for
# AppGallery Connect. A random password is generated locally and written only to
# keystore-password.txt next to the key store; it is never printed.
# Same algorithms as DevEco "Generate Key and CSR": ECC NIST-P-256, SHA256withECDSA.
$ErrorActionPreference = 'Stop'
$deveco = 'D:\SJTU-Hub-Tools\DevEcoStudio-26.0.0.851'
$java = Join-Path $deveco 'jbr\bin\java.exe'
$tool = Join-Path $deveco 'sdk\default\openharmony\toolchains\lib\hap-sign-tool.jar'
$dir = 'D:\NfcLauncher-Release'
$p12 = Join-Path $dir 'nfctiejida.p12'
$csr = Join-Path $dir 'nfctiejida.csr'
$pwdFile = Join-Path $dir 'keystore-password.txt'
$alias = 'release'

if (Test-Path $p12) { throw "Key store already exists: $p12 (refusing to overwrite)" }
New-Item -ItemType Directory -Force $dir | Out-Null

# 20 chars from an unambiguous alphabet, guaranteed to contain letters and digits.
$alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
do {
  $bytes = New-Object byte[] 20
  $rng.GetBytes($bytes)
  $pwd = -join ($bytes | ForEach-Object { $alphabet[$_ % $alphabet.Length] })
} until ($pwd -match '[A-Za-z]' -and $pwd -match '\d')

$note = @"
NFC贴即达 发布密钥库
密钥库文件: $p12
别名 (alias): $alias
密钥库密码 = 别名密码: $pwd

请把本文件和 nfctiejida.p12 一起备份到安全的地方（U 盘、网盘）。
丢失后将无法再更新 com.lcz.nfclauncher。
"@
[IO.File]::WriteAllText($pwdFile, $note, (New-Object Text.UTF8Encoding($true)))

& $java -jar $tool generate-keypair -keyAlias $alias -keyAlg ECC -keySize NIST-P-256 `
  -keystoreFile $p12 -keyPwd $pwd -keystorePwd $pwd 2>&1 | Out-Null
if (-not (Test-Path $p12)) { throw 'generate-keypair failed' }

& $java -jar $tool generate-csr -keyAlias $alias -keyPwd $pwd `
  -subject 'C=CN,O=NFC Tiejida,OU=Release,CN=release' -signAlg SHA256withECDSA `
  -keystoreFile $p12 -keystorePwd $pwd -outFile $csr 2>&1 | Out-Null
if (-not (Test-Path $csr)) { throw 'generate-csr failed' }

Get-ChildItem $dir | Select-Object Name, Length
