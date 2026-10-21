import { tag } from '@kit.ConnectivityKit';
import { Log } from './Log';

// Publicly readable identification data of a tag, taken only from TagInfo and the
// anti-collision / activation parameters. No sector, file or balance data is read.
export interface CardInfo {
  key: string;        // binding key, currently "uid:<hex>"
  uidHex: string;
  techs: string;      // e.g. "NfcA,IsoDep"
  sak: string;
  atqa: string;
  historical: string; // IsoDep historical bytes (ISO 14443-A) / hi-layer response (B)
  seenAt: number;
}

const TECH_NAMES: Record<number, string> = {
  1: 'NfcA', 2: 'NfcB', 3: 'IsoDep', 4: 'NfcF', 5: 'NfcV', 6: 'Ndef',
  7: 'NdefFormatable', 8: 'MifareClassic', 9: 'MifareUltralight', 10: 'Barcode'
};

export function hex(bytes: number[] | undefined): string {
  if (!bytes) { return ''; }
  return bytes.map((b: number) => (b & 0xff).toString(16).padStart(2, '0')).join('').toUpperCase();
}

export function readCard(info: tag.TagInfo): CardInfo {
  const techList: number[] = info.technology ?? [];
  const uidHex = hex(info.uid);
  let sak = '';
  let atqa = '';
  let historical = '';
  if (techList.includes(tag.NFC_A)) {
    try {
      const a = tag.getNfcA(info);
      sak = a.getSak().toString(16).padStart(2, '0').toUpperCase();
      atqa = hex(a.getAtqa());
    } catch (e) { Log.w(`NfcA params unavailable: ${JSON.stringify(e)}`); }
  }
  if (techList.includes(tag.ISO_DEP)) {
    try {
      const d = tag.getIsoDep(info);
      historical = hex(d.getHistoricalBytes()) || hex(d.getHiLayerResponse());
    } catch (e) { Log.w(`IsoDep params unavailable: ${JSON.stringify(e)}`); }
  }
  return {
    key: `uid:${uidHex}`,
    uidHex: uidHex,
    techs: techList.map((t: number) => TECH_NAMES[t] ?? `T${t}`).join(','),
    sak: sak,
    atqa: atqa,
    historical: historical,
    seenAt: Date.now()
  };
}

export function describe(c: CardInfo): string {
  return `UID=${c.uidHex || '(空)'} 技术=${c.techs} SAK=${c.sak || '-'} ATQA=${c.atqa || '-'} HB=${c.historical || '-'}`;
}
