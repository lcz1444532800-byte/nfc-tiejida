# How it works — findings on HarmonyOS 7 NFC dispatch

All results below were measured on a HUAWEI Pura 90 Pro (HarmonyOS 7.0.0, API 26) using filtered `hilog` output, and cross-checked against the OpenHarmony NFC service source (`services/src/tag/tag_dispatcher.cpp`). Huawei's closed-source parts may differ on other devices or versions.

## 1. NDEF stickers: direct launch, zero taps

`TagDispatcher::HandleTagFound` first tries `HandleNdefDispatch → NdefHarDataParser::TryNdef`. If that succeeds it stops there — no notification, no `TAG_FOUND` broadcast, no chooser. `TryNdef` handles, in order:

1. **Application record** (TNF External, type `ohos.com:pkg` or `android.com:pkg`, payload = bundle name) → `GetLaunchWantForBundle` → the NFC service starts the app's entry ability itself, with the TagInfo in the Want. It also wakes the screen and asks for unlock first.
2. URI record → launched as a link.
3. MIME record → implicit match.

The public SDK can write exactly this: `tag.ndef.makeApplicationRecord(bundleName)` plus `NdefTag.writeNdef()` (or `NdefFormatable.format()` for unformatted tags).

Measured timeline for a bound sticker with the app process killed beforehand:

| t (ms) | Event |
|---|---|
| 0 | NFC service reads the tag (`HandleNdefDispatch`) |
| +25 | `DispatchByHarBundleName succ` |
| +160 | App `EntryAbility` cold start, `uri=nfclauncher://tag/<id>` |
| +280 | `startAbility(<target bundle>/<ability>)` |
| +320 | Target app in the foreground |

Notes:

- Writing fails with `3100204 Tag lost` if the sticker moves; holding still and retrying works.
- Transit, bank and access cards (IsoDep / MIFARE Classic) are refused by the writer, because formatting them as NDEF would destroy their data.

## 2. Non-NDEF cards: notification + chooser every time

For a tag without NDEF content (`ndef msg is empty`) the service only posts an "NFC service" notification (`PublishTagNotification`). The `TAG_FOUND` implicit start happens only after the user taps it (`OnNotificationButtonClicked`). If more than one app declares a matching `tag-tech/*` skill, a chooser follows. On the test phone WeChat and a transit-card app also declare these techs.

- The chooser has no "always use" option.
- There is no public API to set a default NFC handler (`defaultAppManager` has no NFC type and is a system API).

So binding a physical card works, but each tap costs two extra user actions. The app registers `NfcDispatchAbility` for `TAG_FOUND` only to support this.

Card identity: the UID was stable across 8 reads of the test card (4-byte UID). SAK was not stable between reader mode and system dispatch (`28` vs `08`), so only the UID is used. Cards with random UIDs cannot be told apart.

## 3. Launching another app

Both an explicit Want (`startAbility({ bundleName, abilityName })`) and `openLink` work from an ability that was started by the NFC service.

The first time the app jumps to a given target, the ecosystem rule manager (ERMS) shows an allow/cancel dialog **inside the caller's window**. After "allow" the pair is remembered.

Pitfall: calling `terminateSelf()` right after `startAbility` resolves closes that dialog with the window, and the target never opens. The app waits for `onBackground` (target in front) before finishing.

## 4. Installed apps cannot be listed

`bundleManager.getAllBundleInfo` returns 201 for a normal app. `ohos.permission.GET_INSTALLED_BUNDLE_LIST` is `system_basic` / system-only in the SDK permission definitions. The only public listing API (`getInstalledBundleList`) needs an enterprise permission and is limited to 2-in-1 devices.

Hence the built-in catalog. Each binding is "test-launched" once when it is saved, so the user immediately sees whether the app is installed.

## 5. Small gotchas

- When the app is opened normally from the home screen, `tag.getTagInfo(want)` still returns an (empty) TagInfo. Treat a TagInfo without UID/technologies as "not an NFC start".
- Hvigor rejects non-ASCII project paths; build from an ASCII-path copy.
- Command-line release signing needs the store/key passwords encrypted with the signing "material" next to the key store (AES-128-GCM). `scripts/encrypt-signing-pwd.js` reimplements Hvigor's format.
- AppGallery: if you use the platform's hosted privacy policy, do not also show your own consent dialog — review rejects "two privacy dialogs".
