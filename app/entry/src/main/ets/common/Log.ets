import { hilog } from '@kit.PerformanceAnalysisKit';

// All test evidence is greppable on the PC with: hilog | grep NFCL
const DOMAIN = 0x0a11;
const TAG = 'NFCL';

export class Log {
  static i(msg: string): void { hilog.info(DOMAIN, TAG, '%{public}s', msg); }
  static w(msg: string): void { hilog.warn(DOMAIN, TAG, '%{public}s', msg); }
  static e(msg: string): void { hilog.error(DOMAIN, TAG, '%{public}s', msg); }
}
