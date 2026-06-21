/// Identidade do app + catálogo de apps (cross-promoção / tráfego orgânico).
class AppInfo {
  AppInfo._();

  static const developer = 'NojaTools Apps';
  static const appName = 'Frases & Status';
  static const packageId = 'com.frasesstatus.frases_status';

  static String playUrlFor(String id) =>
      'https://play.google.com/store/apps/details?id=$id';

  static const playUrl = 'https://play.google.com/store/apps/details?id=$packageId';
  static const devUrl =
      'https://play.google.com/store/apps/developer?id=NojaTools+Apps';
  static const shareFooter = '📲 Baixe grátis: $playUrl';

  static const List<(String, String)> apps = [
    ('Frases & Status', 'com.frasesstatus.frases_status'),
    ('Frases Bíblicas', 'com.frasesbiblicas.frases_biblicas'),
    ('Bom Dia, Tarde e Noite', 'com.mensagens.mensagens'),
    ('Foco em Foco', 'com.focoemfoco.foco'),
    ('Frases Indiretas', 'com.indiretas.indiretas'),
    ('Mensagens de Aniversário', 'com.aniversario.aniversario'),
  ];

  static List<(String, String)> get otherApps =>
      apps.where((a) => a.$2 != packageId).toList();
}
