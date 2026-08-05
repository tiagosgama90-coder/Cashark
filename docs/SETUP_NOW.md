# O que precisas para criar / publicar a app Cashark agora

## 1. Já tens no código
- App Flutter Android (API 35, 64-bit)
- Login email + **Google Sign-In** (precisa OAuth no Google Cloud)
- 5 tabs: Loja · Spin · Jogos · Rifa · Carteira (ícones com mascote tubarão)
- Economia: Pontos → Sharkcoins → Cash (+ **Pérolas/Pearls** premium)
- Premium sem anúncios + packs de Pérolas (Stripe)
- Roleta, Ocean Stardust 3D, rifas, cashout PayPal
- 7 idiomas (Pérolas / Pearls / Perlas / … conforme a língua)

## 2. Contas e chaves (obrigatório para produção)
1. **Google Cloud / Firebase** — OAuth Client ID Android (package `com.cashark.cashark` + SHA-1)
2. **Stripe** — `STRIPE_SECRET_KEY` + webhook `STRIPE_WEBHOOK_SECRET` no `backend/.env`
3. **PayPal** — credenciais Payouts no backend (pagar utilizadores)
4. **AdMob** — troca os IDs de teste em `AdsService` pelos teus
5. **Domínio** — `cashark.app` (ou outro) para privacy + deep links Stripe
6. **Samsung Seller Office** e/ou **Google Play Console**

## 3. Google Sign-In (Android)
1. Google Cloud Console → APIs → OAuth consent + Credentials
2. Cria OAuth client **Android** com package `com.cashark.cashark` e SHA-1 do keystore
3. Sem client ID configurado, o botão Google usa login **demo** (para testes/review)

## 4. Build
```bash
flutter pub get
flutter build appbundle --release   # Play / Galaxy
# ou
flutter build apk --release
```

## 5. Economia inteligente (resumo)
| Moeda | Como ganha | Para que serve |
|-------|------------|----------------|
| Points | Jogo + spins | → Sharkcoins |
| Sharkcoins | Spins / conversão | → Cash |
| Cash | Conversão | Saque ≥ €10 |
| **Pérolas** | Compra Stripe / bónus | Giros extra, rifa, troca → SC |

## 6. Publicação recomendada
1. Galaxy Store primeiro (mais simples para rewards apps)
2. Play Store closed testing com **testers reais** (não farms de Gmail)
3. Política de privacidade online + screenshots das 5 tabs
