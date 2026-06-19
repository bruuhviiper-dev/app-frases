# Frases & Status 💜

App de frases e mensagens em português, focado em **uso diário** e
**receita com AdMob**. Inspirado nos maiores apps de frases do Brasil, com um
diferencial próprio: um **feed vertical estilo Reels** de frases.

## Diferenciais (o que torna único)

1. **Feed deslizável (modo Reels)** — deslize para cima para a próxima frase em
   tela cheia com gradiente. Vicia o uso e multiplica as impressões de anúncio.
2. **Sequência diária (🔥 ofensiva)** — conta dias consecutivos de uso, no estilo
   Duolingo, para criar hábito e retenção.
3. **Frase do dia + notificação** — uma frase nova toda manhã (09h) traz o
   usuário de volta ao app.
4. **Compartilhar como imagem** — cada frase vira um cartão bonito pronto para o
   Status do WhatsApp/Instagram, com assinatura do app (marketing orgânico).
5. **Conteúdo que se atualiza sozinho** — o app busca um JSON remoto e mescla
   frases/categorias novas SEM precisar de atualização na Play Store. Cresce
   continuamente (ideal para campanhas com influenciadores).
6. **Busca** instantânea por palavra ou categoria.
7. **Favoritas, tema claro/escuro** e 20 categorias (Bom dia, Boa noite, Amor,
   Motivação, Indiretas, Reflexão, Fé, Amizade, Aniversário, Superação, Sextou,
   Humor, Gratidão, Saudade, Família, Status curtos, Foco & Sucesso, Paz
   interior, Desabafo, Café & Segunda) — 440+ frases originais e contando.

## Conteúdo auto-atualizável

- Base embutida em `lib/data/phrases.dart` (funciona 100% offline).
- `lib/services/content_repository.dart` busca `remoteUrl` (um JSON), faz cache
  local e **mescla**: categorias novas são adicionadas; categorias existentes
  recebem frases novas (sem duplicar).
- Modelo do arquivo remoto: `content/phrases.json`. Para publicar frases novas,
  edite o JSON hospedado e aumente o campo `version`. Pronto — todos os apps
  recebem na próxima abertura (ou via Ajustes → "Atualizar frases agora").
- Como os textos são originais, os usuários compartilham sem risco de direitos
  autorais.

## Estrutura

```
lib/
  data/        models, banco de frases, tema
  services/    estado global, AdMob, notificações
  widgets/     cartão de frase, item de lista, banner, share helper
  screens/     home (categorias), feed, categoria, favoritas, ajustes
```

## Monetização (AdMob)

- **Banner** ancorado nas telas de lista.
- **Intersticial** a cada `interstitialEvery` (12) frases vistas, com intervalo
  mínimo de 60s entre exibições (evita punição da política do AdMob).

> ⚠️ Por padrão o app usa os **IDs de teste** do Google. Antes de publicar:
> 1. Em `lib/services/ads_service.dart`, troque `_useTestAds` para `false` e
>    preencha os IDs reais (`_realBannerAndroid`, `_realInterstitialAndroid`).
> 2. Em `android/app/src/main/AndroidManifest.xml`, troque o
>    `com.google.android.gms.ads.APPLICATION_ID` pelo seu App ID real.
> 3. **Nunca** clique nos próprios anúncios reais — gera banimento da conta.

## Rodar

```bash
flutter pub get
flutter run
```

## Próximos passos sugeridos

- Tela de busca de frases.
- Mais frases por categoria (o conteúdo é o motor da retenção).
- App Open Ad na abertura (com cuidado para não irritar).
- Consentimento (UMP/GDPR) caso publique fora do Brasil.
