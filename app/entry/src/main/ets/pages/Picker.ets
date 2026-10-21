import { common } from '@kit.AbilityKit';
import { APP_CATALOG, CatalogApp, CATEGORIES, searchCatalog } from '../common/AppCatalog';
import { LaunchTarget, Store } from '../common/Store';
import { launchTarget, LaunchResult } from '../common/Launcher';
import { NfcLaunchFlow } from '../common/NfcLaunchFlow';

interface PickerParams { key: string }

interface Section { title: string; apps: CatalogApp[] }

// Choose the app (or link) a sticker/card opens. A choice is saved only after the app was
// actually opened once, because the catalog cannot know which apps are installed.
@Entry
@Component
struct Picker {
  @State query: string = '';
  @State cardKey: string = '';
  @State cardName: string = '';
  @State showLink: boolean = false;
  @State linkText: string = '';
  @State linkLabel: string = '';
  @State busy: boolean = false;

  aboutToAppear(): void {
    const p = this.getUIContext().getRouter().getParams() as PickerParams;
    this.cardKey = p?.key ?? '';
    this.cardName = new Store(this.ctx()).getName(this.cardKey);
  }

  ctx(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  sections(): Section[] {
    if (this.query.trim()) {
      return [{ title: '搜索结果', apps: searchCatalog(this.query) }];
    }
    return CATEGORIES.map((c: string): Section => ({ title: c, apps: APP_CATALOG.filter((a: CatalogApp) => a.category === c) }))
      .filter((s: Section) => s.apps.length > 0);
  }

  toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message, duration: 2500 });
  }

  confirm(target: LaunchTarget): void {
    this.getUIContext().showAlertDialog({
      title: `打开「${target.label}」`,
      message: `会先打开一次${target.label}，确认这台手机上能打开后就完成绑定。以后碰「${this.cardName}」就会直接打开它。`,
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '打开并绑定', action: () => this.bindAndOpen(target) }
    });
  }

  bindAndOpen(target: LaunchTarget): void {
    if (this.busy) { return; }
    this.busy = true;
    launchTarget(this.ctx(), target).then((r: LaunchResult) => {
      this.busy = false;
      if (!r.ok) {
        this.toast(r.message);
        return;
      }
      new Store(this.ctx()).setBinding(this.cardKey, target);
      AppStorage.setOrCreate('homeNotice', `「${this.cardName}」已绑定${target.label}`);
      AppStorage.setOrCreate('tick', Date.now());
      // Opened from an NFC launch window: let that ability close once the app is in front.
      const flow = this.getUIContext().getSharedLocalStorage()?.get<NfcLaunchFlow>('flow');
      if (flow) { flow.markLaunchedAway(); }
      this.getUIContext().getRouter().back();
    });
  }

  @Builder appRow(a: CatalogApp) {
    Row({ space: 12 }) {
      Text(a.name.substring(0, 1))
        .width(40).height(40).borderRadius(12).textAlign(TextAlign.Center)
        .fontSize(18).fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.accent')).backgroundColor($r('app.color.accent_soft'))
      Text(a.name).fontSize(16).fontColor($r('app.color.text')).layoutWeight(1)
    }
    .width('100%').padding({ top: 8, bottom: 8 })
    .onClick(() => this.confirm({ label: a.name, bundleName: a.bundle, abilityName: a.ability, link: '' }))
  }

  @Builder linkPanel() {
    Column({ space: 10 }) {
      TextInput({ placeholder: '链接，例如 weixin://', text: this.linkText })
        .id('linkInput').type(InputType.URL)
        .onChange((v: string) => { this.linkText = v; })
      TextInput({ placeholder: '显示名称（可选）', text: this.linkLabel })
        .id('linkLabelInput')
        .onChange((v: string) => { this.linkLabel = v; })
      Text('链接由对应应用提供。打不开时，说明这台手机上没有能处理它的应用。')
        .fontSize(12).fontColor($r('app.color.subtext'))
      Button('打开并绑定').width('100%').enabled(this.linkText.trim().length > 0 && !this.busy)
        .backgroundColor($r('app.color.accent')).fontColor($r('app.color.on_accent'))
        .onClick(() => {
          const link = this.linkText.trim();
          this.confirm({ label: this.linkLabel.trim() || link, bundleName: '', abilityName: '', link: link });
        })
    }
    .padding(16).borderRadius(14).backgroundColor($r('app.color.surface'))
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Text('‹ 返回').fontSize(15).fontColor($r('app.color.accent'))
          .onClick(() => this.getUIContext().getRouter().back())
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 4 })

      Column({ space: 4 }) {
        Text('选择要打开的应用').fontSize(22).fontWeight(FontWeight.Bold).fontColor($r('app.color.text'))
        Text(`绑定到「${this.cardName}」`).fontSize(14).fontColor($r('app.color.subtext'))
      }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 16, right: 16, bottom: 12 })

      Search({ placeholder: '搜索应用，支持拼音首字母', value: this.query })
        .id('appSearch').margin({ left: 16, right: 16 })
        .onChange((v: string) => { this.query = v; })

      Scroll() {
        Column({ space: 16 }) {
          Row() {
            Text(this.showLink ? '收起「用链接打开」' : '列表里没有？用链接打开（高级）')
              .fontSize(14).fontColor($r('app.color.accent'))
          }.width('100%').onClick(() => { this.showLink = !this.showLink; })
          if (this.showLink) { this.linkPanel() }

          ForEach(this.sections(), (s: Section) => {
            Column() {
              Text(s.title).fontSize(13).fontColor($r('app.color.subtext')).margin({ bottom: 4 })
              ForEach(s.apps, (a: CatalogApp) => { this.appRow(a) }, (a: CatalogApp) => a.bundle)
            }
            .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(14).backgroundColor($r('app.color.surface')).alignItems(HorizontalAlign.Start)
          }, (s: Section) => s.title + this.query)

          if (this.query.trim() && searchCatalog(this.query).length === 0) {
            Column({ space: 8 }) {
              Text(`清单里还没有「${this.query.trim()}」。`).fontSize(14).fontColor($r('app.color.text'))
              Text('告诉我们缺这个应用').fontSize(14).fontColor($r('app.color.accent'))
                .onClick(() => this.getUIContext().getRouter()
                  .pushUrl({ url: 'pages/Feedback', params: { missingApp: this.query.trim() } }))
              Text('也可以试试上面的「用链接打开」。').fontSize(13).fontColor($r('app.color.subtext'))
            }.width('100%').alignItems(HorizontalAlign.Start)
          }
          Text(`列表里的应用不一定都装在你的手机上，选中后会先打开一次来确认。`)
            .fontSize(12).fontColor($r('app.color.subtext')).margin({ bottom: 24 })
        }
        .padding({ left: 16, right: 16, top: 16 })
      }
      .layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg'))
  }
}
