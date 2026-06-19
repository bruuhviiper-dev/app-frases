import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import '../data/phrases.dart';
import 'store_products.dart';

/// Repositório de conteúdo do app.
///
/// Combina o conteúdo EMBUTIDO (semente) com atualizações vindas de um JSON
/// remoto — assim o app "sempre se atualiza" com frases novas SEM precisar de
/// uma nova versão na Play Store. O conteúdo remoto é cacheado localmente e
/// usado como fallback offline.
class ContentRepository extends ChangeNotifier {
  ContentRepository(this._prefs) {
    _categories = PhraseData.bundled;
    _loadCache();
  }

  final SharedPreferences _prefs;

  /// URL do JSON remoto. Hospede `content/phrases.json` (ex.: GitHub Raw,
  /// Firebase Hosting, seu site) e atualize-o quando quiser publicar frases
  /// novas. Veja o formato em `content/phrases.json`.
  static const String remoteUrl =
      'https://raw.githubusercontent.com/SEU_USUARIO/frases-status-content/main/phrases.json';

  static const _kCacheJson = 'content_cache_json';
  static const _kContentVersion = 'content_version';
  static const _kLastSync = 'content_last_sync';

  late List<PhraseCategory> _categories;
  int _version = 0;
  bool _updating = false;

  List<PhraseCategory> get categories => _categories;
  int get version => _version;
  bool get isUpdating => _updating;
  int get totalPhrases =>
      _categories.fold(0, (sum, c) => sum + c.phrases.length);

  List<Phrase> get allPhrases => PhraseData.flatten(_categories);

  /// É uma categoria de conteúdo exclusivo (bloqueada sem o pacote)?
  bool isExclusive(String categoryId) =>
      StoreProducts.exclusiveCategoryIds.contains(categoryId);

  /// Frases que o usuário pode LER (frase do dia, feed aleatório, busca).
  /// Quando [ownsExclusive] é falso, remove as categorias exclusivas para o
  /// conteúdo premium não vazar fora da loja.
  List<Phrase> readablePhrases(bool ownsExclusive) {
    if (ownsExclusive) return allPhrases;
    return PhraseData.flatten(
        _categories.where((c) => !isExclusive(c.id)).toList());
  }

  PhraseCategory categoryById(String id) => _categories
      .firstWhere((c) => c.id == id, orElse: () => _categories.first);

  List<Phrase> phrasesOf(String categoryId) =>
      PhraseData.flatten([categoryById(categoryId)]);

  void _loadCache() {
    _version = _prefs.getInt(_kContentVersion) ?? 0;
    final cached = _prefs.getString(_kCacheJson);
    if (cached == null) return;
    try {
      final parsed = _parse(jsonDecode(cached));
      if (parsed.isNotEmpty) {
        _categories = _merge(PhraseData.bundled, parsed);
      }
    } catch (e) {
      debugPrint('Falha ao ler cache de conteúdo: $e');
    }
  }

  /// Busca o conteúdo remoto e mescla. Seguro para chamar em toda abertura:
  /// se falhar (offline/URL inválida), mantém o conteúdo atual.
  Future<void> syncFromRemote() async {
    if (_updating) return;
    _updating = true;
    try {
      final resp = await http
          .get(Uri.parse(remoteUrl))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return;

      final body = jsonDecode(utf8.decode(resp.bodyBytes));
      final remoteVersion = (body is Map && body['version'] is int)
          ? body['version'] as int
          : 0;
      final cats = _parse(body);
      if (cats.isEmpty) return;

      _categories = _merge(PhraseData.bundled, cats);
      _version = remoteVersion;
      await _prefs.setString(_kCacheJson, jsonEncode(body));
      await _prefs.setInt(_kContentVersion, remoteVersion);
      await _prefs.setInt(_kLastSync, DateTime.now().millisecondsSinceEpoch);
      notifyListeners();
    } catch (e) {
      debugPrint('Sync de conteúdo falhou (mantendo atual): $e');
    } finally {
      _updating = false;
    }
  }

  /// Aceita tanto `{"version":N,"categories":[...]}` quanto uma lista direta.
  List<PhraseCategory> _parse(dynamic json) {
    final List rawList;
    if (json is Map && json['categories'] is List) {
      rawList = json['categories'] as List;
    } else if (json is List) {
      rawList = json;
    } else {
      return const [];
    }
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(PhraseCategory.fromJson)
        .whereType<PhraseCategory>()
        .toList();
  }

  /// Mescla base + remoto: categorias novas são adicionadas; categorias
  /// existentes recebem as frases novas (sem duplicar).
  List<PhraseCategory> _merge(
      List<PhraseCategory> base, List<PhraseCategory> remote) {
    final byId = {for (final c in base) c.id: c};
    final order = [for (final c in base) c.id];

    for (final r in remote) {
      final existing = byId[r.id];
      if (existing == null) {
        byId[r.id] = r;
        order.add(r.id);
      } else {
        byId[r.id] = existing.merge(r.phrases, r.authors ?? const <String?>[]);
      }
    }
    return [for (final id in order) byId[id]!];
  }
}
