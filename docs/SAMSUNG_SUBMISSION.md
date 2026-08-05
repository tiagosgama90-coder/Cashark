# Samsung Galaxy Store — Submission checklist

## Review Comment (obrigatório — colar exatamente)

```
Test login:
Email: teste_samsung@email.com
Password: SenhaTeste123
```

Conta de teste já vem pré-criada na app com Cash, Sharks e giros.

## Technical compliance

| Requirement | Status |
|-------------|--------|
| Target API ≥ 33 | ✅ Target SDK **35** |
| 64-bit binaries | ✅ `arm64-v8a` + `x86_64` only (no armeabi-v7a) |
| 16KB page size (Android 15+) | ✅ NDK 27, uncompressed native libs, `extractNativeLibs=false` |
| No self-updating APK downloads | ✅ Updates only via store |
| Balanced ads | ✅ Rewarded only + offline fallback for QA |
| ADV package ownership | ⚠️ Regista `com.cashark.cashark` + certificado no Seller Portal |

## Artifacts

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## Before production upload

1. Replace AdMob **test** IDs with your real App ID + rewarded unit ID
2. Host Privacy Policy and update the URL in Profile (`https://cashark.app/privacy`)
3. Sign with your upload keystore (current release uses debug signing for convenience)
4. Capture 3–8 real screenshots from a device/emulator
5. Wire Galaxy Store IAP SKUs to shop item IDs if you want real billing (shop currently simulates purchases for review)

## Package name

`com.cashark.cashark`
