import { common } from '@kit.AbilityKit';
import { Store } from '../common/Store';
import { APP_NAME } from '../common/AppInfo';

// Shown while handling an NFC launch. For a bound card it only flashes "正在打开…" before
// the target app takes over; for an unbound card it offers to bind it.
@Entry
@Component
struct Dispatch {
  @StorageProp('dispatchMsg') msg: string = '';
  @StorageProp('tick') @Watch('reload') tick: number = 0;
  @State cardKey: string = '';
  @State bound: boolean = false;

  aboutToAppear(): void { this.reload(); }
  onPageShow(): void { this.reload(); }

  reload(): void {
    const store = new Store(this.ctx());
    const card = store.getLastCard();
    this.cardKey = card?.key ?? '';
    this.bound = this.cardKey !== '' && store.getBinding(this.cardKey) !== undefined;
  }

  ctx(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  goBind(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/Picker', params: { key: this.cardKey } });
  }

  build() {
    Column({ space: 16 }) {
      Text(APP_NAME).fontSize(15).fontColor($r('app.color.subtext'))
      Text(this.msg).fontSize(20).fontWeight(FontWeight.Medium).fontColor($r('app.color.text'))
        .textAlign(TextAlign.Center)
      if (this.cardKey && !this.bound) {
        Button('选择要打开的应用').width('80%').height(46)
          .backgroundColor($r('app.color.accent')).fontColor($r('app.color.on_accent'))
          .onClick(() => this.goBind())
      }
      Button('关闭').width('80%').backgroundColor($r('app.color.surface')).fontColor($r('app.color.subtext'))
        .onClick(() => this.ctx().terminateSelf())
    }
    .width('100%').height('100%').padding(24).justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.bg'))
  }
}
