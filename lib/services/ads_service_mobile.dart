import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centraliza a lógica de AdMob (apenas Android/iOS).
///
/// Por padrão usa os IDs de TESTE oficiais do Google. Troque [_useTestAds]
/// para `false` e preencha os IDs reais antes de publicar. NUNCA clique nos
/// próprios anúncios reais — isso gera banimento da conta AdMob.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static const bool _useTestAds = false;

  // ----- IDs de TESTE oficiais do Google -----
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testBanneriOS = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialIOS =
      'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardediOS = 'ca-app-pub-3940256099942544/1712485313';

  // ----- IDs REAIS -----
  static const _realBannerAndroid = 'ca-app-pub-5880219350817278/5661275381';
  // Ainda nao criados: caem em teste automaticamente (ver getters abaixo).
  static const _realInterstitialAndroid =
      'ca-app-pub-0000000000000000/0000000000';
  static const _realRewardedAndroid = 'ca-app-pub-0000000000000000/0000000000';

  /// ID placeholder ainda nao preenchido? Entao usamos o de teste.
  static bool _isPlaceholder(String id) => id.contains('0000000000');

  /// Dispositivos de teste: recebem ANUNCIOS DE TESTE mesmo usando os IDs
  /// reais (preenchimento garantido e ZERO risco de ban). Rode o app uma vez
  /// no seu celular e pegue o ID no logcat (linha do tipo:
  /// "setTestDeviceIds(Arrays.asList(\"33BE2250B43518CCDA7DE426D04EE231\"))")
  /// e cole aqui.
  static const List<String> _testDeviceIds = [];

  bool _initialized = false;
  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;

  /// Quando true (usuário comprou "remover anúncios"/premium), nenhum anúncio
  /// é exibido.
  bool adsRemoved = false;

  /// A cada quantas frases vistas tentamos exibir um intersticial.
  static const int interstitialEvery = 12;
  int _actionsSinceLastAd = 0;
  DateTime? _lastInterstitialShown;

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  Future<void> init() async {
    if (_initialized || !_supported) return;
    if (_testDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
    }
    await MobileAds.instance.initialize();
    _initialized = true;
    _preloadInterstitial();
  }

  String get bannerUnitId {
    if (_useTestAds) {
      return Platform.isIOS ? _testBanneriOS : _testBannerAndroid;
    }
    return _realBannerAndroid;
  }

  String get interstitialUnitId {
    if (_useTestAds || _isPlaceholder(_realInterstitialAndroid)) {
      return Platform.isIOS ? _testInterstitialIOS : _testInterstitialAndroid;
    }
    return _realInterstitialAndroid;
  }

  String get rewardedUnitId {
    if (_useTestAds || _isPlaceholder(_realRewardedAndroid)) {
      return Platform.isIOS ? _testRewardediOS : _testRewardedAndroid;
    }
    return _realRewardedAndroid;
  }

  /// Carrega e exibe um anúncio premiado. Resolve `true` se o usuário assistiu
  /// até ganhar a recompensa; `false` se falhou, não há suporte ou desistiu.
  Future<bool> showRewarded() async {
    if (!_supported) return false;
    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var earned = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(earned);
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (_, _) => earned = true);
        },
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded falhou: $err');
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  void _preloadInterstitial() {
    if (!_supported || _loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (err) {
          _interstitial = null;
          _loadingInterstitial = false;
          debugPrint('Interstitial falhou: $err');
        },
      ),
    );
  }

  /// Registra uma ação relevante (frase vista/aberta) e, ao atingir o limite,
  /// exibe o intersticial — respeitando um intervalo mínimo de 60s.
  void registerActionAndMaybeShow() {
    if (!_supported || adsRemoved) return;
    _actionsSinceLastAd++;
    if (_actionsSinceLastAd < interstitialEvery) return;

    final now = DateTime.now();
    final tooSoon = _lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!) < const Duration(seconds: 60);
    if (tooSoon) return;

    final ad = _interstitial;
    if (ad == null) {
      _preloadInterstitial();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _interstitial = null;
        _preloadInterstitial();
      },
    );
    ad.show();
    _interstitial = null;
    _actionsSinceLastAd = 0;
    _lastInterstitialShown = now;
  }
}
