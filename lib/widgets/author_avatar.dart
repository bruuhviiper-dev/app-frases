import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Avatar do autor em preto e branco, redondo.
///
/// Ordem de resolução da imagem:
/// 1. [authorImages] — mapa manual (asset em `assets/authors/` ou URL). Use
///    para garantir uma foto específica e de licença segura.
/// 2. Busca automática do retrato na Wikipédia (REST summary API) pelo nome do
///    autor. Resultado fica em cache na memória para não repetir requisição.
/// 3. Monograma (iniciais) num círculo escuro — elegante e 100% offline.
///
/// A imagem é sempre exibida em tons de cinza e recortada em círculo.
///
/// ⚠️ Direitos: prefira fotos de autores clássicos / domínio público. Para
/// figuras modernas, registre uma imagem de licença livre em [authorImages]
/// ou deixe o monograma (a busca automática pode trazer imagem protegida).
class AuthorAvatar extends StatefulWidget {
  const AuthorAvatar({
    super.key,
    required this.author,
    this.size = 44,
    this.autoFetch = true,
  });

  final String author;
  final double size;

  /// Se deve tentar buscar o retrato na Wikipédia quando não houver imagem
  /// manual registrada. Desligue para um app 100% offline/sem requisições.
  final bool autoFetch;

  /// Mapa autor → imagem (asset path ou URL). Tem prioridade sobre a busca.
  static const Map<String, String> authorImages = {
    // 'Machado de Assis': 'assets/authors/machado.jpg',
    // 'Sócrates': 'https://.../socrates.jpg',
  };

  /// Idiomas de Wikipédia tentados na busca automática, em ordem.
  static const List<String> _wikiLangs = ['pt', 'en'];

  /// Cache em memória: autor → URL do retrato (null = sem foto encontrada).
  static final Map<String, String?> _urlCache = {};

  /// Filtro que deixa qualquer imagem em preto e branco.
  static const ColorFilter grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  /// Resolve a URL do retrato na Wikipédia (com cache). Retorna null se não
  /// encontrar ou em caso de erro/sem internet.
  static Future<String?> resolvePortrait(String author) async {
    if (_urlCache.containsKey(author)) return _urlCache[author];
    for (final lang in _wikiLangs) {
      try {
        final title = Uri.encodeComponent(author.replaceAll(' ', '_'));
        final uri = Uri.parse(
            'https://$lang.wikipedia.org/api/rest_v1/page/summary/$title');
        final resp = await http
            .get(uri, headers: {'accept': 'application/json'}).timeout(
                const Duration(seconds: 6));
        if (resp.statusCode != 200) continue;
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final src = (data['thumbnail'] as Map?)?['source'] as String?;
        if (src != null && src.isNotEmpty) {
          _urlCache[author] = src;
          return src;
        }
      } catch (_) {
        // tenta o próximo idioma; se todos falharem, cai no monograma.
      }
    }
    _urlCache[author] = null;
    return null;
  }

  @override
  State<AuthorAvatar> createState() => _AuthorAvatarState();
}

class _AuthorAvatarState extends State<AuthorAvatar> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AuthorAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.author != widget.author) {
      _url = null;
      _load();
    }
  }

  Future<void> _load() async {
    // 1) imagem manual tem prioridade.
    final manual = AuthorAvatar.authorImages[widget.author];
    if (manual != null) {
      setState(() => _url = manual);
      return;
    }
    if (!widget.autoFetch || widget.author.trim().isEmpty) return;
    // 2) busca automática (com cache).
    final src = await AuthorAvatar.resolvePortrait(widget.author);
    if (mounted && src != null) setState(() => _url = src);
  }

  String get _initials {
    final parts = widget.author
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2) // ignora "de", "da", "e"...
        .toList();
    if (parts.isEmpty) {
      return widget.author.isNotEmpty ? widget.author[0].toUpperCase() : '?';
    }
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    Widget content;

    final url = _url;
    if (url != null) {
      final img = url.startsWith('http')
          ? Image.network(url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => _monogram(size))
          : Image.asset(url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _monogram(size));
      content = ColorFiltered(colorFilter: AuthorAvatar.grayscale, child: img);
    } else {
      content = _monogram(size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(child: content),
    );
  }

  Widget _monogram(double size) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2B2E), Color(0xFF6E6E73)],
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
