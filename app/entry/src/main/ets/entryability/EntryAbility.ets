import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ReaderMode } from '../common/ReaderMode';
import { NfcLaunchFlow } from '../common/NfcLaunchFlow';
import { Log } from '../common/Log';
import { Store } from '../common/Store';

// Main UI, and also the target of the sticker's NDEF application record: the system NFC
// service starts the bundle's launch ability directly (want.uri = nfclauncher://tag/<id>,
// plus tag info), without notification or app chooser.
export default class EntryAbility extends UIAbility {
  private flow: NfcLaunchFlow = new NfcLaunchFlow();
  private coldNfcLaunch: boolean = false;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Log.i(`EntryAbility onCreate reason=${launchParam.launchReason} uri=${want.uri ?? ''}`);
    new Store(this.context).migrate();
    this.coldNfcLaunch = this.flow.handle(this.context, want, '贴纸直启(冷启动)');
  }

  onNewWant(want: Want): void {
    Log.i(`EntryAbility onNewWant uri=${want.uri ?? ''}`);
    if (this.flow.handle(this.context, want, '贴纸直启(热启动)')) {
      // onForeground may not fire again if the main UI is already visible.
      setTimeout(() => { this.flow.launchPending(this.context); }, 300);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    const storage = new LocalStorage();
    storage.setOrCreate('flow', this.flow);
    const page = this.coldNfcLaunch ? 'pages/Dispatch' : 'pages/Index';
    windowStage.loadContent(page, storage, (err: BusinessError) => {
      if (err.code) { Log.e(`loadContent ${page} failed ${err.code}`); }
    });
  }

  onForeground(): void {
    Log.i('EntryAbility onForeground');
    AppStorage.setOrCreate('tick', Date.now());
    this.flow.launchPending(this.context);
  }

  onBackground(): void {
    // readerMode is a foreground-only API; release it so background dispatch can be tested.
    if (ReaderMode.active) {
      ReaderMode.stop(this.context);
      AppStorage.setOrCreate('readerOn', false);
      AppStorage.setOrCreate('readerKind', '');
    }
    Log.i('EntryAbility onBackground');
    // Only a window that exists solely for an NFC launch is closed; a main UI the user
    // opened themselves stays in recents.
    if (this.flow.consumeLaunchedAway(this.context) && this.coldNfcLaunch) {
      this.context.terminateSelf();
    }
  }

  onDestroy(): void {
    Log.i('EntryAbility onDestroy');
  }
}
