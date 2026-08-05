# Google Sign-In — Cashark

Package: `com.cashark.cashark`

## Passos
1. Abre [Google Cloud Console](https://console.cloud.google.com/)
2. Cria/seleciona um projeto → OAuth consent screen
3. Credentials → Create credentials → OAuth client ID → **Android**
4. Package name: `com.cashark.cashark`
5. SHA-1 do teu keystore de release (e debug para testes locais):
   ```bash
   keytool -list -v -keystore android/app/upload-keystore.jks
   ```
6. (Opcional) passa `serverClientId` / `clientId` em `GoogleSignIn.instance.initialize(...)` se precisares de ID token no backend

## Comportamento na app
- Botão **Continuar com Google** no ecrã de login
- Se OAuth falhar / não estiver configurado → login demo `google.player@cashark.app`
- Conta fica com `googleLinked = true` e bónus inicial de Pérolas
