import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { NfcLaunchFlow } from '../common/NfcLaunchFlow';
import { Log } from '../common/Log';

// Started by the system NFC service via tag-tech dispatch (action TAG_FOUND), e.g. transit
// cards. On this phone that path needs a notification tap and the app chooser first.
export default class NfcDispatchAbility extends UIAbility {
  private flow: NfcLaunchFlow = new NfcLaunchFlow();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Log.i(`NfcDispatchAbility onCreate (cold) reason=${launchParam.launchReason}`);
    this.flow.handle(this.context, want, 'NFC 分发(冷启动)');
  }

  onNewWant(want: Want): void {
    Log.i('NfcDispatchAbility onNewWant (warm)');
    this.flow.handle(this.context, want, 'NFC 分发(热启动)');
    // onForeground may not fire again if the ability is already visible.
    setTimeout(() => { this.flow.launchPending(this.context); }, 300);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    const storage = new LocalStorage();
    storage.setOrCreate('flow', this.flow);
    windowStage.loadContent('pages/Dispatch', storage, (err: BusinessError) => {
      if (err.code) { Log.e(`loadContent Dispatch failed ${err.code}`); }
    });
  }

  onForeground(): void {
    Log.i('NfcDispatchAbility onForeground');
    this.flow.launchPending(this.context);
  }

  onBackground(): void {
    Log.i('NfcDispatchAbility onBackground');
    if (this.flow.consumeLaunchedAway(this.context)) { this.context.terminateSelf(); }
  }

  onDestroy(): void {
    Log.i('NfcDispatchAbility onDestroy');
  }
}
