import { tag } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CardInfo, readCard } from './CardInfo';

// Sticker content, two NDEF records:
//  [0] URI  nfclauncher://tag/<id>   -> passed to the app as want.uri; also a fallback route
//                                       (system App Linking dispatch) if [1] is not honoured.
//  [1] OpenHarmony application record (ohos.com:pkg = our bundle). The system NFC service
//      starts our launch ability directly for this record: no notification, no app chooser.
export const STICKER_SCHEME = 'nfclauncher';
const STICKER_PREFIX = 'nfclauncher://tag/';
const BUNDLE = 'com.lcz.nfclauncher';
const MARKER = 'nfclauncher';

export function stickerIdFromUri(uri: string | undefined): string {
  if (!uri || !uri.startsWith(STICKER_PREFIX)) { return ''; }
  const id = uri.substring(STICKER_PREFIX.length).toUpperCase();
  return /^[0-9A-F]{8}$/.test(id) ? id : '';
}

function newStickerId(): string {
  let id = '';
  for (let i = 0; i < 8; i++) { id += Math.floor(Math.random() * 16).toString(16); }
  return id.toUpperCase();
}

function containsMarker(msg: tag.NdefMessage | null | undefined): boolean {
  if (!msg) { return false; }
  const bytes = tag.ndef.messageToBytes(msg);
  return String.fromCharCode(...bytes).includes(MARKER);
}

export interface WriteResult { ok: boolean; text: string; card?: CardInfo }

// Only plain NFC Forum stickers (NTAG21x / Ultralight family) are accepted. Transit, bank
// and access cards (IsoDep, MIFARE Classic) are refused: formatting them as NDEF would
// overwrite their sector keys and could make them unusable.
export async function writeSticker(info: tag.TagInfo): Promise<WriteResult> {
  const techs: number[] = info.technology ?? [];
  if (techs.includes(tag.ISO_DEP) || techs.includes(tag.MIFARE_CLASSIC)) {
    return { ok: false, text: '拒绝写入：这是交通卡/银行卡/门禁卡一类的卡片，不能写。请换 NTAG213/215 贴纸' };
  }
  const id = newStickerId();
  const message = tag.ndef.createNdefMessage([
    tag.ndef.makeUriRecord(STICKER_PREFIX + id),
    tag.ndef.makeApplicationRecord(BUNDLE)
  ]);
  try {
    if (techs.includes(tag.NDEF)) {
      const ndef = tag.getNdef(info);
      const existing = ndef.getNdefMessage();
      if (existing && tag.ndef.messageToBytes(existing).length > 3 && !containsMarker(existing)) {
        return { ok: false, text: '贴纸里已有其他内容，为避免误覆盖没有写入（请换一张空白贴纸）' };
      }
      if (!ndef.isConnected()) { ndef.connect(); }
      if (!ndef.isNdefWritable()) { return { ok: false, text: '贴纸是只读的，无法写入' }; }
      await ndef.writeNdef(message);
    } else if (techs.includes(tag.NDEF_FORMATABLE) && techs.includes(tag.MIFARE_ULTRALIGHT)) {
      const f = tag.getNdefFormatable(info);
      if (!f.isConnected()) { f.connect(); }
      await f.format(message);
    } else {
      return { ok: false, text: '这不是可写的 NDEF 贴纸（没有 Ndef / NdefFormatable 技术）' };
    }
  } catch (e) {
    const err = e as BusinessError;
    // 3100204 = tag left the field during the write, the common case.
    return { ok: false, text: err.code === 3100204 ? '贴纸移开了，请保持不动再试一次' : `写入失败（错误码 ${err.code}），请重试` };
  }
  const card = readCard(info);
  card.key = `sticker:${id}`;
  return { ok: true, text: '写入成功', card: card };
}
