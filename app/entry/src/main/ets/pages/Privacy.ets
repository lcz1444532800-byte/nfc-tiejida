import { PolicySection, privacyPolicy } from '../common/AppInfo';

// Read-only privacy policy, opened from the home page. First-launch consent is shown by the
// system (AppGallery privacy hosting), so the app does not show its own consent screen.
@Entry
@Component
struct Privacy {
  build() {
    Column() {
      Row() {
        Text('‹ 返回').fontSize(15).fontColor($r('app.color.accent'))
          .onClick(() => this.getUIContext().getRouter().back())
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 4 })
      Column({ space: 4 }) {
        Text('隐私政策').fontSize(22).fontWeight(FontWeight.Bold).fontColor($r('app.color.text'))
      }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 16, right: 16, top: 16, bottom: 12 })

      Scroll() {
        Column({ space: 14 }) {
          ForEach(privacyPolicy(), (s: PolicySection) => {
            Column({ space: 4 }) {
              Text(s.title).fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text'))
              Text(s.body).fontSize(14).lineHeight(22).fontColor($r('app.color.subtext'))
            }.alignItems(HorizontalAlign.Start).width('100%')
          }, (s: PolicySection) => s.title)
        }
        .padding(16).borderRadius(14).backgroundColor($r('app.color.surface'))
      }
      .layoutWeight(1).margin({ left: 16, right: 16, bottom: 16 }).scrollBar(BarState.Auto)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg'))
  }
}
