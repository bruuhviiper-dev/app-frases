import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:provider/provider.dart';

import '../services/ads_service_mobile.dart';
import '../services/app_state.dart';
import 'banner_ad_placeholder.dart';

/// Banner ancorado, reutilizável em telas de lista. Mostra o espaço reservado
/// (preview) enquanto carrega e se remove sozinho caso o anúncio falhe.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Não carrega anúncio para quem comprou "remover anúncios"/premium.
    final premium = context.read<AppState>().isPremium;
    if (!premium && (Platform.isAndroid || Platform.isIOS)) _load();
  }

  void _load() {
    final ad = BannerAd(
      adUnitId: AdsService.instance.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _loaded = false;
              _failed = true;
            });
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Premium: sem anúncios e sem espaço reservado.
    if (context.watch<AppState>().isPremium) return const SizedBox.shrink();
    // Anúncio falhou de vez: não ocupa espaço (não deixa marcador em produção).
    if (_failed) return const SizedBox.shrink();
    // Ainda carregando: reserva o espaço do banner com o marcador de preview.
    if (!_loaded || _ad == null) return const BannerAdPlaceholder();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
