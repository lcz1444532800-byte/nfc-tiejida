// Built-in list of launchable apps. ArkTS apps cannot enumerate installed apps (that needs an
// enterprise-only permission), so the picker shows this list and verifies a choice by actually
// opening the app once. Every entry's bundle and launcher ability were read from a real device
// with `bm dump -n <bundle>` (see scripts/Collect-Apps.ps1); do not add unverified entries.
// keywords: pinyin, initials and English names, used by the picker search.
export interface CatalogApp {
  name: string;
  bundle: string;
  ability: string;
  category: string;
  keywords: string;
}

export const CATEGORIES: string[] = ['社交通讯', '购物', '支付金融', '出行旅行', '影音娱乐', '阅读', '游戏', '生活服务', '办公学习', '工具'];

export const APP_CATALOG: CatalogApp[] = [
  { name: '微信', bundle: 'com.tencent.wechat', ability: 'EntryAbility', category: '社交通讯', keywords: 'weixin wx wechat' },
  { name: 'QQ', bundle: 'com.tencent.mqq', ability: 'EntryAbility', category: '社交通讯', keywords: 'qq tengxun' },
  { name: '微博', bundle: 'com.sina.weibo.stage', ability: 'EntryAbility', category: '社交通讯', keywords: 'weibo wb sina' },
  { name: '小红书', bundle: 'com.xingin.xhs_hos', ability: 'EntryAbility', category: '社交通讯', keywords: 'xiaohongshu xhs rednote' },
  { name: 'QQ邮箱', bundle: 'com.tencent.qqmail.hmos', ability: 'EntryAbility', category: '社交通讯', keywords: 'qqyouxiang qqyx mail' },
  { name: '中国移动', bundle: 'com.chinamobile.cmcc', ability: 'EntryAbility', category: '社交通讯', keywords: 'zhongguoyidong zgyd 10086 cmcc' },

  { name: '淘宝', bundle: 'com.taobao.taobao4hmos', ability: 'Taobao_mainAbility', category: '购物', keywords: 'taobao tb' },
  { name: '京东', bundle: 'com.jd.hm.mall', ability: 'EntryAbility', category: '购物', keywords: 'jingdong jd' },
  { name: '拼多多', bundle: 'com.xunmeng.pinduoduo.hos', ability: 'EntryAbility', category: '购物', keywords: 'pinduoduo pdd' },
  { name: '闲鱼', bundle: 'com.taobao.idlefish4ohos', ability: 'EntryAbility', category: '购物', keywords: 'xianyu xy' },
  { name: '转转', bundle: 'com.zhuanzhuan.hmoszz', ability: 'EntryAbility', category: '购物', keywords: 'zhuanzhuan zz' },

  { name: '支付宝', bundle: 'com.alipay.mobile.client', ability: 'EntryAbility', category: '支付金融', keywords: 'zhifubao zfb alipay' },
  { name: '中国银行', bundle: 'com.boc.bocsoft.mbs.personal', ability: 'AppAbility', category: '支付金融', keywords: 'zhongguoyinhang zgyh boc' },
  { name: '中国农业银行', bundle: 'com.bankabc.openharmonyapp.release', ability: 'MainAbility', category: '支付金融', keywords: 'nongye yinhang nh nyyh abc' },
  { name: '江苏银行', bundle: 'cn.jsbank.china', ability: 'EntryAbility', category: '支付金融', keywords: 'jiangsuyinhang jsyh' },

  { name: '高德地图', bundle: 'com.amap.hmapp', ability: 'EntryAbility', category: '出行旅行', keywords: 'gaode gd amap ditu' },
  { name: '滴滴出行', bundle: 'com.sdu.didi.hmos.psnger', ability: 'EntryAbility', category: '出行旅行', keywords: 'didi dd dache' },
  { name: '铁路12306', bundle: 'com.chinarailway.ticketingHM', ability: 'EntryAbility', category: '出行旅行', keywords: 'tielu 12306 huoche' },
  { name: '携程旅行', bundle: 'com.ctrip.harmonynext', ability: 'CTEntryAbility', category: '出行旅行', keywords: 'xiecheng xc ctrip' },
  { name: '去哪儿旅行', bundle: 'com.qunar.hos', ability: 'EntryAbility', category: '出行旅行', keywords: 'qunaer qne qunar' },
  { name: '华住会', bundle: 'com.htinns.application', ability: 'EntryAbility', category: '出行旅行', keywords: 'huazhuhui hzh jiudian' },
  { name: '交管12123', bundle: 'com.tmri.app.harmony12123', ability: 'EntryAbility', category: '出行旅行', keywords: 'jiaoguan 12123 jg' },
  { name: '上海交通卡', bundle: 'com.sptcc.app', ability: 'EntryAbility', category: '出行旅行', keywords: 'shanghai jiaotongka shjtk sptcc' },
  { name: '出境易', bundle: 'com.easy.hmos.abroad', ability: 'EntryAbility', category: '出行旅行', keywords: 'chujingyi cjy' },

  { name: '抖音', bundle: 'com.ss.hm.ugc.aweme', ability: 'MainAbility', category: '影音娱乐', keywords: 'douyin dy tiktok' },
  { name: '快手', bundle: 'com.kuaishou.hmapp', ability: 'EntryAbility', category: '影音娱乐', keywords: 'kuaishou ks' },
  { name: '哔哩哔哩', bundle: 'yylx.danmaku.bili', ability: 'EntryAbility', category: '影音娱乐', keywords: 'bilibili blbl b zhan' },
  { name: 'QQ音乐', bundle: 'com.tencent.hm.qqmusic', ability: 'EntryAbility', category: '影音娱乐', keywords: 'qqyinyue qqyy music' },
  { name: '汽水音乐', bundle: 'com.luna.hm.music', ability: 'MainAbility', category: '影音娱乐', keywords: 'qishui yinyue qsyy music' },
  { name: '今日头条', bundle: 'com.ss.hm.article.news', ability: 'MainAbility', category: '影音娱乐', keywords: 'jinritoutiao jrtt toutiao' },

  { name: '番茄免费小说', bundle: 'com.dragon.read.next', ability: 'MainAbility', category: '阅读', keywords: 'fanqie xiaoshuo fqxs fanqiemianfeixiaoshuo' },

  { name: '王者荣耀', bundle: 'com.tencent.tmgp.sgame.hw', ability: 'SGameAbility', category: '游戏', keywords: 'wangzherongyao wzry wangzhe' },

  { name: '美团', bundle: 'com.sankuai.hmeituan', ability: 'EntryAbility', category: '生活服务', keywords: 'meituan mt waimai' },
  { name: '大众点评', bundle: 'com.sankuai.dianping', ability: 'EntryAbility', category: '生活服务', keywords: 'dazhongdianping dzdp dianping' },

  { name: 'WPS Office', bundle: 'cn.wps.mobileoffice.hap', ability: 'EntryAbility', category: '办公学习', keywords: 'wps office bangong' },
  { name: '腾讯会议', bundle: 'com.tencent.meeting.app', ability: 'NXHostUIAbility', category: '办公学习', keywords: 'tengxunhuiyi txhy meeting' },
  { name: '学信网', bundle: 'cn.com.chsi.app', ability: 'EntryAbility', category: '办公学习', keywords: 'xuexinwang xxw chsi' },
  { name: 'ClassIn', bundle: 'cn.eeo.hos.classin.mobile', ability: 'EntryAbility', category: '办公学习', keywords: 'classin' },
  { name: 'U校园', bundle: 'cn.unipus.cloud.hm', ability: 'EntryAbility', category: '办公学习', keywords: 'uxiaoyuan uxy unipus' },
  { name: '知到', bundle: 'com.able.wisdomtreehm', ability: 'EntryAbility', category: '办公学习', keywords: 'zhidao zd zhihuishu' },

  { name: '百度', bundle: 'com.baidu.baiduapp', ability: 'EntryAbility', category: '工具', keywords: 'baidu bd sousuo' },
  { name: '夸克', bundle: 'com.quark.ohosbrowser', ability: 'EntryAbility', category: '工具', keywords: 'kuake kk quark' },
  { name: '豆包', bundle: 'com.larus.nova.hm', ability: 'MainAbility', category: '工具', keywords: 'doubao db ai' },
  { name: '卓易通', bundle: 'com.droi.tong', ability: 'EntryAbility', category: '工具', keywords: 'zhuoyitong zyt' }
];

export function searchCatalog(query: string): CatalogApp[] {
  const q = query.trim().toLowerCase().replace(/\s+/g, '');
  if (!q) { return APP_CATALOG; }
  return APP_CATALOG.filter((a: CatalogApp) =>
    a.name.toLowerCase().includes(q) || a.keywords.replace(/\s+/g, ' ').split(' ').some((k: string) => k.startsWith(q)) ||
      a.keywords.replace(/\s+/g, '').includes(q));
}
