import { common, Want } from '@kit.AbilityKit';
import { tag } from '@kit.ConnectivityKit';
import { CardInfo, describe, readCard } from './CardInfo';
import { stickerIdFromUri } from './Sticker';
import { LaunchTarget, Store } from './Store';
import { launchTarget, LaunchResult } from './Launcher';
import { Log } from './Log';

// Identifies the card/sticker carried by a Want started by the system NFC service, then
// launches the bound app. Shared by NfcDispatchAbility (tag-tech dispatch, transit cards)
// and EntryAbility (direct NDEF application-record launch, stickers).
export class NfcLaunchFlow {
  private pending: LaunchTarget | undefined = undefined;
  private launchedAway: boolean = false;

  // Returns false when the Want carries neither a sticker URI nor tag info.
  handle(ctx: common.UIAbilityContext, want: Want, source: string): boolean {
    const stickerId = stickerIdFromUri(want.uri);
    let card: CardInfo | undefined = undefined;
    let tagErr = '';
    try {
      const c = readCard(tag.getTagInfo(want));
      // A normal launcher start also yields a TagInfo, but with no UID and no technology.
      if (c.uidHex || c.techs) { card = c; } else { tagErr = 'empty TagInfo'; }
    } catch (e) {
      tagErr = JSON.stringify(e);
    }
    if (!stickerId && !card) {
      if (want.action === 'ohos.nfc.tag.action.TAG_FOUND') {
        new Store(ctx).addEvent(`${source}: 收到 NFC 启动但无法读取卡片 ${tagErr}`);
        AppStorage.setOrCreate('dispatchMsg', '读取卡片失败');
        return true;
      }
      return false;
    }
    if (!card) {
      card = { key: '', uidHex: '', techs: '', sak: '', atqa: '', historical: '', seenAt: Date.now() };
    }
    if (stickerId) { card.key = `sticker:${stickerId}`; }
    const store = new Store(ctx);
    store.setLastCard(card);
    this.pending = store.getBinding(card.key);
    store.addEvent(`${source}: ${card.key} ${describe(card)}${this.pending ? ' 已绑定→' + this.pending.label : ' 未绑定'}`);
    AppStorage.setOrCreate('dispatchMsg', this.pending ? `正在打开${this.pending.label}…` : `「${store.getName(card.key)}」还没有绑定应用`);
    AppStorage.setOrCreate('tick', Date.now());
    return true;
  }

  hasPending(): boolean { return this.pending !== undefined; }

  // Must run while the ability is in the foreground.
  launchPending(ctx: common.UIAbilityContext): void {
    const target = this.pending;
    if (!target) { return; }
    this.pending = undefined;
    const store = new Store(ctx);
    launchTarget(ctx, target).then((result: LaunchResult) => {
      store.addEvent(`自动启动 ${target.label}: ok=${result.ok} code=${result.code}`);
      if (result.ok) {
        // Do not finish yet: the system may show its cross-app jump confirmation inside
        // our window (ecological rule). Finish once the target app has the foreground.
        this.launchedAway = true;
        AppStorage.setOrCreate('dispatchMsg', `正在打开${target.label}…`);
      } else {
        AppStorage.setOrCreate('dispatchMsg', result.message);
      }
    });
  }

  markLaunchedAway(): void { this.launchedAway = true; }

  // True when the ability should finish because the target app took the foreground.
  consumeLaunchedAway(ctx: common.UIAbilityContext): boolean {
    if (!this.launchedAway) { return false; }
    this.launchedAway = false;
    new Store(ctx).addEvent('target app in front, finishing');
    Log.i('launched away, finishing');
    return true;
  }
}
