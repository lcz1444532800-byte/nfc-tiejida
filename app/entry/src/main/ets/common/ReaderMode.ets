import { tag } from '@kit.ConnectivityKit';
import { bundleManager, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CardInfo, describe, readCard } from './CardInfo';
import { writeSticker, WriteResult } from './Sticker';
import { Store } from './Store';
import { Log } from './Log';

// Foreground reader mode: only valid while EntryAbility is in the foreground.
//  'read'  - show card identification data
//  'write' - write the launcher NDEF content to the next sticker, then stop
export type ReaderKind = 'read' | 'write';

const TECHS: number[] = [tag.NFC_A, tag.NFC_B, tag.ISO_DEP, tag.NFC_F, tag.NFC_V, tag.MIFARE_CLASSIC];

function element(ctx: common.UIAbilityContext): bundleManager.ElementName {
  return { bundleName: ctx.abilityInfo.bundleName, abilityName: ctx.abilityInfo.name };
}

function status(text: string): void {
  AppStorage.setOrCreate('readerStatus', text);
  AppStorage.setOrCreate('tick', Date.now());
}

export class ReaderMode {
  static active: boolean = false;
  static kind: ReaderKind = 'read';
  private static writing: boolean = false;

  static start(ctx: common.UIAbilityContext, kind: ReaderKind): string {
    if (ReaderMode.active) { ReaderMode.stop(ctx); }
    const store = new Store(ctx);
    ReaderMode.kind = kind;
    try {
      tag.on('readerMode', element(ctx), TECHS, (err: BusinessError, info: tag.TagInfo) => {
        if (err) {
          store.addEvent(`前台读卡回调错误 code=${err.code}`);
          return;
        }
        if (ReaderMode.kind === 'write') {
          ReaderMode.onWriteTag(ctx, store, info);
          return;
        }
        const card: CardInfo = readCard(info);
        if (!card.uidHex) { status('没有读到卡片标识，请把卡片贴紧手机背面重试'); return; }
        store.setLastCard(card);
        store.addEvent(`前台读卡: ${describe(card)}`);
        ReaderMode.finish(ctx, '');
        AppStorage.setOrCreate('newCardKey', card.key);
      });
      ReaderMode.active = true;
      AppStorage.setOrCreate('readerOn', true);
      AppStorage.setOrCreate('readerKind', kind);
      status(kind === 'write' ? '把空白贴纸贴到手机背面摄像头附近，保持不动' : '把卡片贴到手机背面摄像头附近');
      return '';
    } catch (e) {
      const err = e as BusinessError;
      Log.e(`readerMode on failed ${err.code} ${err.message}`);
      return `开启读卡模式失败 code=${err.code} ${err.message}`;
    }
  }

  private static onWriteTag(ctx: common.UIAbilityContext, store: Store, info: tag.TagInfo): void {
    if (ReaderMode.writing) { return; }
    ReaderMode.writing = true;
    status('正在写入，请保持贴纸不动…');
    writeSticker(info).then((r: WriteResult) => {
      ReaderMode.writing = false;
      store.addEvent(`写入贴纸: ${r.text}`);
      if (r.ok && r.card) {
        store.setLastCard(r.card);
        ReaderMode.finish(ctx, '');
        AppStorage.setOrCreate('newCardKey', r.card.key);
      } else {
        status(r.text);
      }
    });
  }

  static finish(ctx: common.UIAbilityContext, text: string): void {
    ReaderMode.stop(ctx);
    AppStorage.setOrCreate('readerOn', false);
    AppStorage.setOrCreate('readerKind', '');
    status(text);
  }

  static stop(ctx: common.UIAbilityContext): void {
    if (!ReaderMode.active) { return; }
    try {
      tag.off('readerMode', element(ctx));
    } catch (e) {
      Log.w(`readerMode off failed ${JSON.stringify(e)}`);
    }
    ReaderMode.active = false;
  }
}
