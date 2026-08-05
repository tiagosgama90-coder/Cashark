# Cashark

Colorful Android rewards app: animated shark/coin roulette, space shooter mini-game, shop, profile, multi-language login, and balanced rewarded ads.

**Package:** `com.cashark.cashark`  
**Target SDK:** 35 (min 24) · **64-bit only** (`arm64-v8a`, `x86_64`) · **16KB page-size ready**

## Samsung Galaxy Store — Review Comment (paste exactly)

```
Test login:
Email: teste_samsung@email.com
Password: SenhaTeste123
```

## Store metadata tips

- Title: **Cashark**
- Avoid third-party trademarks in title/description
- Provide 3–8 real screenshots + working Privacy Policy URL
- Register package name + signing certificate under ADV / Seller Portal

## Economy (house-friendly)

| Action | Result |
|--------|--------|
| Roulette Shark | +4–12 Sharks |
| Roulette Coin | +€0.02–€0.08 Cash |
| Convert | 100 Sharks → €0.35 (Turbo shop: €0.55) |
| Min cashout | €1.00 |
| Space kill | +1 Shark · 3 lives · buy lives via Cash / Sharks / ad / shop |

Daily free spins: 5 (+1 if VIP). Extra spins via rewarded ads or shop.

## Ads

- Rewarded ads only (no spam interstitials that trap navigation)
- Uses Google **test** AdMob IDs — replace with your production IDs before release
- Offline/review fallback still grants the reward so Samsung QA is never blocked

## Build

```bash
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

Outputs:

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

## Privacy Policy

Replace `https://cashark.app/privacy` in the Profile screen with your hosted policy before submission. A starter template is in `docs/PRIVACY_POLICY.md`.

## No self-updates

The app does not download or install APKs outside the store. All updates must ship via Samsung Galaxy Store.
