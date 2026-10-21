// Product identity used in the UI and the privacy policy. The privacy policy must name the
// same developer and app as the AppGallery Connect listing; fill these in before submitting.
export const APP_NAME = 'NFC贴即达';
export const DEVELOPER_NAME = '刘春泽';
export const CONTACT = '1444532800@qq.com';
export const POLICY_DATE = '2026年10月18日';
export const VERSION_NAME = '1.0.1';

export interface PolicySection {
  title: string;
  body: string;
}

export function privacyPolicy(): PolicySection[] {
  return [
    {
      title: '概述',
      body: `${APP_NAME}（以下称“本应用”）由${DEVELOPER_NAME}开发。本应用用于把 NFC 贴纸或卡片与你选择的应用绑定，碰一下贴纸即可打开对应应用。本政策说明本应用如何处理你的信息。`
    },
    {
      title: '我们处理哪些信息',
      body: '1. NFC 标签标识：读取贴纸或卡片的标识号（UID）和本应用写入贴纸的编号，用于识别是哪一张贴纸。不读取交通卡、银行卡的余额、交易记录或其他内容。\n2. 绑定关系：你为每张贴纸选择的应用名称、应用包名或链接，以及你给贴纸起的名字。\n以上信息只保存在你的手机本地。'
    },
    {
      title: '我们不做什么',
      body: '本应用没有联网功能，不上传、不共享、不出售任何信息；不获取你手机上已安装应用的列表；不收集设备标识、位置、通讯录等个人信息；不包含广告或第三方统计 SDK。'
    },
    {
      title: '权限说明',
      body: 'NFC 标签权限（ohos.permission.NFC_TAG）：用于读取贴纸或卡片标识，以及向空白贴纸写入启动信息。只会写入你主动放到手机上的空白贴纸；交通卡、银行卡、门禁卡等卡片会被拒绝写入。'
    },
    {
      title: '打开其他应用',
      body: '碰贴纸时，本应用会通过系统公开的接口打开你绑定的应用。首次打开某个应用时，系统可能会询问是否允许，这一选择由系统记录。'
    },
    {
      title: '你的权利',
      body: '你可以随时在本应用中修改或删除任何绑定。卸载本应用会删除全部本地数据。'
    },
    {
      title: '联系我们',
      body: `如有问题，请联系：${CONTACT}。应用内的「意见反馈」会打开你自己的邮件应用发送，内容只包含你填写的文字和本应用版本号，本应用不会自动发送任何信息。\n本政策更新日期：${POLICY_DATE}。`
    }
  ];
}
