// Encrypts a signing password in the format Hvigor's DecipherUtil expects, so a release
// signingConfig can be used from the command line. Standalone re-implementation of
// hvigor-ohos-plugin/src/utils/decipher-util.js (key derivation from <storeFile dir>/material,
// AES-128-GCM, layout: len(ciphertext+tag) (4, big-endian) | iv | ciphertext | 16-byte tag).
// Usage:
//   NFCL_PWD=<password> node encrypt-signing-pwd.js <storeFileDir>   -> prints hex ciphertext
//   node encrypt-signing-pwd.js --check <storeFileDir> <hex>          -> prints decrypted length
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const COMPONENT = Buffer.from(new Int8Array([49, 243, 9, 115, 214, 175, 91, 184, 211, 190, 177, 88, 101, 131, 192, 119]).buffer);

function readSingleFile(dir) {
  const files = fs.readdirSync(dir).filter((f) => f !== '.DS_Store');
  if (files.length !== 1) { throw new Error(`expected one file in ${dir}`); }
  return fs.readFileSync(path.join(dir, files[0]));
}

function decrypt(key, data) {
  const ivLen = data.length - 4 - data.readUInt32BE(0);
  const iv = data.subarray(4, 4 + ivLen);
  const d = crypto.createDecipheriv('aes-128-gcm', key, iv);
  d.setAuthTag(data.subarray(data.length - 16));
  return Buffer.concat([d.update(data.subarray(4 + ivLen, data.length - 16)), d.final()]);
}

function workKey(storeDir) {
  const material = path.join(path.resolve(storeDir), 'material');
  const fdDir = path.join(material, 'fd');
  const parts = fs.readdirSync(fdDir).filter((f) => f !== '.DS_Store').map((f) => readSingleFile(path.join(fdDir, f)));
  if (parts.length !== 3) { throw new Error('material/fd must hold 3 parts'); }
  let x = Buffer.from(parts[0]);
  for (const p of [...parts.slice(1), COMPONENT]) {
    if (p.length !== 16) { throw new Error('material part is not 16 bytes'); }
    x = Buffer.from(x.map((b, i) => b ^ p[i]));
  }
  // Hvigor passes Buffer.toString() (UTF-8) as the PBKDF2 password; replicate exactly.
  const rootKey = crypto.pbkdf2Sync(x.toString(), readSingleFile(path.join(material, 'ac')), 10000, 16, 'sha256');
  return decrypt(rootKey, readSingleFile(path.join(material, 'ce')));
}

if (process.argv[2] === '--check') {
  const plain = decrypt(workKey(process.argv[3]), Buffer.from(process.argv[4], 'hex'));
  process.stdout.write(`decrypted ${plain.length} chars`);
} else {
  const dir = process.argv[2];
  const pwd = process.env.NFCL_PWD;
  if (!dir || !pwd) { console.error('usage: NFCL_PWD=... node encrypt-signing-pwd.js <dir>'); process.exit(2); }
  const key = workKey(dir);
  const iv = crypto.randomBytes(12);
  const c = crypto.createCipheriv('aes-128-gcm', key, iv);
  const ct = Buffer.concat([c.update(Buffer.from(pwd, 'utf-8')), c.final()]);
  const tag = c.getAuthTag();
  const len = Buffer.alloc(4); len.writeUInt32BE(ct.length + tag.length);
  const out = Buffer.concat([len, iv, ct, tag]);
  if (decrypt(key, out).toString('utf-8') !== pwd) { console.error('round trip failed'); process.exit(1); }
  process.stdout.write(out.toString('hex').toUpperCase());
}
