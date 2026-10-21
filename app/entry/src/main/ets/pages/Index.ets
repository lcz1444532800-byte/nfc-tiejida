import { common } from '@kit.AbilityKit';
import { nfcController } from '@kit.ConnectivityKit';
import { BindingRow, Store } from '../common/Store';
import { ReaderMode } from '../common/ReaderMode';
import { APP_NAME, VERSION_NAME } from '../common/AppInfo';

@CustomDialog
struct RenameDialog {
  controller: CustomDialogController;
  @Prop current: string = '';
  @State value: string = '';
  onSave: (name: string) => void = () => {};

  aboutToAppear(): void { this.value = this.current; }

  build() {
    Column({ space: 14 }) {
      Text('重命名').fontSize(18).fontWeight(FontWeight.Medium).fontColor($r('app.color.text'))
      TextInput({ text: this.value, placeholder: '例如：门口、床头、车里' }).id('renameInput').maxLength(20)
        .onChange((v: string) => { this.value = v; })
      Row({ space: 12 }) {
        Button('取消').layoutWeight(1).backgroundColor($r('app.color.surface')).fontColor($r('app.color.subtext'))
          .onClick(() => this.controller.close())
        Button('保存').layoutWeight(1).enabled(this.value.trim().length > 0)
          .backgroundColor($r('app.color.accent')).fontColor($r('app.color.on_accent'))
          .onClick(() => { this.onSave(this.value); this.controller.close(); })
      }
    }.padding(20).backgroundColor($r('app.color.surface'))
  }
}

@Entry
@Component
struct Index {
  @StorageProp('tick') @Watch('reload') tick: number = 0;
  @StorageLink('readerKind') readerKind: string = '';
  @StorageProp('readerStatus') readerStatus: string = '';
  @StorageLink('newCardKey') @Watch('onNewCard') newCardKey: string = '';
  @StorageLink('homeNotice') notice: string = '';
  @State nfcOn: boolean = true;
  @State rows: BindingRow[] = [];
  @State renameKey: string = '';
  @State showHelp: boolean = false;
  private renameDialog: CustomDialogController | null = null;

  ctx(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  aboutToAppear(): void { this.reload(); }

  onPageShow(): void { this.reload(); }

  reload(): void {
    try { this.nfcOn = nfcController.isNfcOpen(); } catch (e) { this.nfcOn = true; }
    this.rows = new Store(this.ctx()).listBindings();
  }

  onNewCard(): void {
    if (!this.newCardKey) { return; }
    const key = this.newCardKey;
    this.newCardKey = '';
    this.getUIContext().getRouter().pushUrl({ url: 'pages/Picker', params: { key: key } });
  }

  startReader(kind: 'read' | 'write'): void {
    this.notice = '';
    const err = ReaderMode.start(this.ctx(), kind);
    if (err) { this.getUIContext().getPromptAction().showToast({ message: err }); }
  }

  openRename(row: BindingRow): void {
    this.renameKey = row.key;
    this.renameDialog = new CustomDialogController({
      builder: RenameDialog({
        current: row.name,
        onSave: (name: string) => { new Store(this.ctx()).setName(this.renameKey, name); this.reload(); }
      }),
      autoCancel: true
    });
    this.renameDialog.open();
  }

  confirmDelete(row: BindingRow): void {
    this.getUIContext().showAlertDialog({
      title: `删除「${row.name}」？`,
      message: '删除后碰这张贴纸不再打开任何应用。贴纸本身可以重新绑定。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除', fontColor: $r('app.color.danger'),
        action: () => { new Store(this.ctx()).removeBinding(row.key); this.reload(); }
      }
    });
  }

  @Builder readerPanel() {
    Column({ space: 12 }) {
      Text(this.readerKind === 'write' ? '写入新贴纸' : '绑定实体卡')
        .fontSize(17).fontWeight(FontWeight.Medium).fontColor($r('app.color.text'))
      Text(this.readerStatus).fontSize(14).fontColor($r('app.color.subtext'))
      LoadingProgress().width(36).height(36).color($r('app.color.accent'))
      Button('取消').width('100%').backgroundColor($r('app.color.bg')).fontColor($r('app.color.subtext'))
        .onClick(() => ReaderMode.finish(this.ctx(), ''))
    }
    .width('100%').padding(20).borderRadius(16).backgroundColor($r('app.color.surface'))
  }

