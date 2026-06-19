/// Stub de anúncios para plataformas sem AdMob (ex.: web de preview).
/// Mantém a mesma API pública de [AdsService], mas sem efeitos.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static const int interstitialEvery = 12;

  bool adsRemoved = false;

  Future<void> init() async {}

  void registerActionAndMaybeShow() {}

  Future<bool> showRewarded() async => false;
}
