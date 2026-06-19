# 🚀 Publicar na Google Play Store

Guia passo a passo para subir o **Frases & Status**.

> ⚠️ Neste computador o `git.exe` está bloqueado pelo sistema (AppLocker/antivírus),
> então `flutter build appbundle` falha pelo wrapper. **Destrave o git** (ou rode
> em outra máquina) antes de gerar o `.aab`. Tudo o mais já está configurado.

---

## 1. Trocar os IDs de teste do AdMob pelos reais

Sem isso você não ganha dinheiro (e clicar nos anúncios de teste é inofensivo,
mas clicar nos reais te bane).

1. Crie o app e os blocos de anúncio em https://admob.google.com
2. `lib/services/ads_service_mobile.dart`:
   - `_useTestAds = false`
   - preencha `_realBannerAndroid` e `_realInterstitialAndroid`
3. `android/app/src/main/AndroidManifest.xml`:
   - troque o valor de `com.google.android.gms.ads.APPLICATION_ID` pelo seu
     App ID real (formato `ca-app-pub-XXXX~YYYY`).

## 1.1. Ativar a auto-atualização de conteúdo (opcional, recomendado)

1. Hospede o arquivo `content/phrases.json` em uma URL pública (GitHub Raw,
   Firebase Hosting, seu site, etc.).
2. Em `lib/services/content_repository.dart`, ajuste `remoteUrl` para essa URL.
3. Para publicar frases novas depois: edite o JSON hospedado e **aumente o
   campo `version`**. Os apps já instalados recebem na próxima abertura, sem
   nova versão na loja. (Se a URL estiver vazia/offline, o app usa a base
   embutida normalmente.)

## 2. Definir nome do pacote (applicationId) definitivo

Hoje é `com.frasesstatus.frases_status` (em `android/app/build.gradle.kts`).
Ele **não pode mudar depois de publicado**, então escolha bem agora.

## 3. Gerar a chave de assinatura (uma única vez)

```bash
keytool -genkey -v -keystore upload-keystore.jks ^
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Guarde o `.jks` e as senhas em local seguro (perder = não conseguir mais
  atualizar o app).
- Mova `upload-keystore.jks` para `android/app/`.
- Copie `android/key.properties.example` para `android/key.properties` e preencha
  as senhas/alias. (Esses arquivos já estão no `.gitignore`.)

## 4. Ícone e versão

- Ícone: substitua os arquivos em `android/app/src/main/res/mipmap-*`
  (sugestão: use o pacote `flutter_launcher_icons`).
- Versão: edite `version: 1.0.0+1` no `pubspec.yaml`
  (`+1` é o versionCode; aumente a cada envio).

## 5. Gerar o App Bundle (.aab)

```bash
flutter pub get
flutter build appbundle --release
```

Saída: `build/app/outputs/bundle/release/app-release.aab`

> Se o build de release falhar por causa do R8/minify, abra
> `android/app/build.gradle.kts` e troque `isMinifyEnabled`/`isShrinkResources`
> para `false`, depois rebuild. As regras em `proguard-rules.pro` já cobrem
> AdMob, notificações e Flutter.

## 6. Play Console

1. Crie a conta de desenvolvedor (taxa única de US$25) em
   https://play.google.com/console
2. Criar app → idioma padrão Português (Brasil).
3. Suba o `.aab` em **Testes internos** primeiro (valida assinatura/anúncios).
4. Preencha a ficha da loja: nome, descrição curta/longa, ícone 512×512,
   screenshots (mín. 2), banner 1024×500.
   → **Textos prontos para colar em `STORE_LISTING.md`.**
5. **Segurança dos dados**: declare que usa AdMob (coleta de ID de publicidade).
6. **Política de privacidade**: obrigatória por causa dos anúncios — veja o
   modelo em `PRIVACY_POLICY.md` (hospede em qualquer URL pública).
7. Classificação de conteúdo, público-alvo, anúncios = "Sim".
8. Envie para revisão.

## Checklist rápido

- [ ] IDs reais do AdMob (Dart + Manifest)
- [ ] applicationId definitivo
- [ ] keystore gerado + key.properties preenchido
- [ ] ícone próprio
- [ ] versionCode incrementado
- [ ] `flutter build appbundle --release` OK
- [ ] política de privacidade hospedada
- [ ] ficha da loja + screenshots