  @Builder bindingRow(row: BindingRow) {
    Column({ space: 8 }) {
      Row({ space: 12 }) {
        Column({ space: 2 }) {
          Text(row.name).fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('app.color.text'))
          Text(`碰一下打开：${row.target.label}`).fontSize(13).fontColor($r('app.color.subtext'))
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Text(Store.isSticker(row.key) ? '贴纸' : '实体卡').fontSize(11).fontColor($r('app.color.accent'))
          .padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(8).backgroundColor($r('app.color.accent_soft'))
      }.width('100%')
      Row({ space: 20 }) {
        Text('改绑').fontSize(14).fontColor($r('app.color.accent'))
          .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/Picker', params: { key: row.key } }))
        Text('重命名').fontSize(14).fontColor($r('app.color.accent')).onClick(() => this.openRename(row))
        Text('删除').fontSize(14).fontColor($r('app.color.danger')).onClick(() => this.confirmDelete(row))
      }.width('100%')
    }
    .padding(16).borderRadius(14).backgroundColor($r('app.color.surface'))
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 4 }) {
          Text(APP_NAME).fontSize(26).fontWeight(FontWeight.Bold).fontColor($r('app.color.text'))
          Text('碰一下贴纸，直接打开你绑定的应用').fontSize(14).fontColor($r('app.color.subtext'))
        }.width('100%').alignItems(HorizontalAlign.Start).padding({ top: 12 })

        if (!this.nfcOn) {
          Text('NFC 未开启。请从屏幕右上角下滑打开控制中心，开启 NFC。')
            .fontSize(14).fontColor($r('app.color.warn')).width('100%')
            .padding(12).borderRadius(12).backgroundColor($r('app.color.warn_soft'))
        }
        if (this.notice) {
          Text(this.notice).fontSize(14).fontColor($r('app.color.accent')).width('100%')
            .padding(12).borderRadius(12).backgroundColor($r('app.color.accent_soft'))
            .onClick(() => { this.notice = ''; })
        }

        if (this.readerKind) {
          this.readerPanel()
        } else {
          Button('添加新贴纸').width('100%').height(48).fontSize(16)
            .backgroundColor($r('app.color.accent')).fontColor($r('app.color.on_accent'))
            .onClick(() => this.startReader('write'))
          if (this.readerStatus) {
            Text(this.readerStatus).fontSize(13).fontColor($r('app.color.danger')).width('100%')
          }
        }

        Text('我的贴纸').fontSize(14).fontColor($r('app.color.subtext')).width('100%')
        if (this.rows.length === 0) {
          Column({ space: 6 }) {
            Text('还没有贴纸').fontSize(16).fontColor($r('app.color.text'))
            Text('准备一张 NTAG213 / 215 空白 NFC 贴纸，点「添加新贴纸」，按提示放到手机背面，再选一个要打开的应用。')
              .fontSize(13).lineHeight(20).fontColor($r('app.color.subtext'))
          }.width('100%').padding(16).borderRadius(14).backgroundColor($r('app.color.surface'))
          .alignItems(HorizontalAlign.Start)
        }
        ForEach(this.rows, (row: BindingRow) => { this.bindingRow(row) }, (row: BindingRow) => `${row.key}|${row.name}|${row.target.label}`)

        if (!this.readerKind) {
          Text('绑定交通卡、门禁卡等实体卡').fontSize(14).fontColor($r('app.color.accent')).width('100%')
            .onClick(() => this.startReader('read'))
        }

        Column({ space: 10 }) {
          Text(this.showHelp ? '收起使用说明' : '使用说明').fontSize(14).fontColor($r('app.color.accent'))
            .onClick(() => { this.showHelp = !this.showHelp; })
          if (this.showHelp) {
            Text('· 手机亮屏并解锁后，用贴纸碰手机背面摄像头附近，就会打开绑定的应用，不需要先打开本应用。\n' +
              '· 每个应用第一次被打开时，系统会询问是否允许，选择允许后以后不再询问。\n' +
              '· 换绑应用不需要重新写贴纸。\n' +
              '· 贴在金属表面需使用抗金属贴纸。\n' +
              '· 实体卡（交通卡、门禁卡）无法写入，碰卡时系统会先弹出通知和应用选择框，需要点两下才能打开。')
              .fontSize(13).lineHeight(21).fontColor($r('app.color.subtext'))
          }
          Text('意见反馈').fontSize(14).fontColor($r('app.color.accent'))
            .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/Feedback' }))
          Text('隐私政策').fontSize(14).fontColor($r('app.color.accent'))
            .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/Privacy', params: { mode: 'view' } }))
          Text(`${APP_NAME} ${VERSION_NAME} · 不联网，数据只保存在本机`).fontSize(12).fontColor($r('app.color.subtext'))
        }.width('100%').alignItems(HorizontalAlign.Start).padding({ top: 8, bottom: 32 })
      }
      .padding({ left: 16, right: 16 })
    }
    .width('100%').height('100%').align(Alignment.Top).backgroundColor($r('app.color.bg')).scrollBar(BarState.Off)
  }
}
