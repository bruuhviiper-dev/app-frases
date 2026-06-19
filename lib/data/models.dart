import 'package:flutter/material.dart';

/// Uma categoria de frases (ex.: Bom dia, Amor, Pensadores).
///
/// [phrases] e [authors] são listas paralelas (mesmo índice). [authors] é
/// opcional: quando nulo ou com entrada nula, a frase é anônima/original.
class PhraseCategory {
  const PhraseCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.gradient,
    required this.phrases,
    this.authors,
  });

  final String id;
  final String name;
  final String emoji;
  final List<Color> gradient;
  final List<String> phrases;
  final List<String?>? authors;

  String? authorAt(int i) {
    final a = authors;
    if (a == null || i >= a.length) return null;
    final v = a[i];
    return (v == null || v.trim().isEmpty) ? null : v;
  }

  /// Mescla novas frases (com seus autores) sem duplicar pelo texto.
  PhraseCategory merge(List<String> extraPhrases, List<String?> extraAuthors) {
    final byText = <String, String?>{};
    final order = <String>[];

    void add(String text, String? author) {
      final key = text.trim();
      if (key.isEmpty) return;
      final low = key.toLowerCase();
      if (!byText.containsKey(low)) {
        order.add(key);
        byText[low] = author;
      } else if (byText[low] == null && author != null) {
        byText[low] = author; // completa o autor de uma frase já existente
      }
    }

    for (var i = 0; i < phrases.length; i++) {
      add(phrases[i], authorAt(i));
    }
    for (var i = 0; i < extraPhrases.length; i++) {
      final author = i < extraAuthors.length ? extraAuthors[i] : null;
      add(extraPhrases[i], author);
    }

    final mergedPhrases = order;
    final mergedAuthors = [for (final t in order) byText[t.toLowerCase()]];
    return PhraseCategory(
      id: id,
      name: name,
      emoji: emoji,
      gradient: gradient,
      phrases: mergedPhrases,
      authors: mergedAuthors,
    );
  }

  /// Constrói a categoria a partir do JSON remoto.
  ///
  /// `phrases` aceita itens como string (`"texto"`) ou objeto
  /// (`{"text": "...", "author": "..."}`).
  static PhraseCategory? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    if (id == null || name == null) return null;

    final gradientRaw = (json['gradient'] as List?) ?? const [];
    final gradient = gradientRaw
        .map((e) => _hexToColor(e.toString()))
        .whereType<Color>()
        .toList();

    final phrases = <String>[];
    final authors = <String?>[];
    for (final item in (json['phrases'] as List?) ?? const []) {
      if (item is String) {
        if (item.trim().isEmpty) continue;
        phrases.add(item);
        authors.add(null);
      } else if (item is Map) {
        final text = (item['text'] ?? '').toString();
        if (text.trim().isEmpty) continue;
        phrases.add(text);
        final a = item['author']?.toString();
        authors.add((a == null || a.trim().isEmpty) ? null : a);
      }
    }

    return PhraseCategory(
      id: id,
      name: name,
      emoji: (json['emoji'] as String?) ?? '✨',
      gradient: gradient.length >= 2
          ? gradient
          : const [Color(0xFFFF1744), Color(0xFFD50032)],
      phrases: phrases,
      authors: authors.any((e) => e != null) ? authors : null,
    );
  }

  static Color? _hexToColor(String hex) {
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final value = int.tryParse(h, radix: 16);
    return value == null ? null : Color(value);
  }
}

/// Uma frase concreta dentro do app, com referência à categoria de origem.
class Phrase {
  const Phrase({
    required this.text,
    required this.categoryId,
    required this.categoryName,
    required this.gradient,
    this.author,
  });

  final String text;
  final String categoryId;
  final String categoryName;
  final List<Color> gradient;
  final String? author;

  /// Texto pronto para copiar/compartilhar (com autor, se houver).
  String get shareText => author == null ? text : '$text\n— $author';

  /// Chave estável usada para favoritos e histórico.
  String get id => '$categoryId::${text.hashCode}';

  Phrase copyWith({List<Color>? gradient}) => Phrase(
        text: text,
        categoryId: categoryId,
        categoryName: categoryName,
        gradient: gradient ?? this.gradient,
        author: author,
      );
}
