import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { CardInfo } from './CardInfo';
import { Log } from './Log';

// Everything is stored locally in one preferences file; nothing leaves the phone.
export interface LaunchTarget {
  label: string;
  bundleName: string;
  abilityName: string;
  link: string; // custom link opened with openLink; '' for a plain app launch
}

export interface BindingRow {
  key: string;
  name: string;
  target: LaunchTarget;
}

const BINDING_PREFIX = 'bind:';
const NAME_PREFIX = 'name:';
const KEY_LAST_CARD = 'lastCard';
// privacyAgreedVersion: the app's own consent screen, replaced by system privacy hosting.
const KEY_LEGACY = ['events', 'launchMethod', 'privacyAgreedVersion'];

export class Store {
  private prefs: preferences.Preferences;

  constructor(context: Context) {
    this.prefs = preferences.getPreferencesSync(context, { name: 'nfc_launcher' });
  }

  // A key must identify one card or sticker: "uid:<hex>" or "sticker:<id>".
  static isValidKey(cardKey: string): boolean {
    return /^(uid|sticker):[0-9A-F]+$/.test(cardKey);
  }

  static isSticker(cardKey: string): boolean {
    return cardKey.startsWith('sticker:');
  }

  // Removes data from earlier builds: bindings under an empty/invalid key (a launcher start
  // misread as an NFC start) and the debug event log / launch-method setting.
  migrate(): void {
    const all = this.prefs.getAllSync() as Record<string, Object>;
    Object.keys(all).forEach((k: string) => {
      const isBind = k.startsWith(BINDING_PREFIX) || k.startsWith(NAME_PREFIX);
      const key = k.substring(k.indexOf(':') + 1);
      if ((isBind && !Store.isValidKey(key)) || KEY_LEGACY.includes(k)) {
        this.prefs.deleteSync(k);
        Log.i(`migrate: removed ${k}`);
      }
    });
    const last = this.getLastCard();
    if (last && !Store.isValidKey(last.key)) { this.prefs.deleteSync(KEY_LAST_CARD); }
    // Bindings saved before stickers had names get a default one.
    this.listBindings().forEach((b: BindingRow) => {
      if (!this.prefs.hasSync(NAME_PREFIX + b.key)) {
        this.prefs.putSync(NAME_PREFIX + b.key, this.defaultName(b.key));
      }
    });
    this.prefs.flushSync();
  }

  getBinding(cardKey: string): LaunchTarget | undefined {
    const raw = this.prefs.getSync(BINDING_PREFIX + cardKey, '') as string;
    return raw ? JSON.parse(raw) as LaunchTarget : undefined;
  }

  setBinding(cardKey: string, target: LaunchTarget): boolean {
    if (!Store.isValidKey(cardKey)) {
      Log.w(`refused binding for invalid key "${cardKey}"`);
      return false;
    }
    this.prefs.putSync(BINDING_PREFIX + cardKey, JSON.stringify(target));
    if (!this.prefs.hasSync(NAME_PREFIX + cardKey)) {
      this.prefs.putSync(NAME_PREFIX + cardKey, this.defaultName(cardKey));
    }
    this.prefs.flushSync();
    Log.i(`bind ${cardKey} -> ${target.label}`);
    return true;
  }

  removeBinding(cardKey: string): void {
    this.prefs.deleteSync(BINDING_PREFIX + cardKey);
    this.prefs.deleteSync(NAME_PREFIX + cardKey);
    this.prefs.flushSync();
    Log.i(`unbind ${cardKey}`);
  }

  getName(cardKey: string): string {
    return (this.prefs.getSync(NAME_PREFIX + cardKey, '') as string) || this.defaultName(cardKey);
  }

  setName(cardKey: string, name: string): void {
    const n = name.trim().substring(0, 20);
    if (!Store.isValidKey(cardKey) || !n) { return; }
    this.prefs.putSync(NAME_PREFIX + cardKey, n);
    this.prefs.flushSync();
  }

  // Smallest "贴纸 N" / "卡片 N" not already used by a saved name.
  private defaultName(cardKey: string): string {
    const kind = Store.isSticker(cardKey) ? '贴纸' : '卡片';
    const all = this.prefs.getAllSync() as Record<string, Object>;
    const taken = new Set<string>();
    Object.keys(all).forEach((k: string) => {
      if (k.startsWith(NAME_PREFIX) && k !== NAME_PREFIX + cardKey) { taken.add(all[k] as string); }
    });
    let n = 1;
    while (taken.has(`${kind} ${n}`)) { n++; }
    return `${kind} ${n}`;
  }

  listBindings(): BindingRow[] {
    const all = this.prefs.getAllSync() as Record<string, Object>;
    const out: BindingRow[] = [];
    Object.keys(all).forEach((k: string) => {
      if (k.startsWith(BINDING_PREFIX)) {
        const key = k.substring(BINDING_PREFIX.length);
        const name = (all[NAME_PREFIX + key] as string) ?? '';
        out.push({ key: key, name: name || key, target: JSON.parse(all[k] as string) as LaunchTarget });
      }
    });
    return out.sort((a: BindingRow, b: BindingRow) => a.name.localeCompare(b.name));
  }

  getLastCard(): CardInfo | undefined {
    const raw = this.prefs.getSync(KEY_LAST_CARD, '') as string;
    return raw ? JSON.parse(raw) as CardInfo : undefined;
  }

  setLastCard(card: CardInfo): void {
    this.prefs.putSync(KEY_LAST_CARD, JSON.stringify(card));
    this.prefs.flushSync();
  }

  // Kept for call sites; diagnostic messages go to hilog only and are not stored.
  addEvent(text: string): void {
    Log.i(`event: ${text}`);
  }
}
