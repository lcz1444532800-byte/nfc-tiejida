import { common } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { APP_NAME, CONTACT, VERSION_NAME } from '../common/AppInfo';

interface FeedbackParams { missingApp: string }

// Feedback goes through the user's own mail app (or a copied address). The app itself has
// no network access and sends nothing.
@Entry
@Component
struct Feedback {
  @State content: string = '';

  aboutToAppear(): void {
    const p = this.getUIContext().getRouter().getParams() as FeedbackParams;
    const missing = p?.missingApp?.trim() ?? '';
    if (missing) {
      this.content = `希望支持的应用：${missing}\n`;
    }
  }

  ctx(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message, duration: 2500 });
  }

  fullText(): string {
    return `${this.content.trim()}\n\n（${APP_NAME} ${VERSION_NAME}）`;
  }

  copy(text: string, done: string): void {
    try {
      pasteboard.getSystemPasteboard().setDataSync(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text));
      this.toast(done);
    } catch (e) {
      this.toast('复制失败，请手动记下邮箱');
    }
  }

  sendMail(): void {
    const subject = encodeURIComponent(`${APP_NAME} 反馈`);
    const body = encodeURIComponent(this.fullText());
    this.ctx().openLink(`mailto:${CONTACT}?subject=${subject}&body=${body}`, { appLinkingOnly: false })
      .catch(() => {
        this.copy(this.fullText(), '没有找到邮件应用。反馈内容已复制，请用 QQ 邮箱等发送到上面的邮箱');
      });
  }

  build() {
    Column() {
      Row() {
        Text('‹ 返回').fontSize(15).fontColor($r('app.color.accent'))
          .onClick(() => this.getUIContext().getRouter().back())
      }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 4 })

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 4 }) {
            Text('意见反馈').fontSize(22).fontWeight(FontWeight.Bold).fontColor($r('app.color.text'))
            Text('缺少想打开的应用、遇到问题或者有建议，都可以告诉我们。')
              .fontSize(14).fontColor($r('app.color.subtext'))
          }.width('100%').alignItems(HorizontalAlign.Start)

          TextArea({ text: this.content, placeholder: '想说的话，例如：希望支持「某某应用」；碰贴纸没反应……' })
            .id('feedbackContent').height(160).fontSize(15)
            .onChange((v: string) => { this.content = v; })

          Button('用邮件发送').width('100%').height(46)
            .enabled(this.content.trim().length > 0)
            .backgroundColor($r('app.color.accent')).fontColor($r('app.color.on_accent'))
            .onClick(() => this.sendMail())

          Column({ space: 8 }) {
            Text('也可以直接发邮件到').fontSize(13).fontColor($r('app.color.subtext'))
            Row({ space: 12 }) {
              Text(CONTACT).fontSize(16).fontColor($r('app.color.text')).copyOption(CopyOptions.LocalDevice)
                .layoutWeight(1)
              Text('复制').fontSize(14).fontColor($r('app.color.accent'))
                .onClick(() => this.copy(CONTACT, '邮箱已复制'))
            }.width('100%')
            Text('或者在华为应用市场本应用的评论区留言。')
              .fontSize(13).fontColor($r('app.color.subtext'))
          }
          .width('100%').padding(16).borderRadius(14).backgroundColor($r('app.color.surface'))
          .alignItems(HorizontalAlign.Start)

          Text('反馈由你自己的邮件应用发送，本应用不联网、不上传任何信息。')
            .fontSize(12).fontColor($r('app.color.subtext')).width('100%')
        }
        .padding(16)
      }
      .layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg'))
  }
}
