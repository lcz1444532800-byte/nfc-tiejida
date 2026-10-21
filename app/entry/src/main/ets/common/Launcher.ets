import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LaunchTarget } from './Store';

export interface LaunchResult {
  ok: boolean;
  message: string; // user-facing
  code: number;
}

// Start/openLink errors meaning "this app (or link handler) is not on the phone".
const NOT_FOUND_CODES: number[] = [16000001, 16000019];

// Starts the bound app only through public Ability Kit entry points:
// a custom link via openLink, otherwise an explicit Want for the app's launcher ability.
export async function launchTarget(ctx: common.UIAbilityContext, target: LaunchTarget): Promise<LaunchResult> {
  try {
    if (target.link) {
      await ctx.openLink(target.link, { appLinkingOnly: false });
    } else {
      const want: Want = { bundleName: target.bundleName, abilityName: target.abilityName };
      await ctx.startAbility(want);
    }
    return { ok: true, message: `已打开${target.label}`, code: 0 };
  } catch (e) {
    const err = e as BusinessError;
    const notFound = NOT_FOUND_CODES.includes(err.code);
    const message = notFound
      ? (target.link ? '这台手机上没有能打开这个链接的应用' : `这台手机上没有找到「${target.label}」`)
      : `打开失败（错误码 ${err.code}）`;
    return { ok: false, message: message, code: err.code };
  }
}
