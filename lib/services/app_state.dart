import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_palettes.dart';
import '../data/models.dart';

/// Estado global do app: favoritos, sequência (ofensiva) diária, tema,
/// histórico de frases vistas, preferências de notificação e contadores usados
/// pela lógica de anúncios.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  static const _kFavorites = 'favorites';
  static const _kThemeMode = 'theme_mode';
  static const _kStreak = 'streak_count';
  static const _kLastOpen = 'last_open_day';
  static const _kBestStreak = 'best_streak';
  static const _kSeenCount = 'seen_count';
  static const _kSharedCount = 'shared_count';
  static const _kNotifEnabled = 'notif_enabled';
  static const _kNotifHour = 'notif_hour';
  static const _kNotifMinute = 'notif_minute';
  static const _kEveningEnabled = 'notif_evening';
  static const _kMyPhrases = 'my_phrases';
  static const _kHistory = 'view_history';
  static const _kInterests = 'interests';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kRatePromptDone = 'rate_prompt_done';
  static const _kCelebratedStreak = 'celebrated_streak';
  static const _kEntitlements = 'entitlements';
  static const _kPaletteId = 'palette_id';

  /// Compra que remove anúncios e a do pacote completo.
  static const String pRemoveAds = 'remove_ads';
  static const String pBundle = 'premium_bundle';

  /// Marcos da ofensiva que disparam uma celebração.
  static const List<int> streakMilestones = [3, 7, 14, 30, 60, 100, 180, 365];

  /// Quantas frases o histórico guarda (vistas recentes).
  static const int historyLimit = 100;

  final Set<String> _favorites = {};
  final Set<String> _interests = {};
  final Set<String> _entitlements = {};
  String _paletteId = 'classico';
  final List<String> _myPhrases = [];
  final List<ViewedPhrase> _history = [];
  bool _onboardingComplete = false;
  bool _ratePromptDone = false;
  int _celebratedStreak = 0;
  ThemeMode _themeMode = ThemeMode.light;
  int _streak = 0;
  int _bestStreak = 0;
  int _seenCount = 0;
  int _sharedCount = 0;
  bool _notificationsEnabled = true;
  int _notifHour = 9;
  int _notifMinute = 0;
  bool _eveningEnabled = false;

  Set<String> get favorites => _favorites;
  Set<String> get interests => _interests;
  bool get onboardingComplete => _onboardingComplete;
  List<String> get myPhrases => List.unmodifiable(_myPhrases);
  List<ViewedPhrase> get history => List.unmodifiable(_history);
  ThemeMode get themeMode => _themeMode;
  int get streak => _streak;
  int get bestStreak => _bestStreak;
  int get seenCount => _seenCount;
  int get sharedCount => _sharedCount;
  bool get notificationsEnabled => _notificationsEnabled;
  int get notifHour => _notifHour;
  int get notifMinute => _notifMinute;
  bool get eveningEnabled => _eveningEnabled;
  bool get hasFavorites => _favorites.isNotEmpty;
  bool get hasHistory => _history.isNotEmpty;
  bool get hasInterests => _interests.isNotEmpty;

  // ----- Loja / compras (compra única) -----
  Set<String> get entitlements => Set.unmodifiable(_entitlements);

  /// Comprou o "remover anúncios" ou o pacote premium.
  bool get isPremium =>
      _entitlements.contains(pRemoveAds) || _entitlements.contains(pBundle);

  /// O pacote premium dá direito a tudo.
  bool get hasBundle => _entitlements.contains(pBundle);

  bool ownsProduct(String productId) =>
      _entitlements.contains(productId) || hasBundle;

  bool ownsPalette(String paletteId) {
    final p = AppPalettes.byId(paletteId);
    if (!p.premium) return true; // tema grátis
    return p.productId != null && ownsProduct(p.productId!);
  }

  /// Paleta de cores ativa (tema vendável).
  AppPalette get palette => AppPalettes.byId(_paletteId);
  Color get accentColor => palette.accent;
  List<Color> get accentGradient => palette.gradient;

  /// Concede um item comprado (chamado pelo serviço de compras).
  void grantEntitlement(String productId) {
    if (_entitlements.add(productId)) {
      _prefs.setStringList(_kEntitlements, _entitlements.toList());
      notifyListeners();
    }
  }

  /// Seleciona a paleta ativa (só se o usuário tiver direito a ela).
  void setPalette(String paletteId) {
    if (!ownsPalette(paletteId)) return;
    _paletteId = paletteId;
    _prefs.setString(_kPaletteId, paletteId);
    notifyListeners();
  }

  /// Mostra o convite de avaliação no momento certo: depois de o usuário já ter
  /// compartilhado algumas frases (engajado) e ainda não ter respondido.
  bool get shouldAskRate => !_ratePromptDone && _sharedCount >= 3;

  /// Horário da frase do dia no formato HH:MM (para exibir nos Ajustes).
  String get notifTimeLabel =>
      '${_notifHour.toString().padLeft(2, '0')}:'
      '${_notifMinute.toString().padLeft(2, '0')}';

  /// Próxima meta da ofensiva (para motivar o usuário a voltar amanhã).
  int get nextStreakMilestone {
    const milestones = [3, 7, 14, 30, 60, 100, 180, 365];
    for (final m in milestones) {
      if (_streak < m) return m;
    }
    return _streak + 100;
  }

  void _load() {
    _favorites
      ..clear()
      ..addAll(_prefs.getStringList(_kFavorites) ?? const []);
    final modeIndex = _prefs.getInt(_kThemeMode);
    if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }
    _streak = _prefs.getInt(_kStreak) ?? 0;
    _bestStreak = _prefs.getInt(_kBestStreak) ?? 0;
    _seenCount = _prefs.getInt(_kSeenCount) ?? 0;
    _sharedCount = _prefs.getInt(_kSharedCount) ?? 0;
    _notificationsEnabled = _prefs.getBool(_kNotifEnabled) ?? true;
    _notifHour = _prefs.getInt(_kNotifHour) ?? 9;
    _notifMinute = _prefs.getInt(_kNotifMinute) ?? 0;
    _eveningEnabled = _prefs.getBool(_kEveningEnabled) ?? false;
    _interests
      ..clear()
      ..addAll(_prefs.getStringList(_kInterests) ?? const []);
    _onboardingComplete = _prefs.getBool(_kOnboardingDone) ?? false;
    _ratePromptDone = _prefs.getBool(_kRatePromptDone) ?? false;
    _celebratedStreak = _prefs.getInt(_kCelebratedStreak) ?? 0;
    _entitlements
      ..clear()
      ..addAll(_prefs.getStringList(_kEntitlements) ?? const []);
    _paletteId = _prefs.getString(_kPaletteId) ?? 'classico';
    // Se perdeu o direito à paleta (ex.: reembolso), volta pro tema grátis.
    if (!ownsPalette(_paletteId)) _paletteId = 'classico';
    _myPhrases
      ..clear()
      ..addAll(_prefs.getStringList(_kMyPhrases) ?? const []);
    _history
      ..clear()
      ..addAll((_prefs.getStringList(_kHistory) ?? const [])
          .map(ViewedPhrase.tryDecode)
          .whereType<ViewedPhrase>());
    _updateStreak();
  }

  /// Número inteiro do dia atual (dias desde a época), em horário local.
  int get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
            .difference(DateTime(2020))
            .inDays;
  }

  /// Atualiza a sequência diária na abertura do app.
  void _updateStreak() {
    final last = _prefs.getInt(_kLastOpen);
    final today = _today;
    if (last == today) return; // já contabilizado hoje
    if (last == today - 1) {
      _streak += 1; // dia consecutivo
    } else {
      _streak = 1; // recomeça a ofensiva
    }
    if (_streak > _bestStreak) _bestStreak = _streak;
    _prefs
      ..setInt(_kLastOpen, today)
      ..setInt(_kStreak, _streak)
      ..setInt(_kBestStreak, _bestStreak);
    notifyListeners();
  }

  bool isFavorite(String id) => _favorites.contains(id);

  void toggleFavorite(String id) {
    if (!_favorites.remove(id)) _favorites.add(id);
    _prefs.setStringList(_kFavorites, _favorites.toList());
    notifyListeners();
  }

  /// Salva uma frase criada pelo usuário (mais recentes primeiro).
  void addMyPhrase(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _myPhrases
      ..remove(t)
      ..insert(0, t);
    _prefs.setStringList(_kMyPhrases, _myPhrases);
    notifyListeners();
  }

  void removeMyPhrase(String text) {
    if (_myPhrases.remove(text)) {
      _prefs.setStringList(_kMyPhrases, _myPhrases);
      notifyListeners();
    }
  }

  bool isInterest(String categoryId) => _interests.contains(categoryId);

  void toggleInterest(String categoryId) {
    if (!_interests.remove(categoryId)) _interests.add(categoryId);
    _prefs.setStringList(_kInterests, _interests.toList());
    notifyListeners();
  }

  /// Define os temas favoritos de uma vez (usado no onboarding).
  void setInterests(Iterable<String> categoryIds) {
    _interests
      ..clear()
      ..addAll(categoryIds);
    _prefs.setStringList(_kInterests, _interests.toList());
    notifyListeners();
  }

  /// Marca o onboarding como concluído (não aparece mais na abertura).
  void completeOnboarding() {
    _onboardingComplete = true;
    _prefs.setBool(_kOnboardingDone, true);
    notifyListeners();
  }

  /// Registra que o usuário já respondeu ao convite de avaliação.
  void markRatePromptDone() {
    _ratePromptDone = true;
    _prefs.setBool(_kRatePromptDone, true);
  }

  /// Maior marco de ofensiva ainda não comemorado (ou null se não há).
  int? get milestoneToCelebrate {
    for (final m in streakMilestones.reversed) {
      if (_streak >= m && _celebratedStreak < m) return m;
    }
    return null;
  }

  /// Marca que o usuário já viu a celebração do marco atual.
  void markStreakCelebrated() {
    _celebratedStreak = _streak;
    _prefs.setInt(_kCelebratedStreak, _streak);
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setInt(_kThemeMode, mode.index);
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    _prefs.setBool(_kNotifEnabled, value);
    notifyListeners();
  }

  /// Define o horário da frase do dia.
  void setNotificationTime(int hour, int minute) {
    _notifHour = hour;
    _notifMinute = minute;
    _prefs
      ..setInt(_kNotifHour, hour)
      ..setInt(_kNotifMinute, minute);
    notifyListeners();
  }

  /// Liga/desliga a segunda notificação (frase da noite).
  void setEveningEnabled(bool value) {
    _eveningEnabled = value;
    _prefs.setBool(_kEveningEnabled, value);
    notifyListeners();
  }

  /// Registra uma frase vista: conta a visualização e a guarda no histórico
  /// (vistas recentes, sem duplicar, mais nova primeiro). Dispara anúncios
  /// intersticiais a cada N visualizações via [seenCount].
  void registerView(Phrase phrase) {
    _seenCount += 1;
    _prefs.setInt(_kSeenCount, _seenCount);

    final entry = ViewedPhrase.fromPhrase(phrase);
    _history.removeWhere((e) => e.text == entry.text);
    _history.insert(0, entry);
    if (_history.length > historyLimit) {
      _history.removeRange(historyLimit, _history.length);
    }
    _prefs.setStringList(_kHistory, [for (final e in _history) e.encode()]);

    // Notifica de forma esparsa para não reconstruir a árvore a cada swipe.
    if (_seenCount % 5 == 0) notifyListeners();
  }

  /// Conta um compartilhamento (estatística de engajamento).
  void registerShared() {
    _sharedCount += 1;
    _prefs.setInt(_kSharedCount, _sharedCount);
  }

  void clearHistory() {
    _history.clear();
    _prefs.remove(_kHistory);
    notifyListeners();
  }
}

/// Frase guardada no histórico de "vistas recentes". Leve e serializável em
/// JSON para persistir em [SharedPreferences].
class ViewedPhrase {
  const ViewedPhrase({
    required this.categoryId,
    required this.categoryName,
    required this.text,
    this.author,
  });

  final String categoryId;
  final String categoryName;
  final String text;
  final String? author;

  factory ViewedPhrase.fromPhrase(Phrase p) => ViewedPhrase(
        categoryId: p.categoryId,
        categoryName: p.categoryName,
        text: p.text,
        author: p.author,
      );

  String get shareText => author == null ? text : '$text\n— $author';

  String encode() => jsonEncode(
      {'c': categoryId, 'n': categoryName, 't': text, 'a': author});

  static ViewedPhrase? tryDecode(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final text = m['t'] as String?;
      if (text == null || text.trim().isEmpty) return null;
      return ViewedPhrase(
        categoryId: (m['c'] as String?) ?? '',
        categoryName: (m['n'] as String?) ?? 'Frase',
        text: text,
        author: m['a'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
