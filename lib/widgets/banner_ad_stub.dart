import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import 'banner_ad_placeholder.dart';

/// Sem AdMob no web/preview: mostra o espaço reservado do banner (preview),
/// a menos que o usuário tenha comprado a remoção de anúncios.
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.watch<AppState>().isPremium) return const SizedBox.shrink();
    return const BannerAdPlaceholder();
  }
}
