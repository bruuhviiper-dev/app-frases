import 'package:flutter/material.dart';

/// Avatar do autor em preto e branco.
///
/// Mostra a foto/caricatura do autor em tons de cinza quando há uma imagem
/// registrada em [authorImages]; caso contrário, exibe um **monograma**
/// (iniciais) num círculo escuro — elegante e que funciona 100% offline.
///
/// COMO ADICIONAR FOTOS/CARICATURAS REAIS:
/// 1. Coloque os arquivos em `assets/authors/` (ex.: `einstein.jpg`).
/// 2. Declare a pasta em `pubspec.yaml` (em `flutter: assets:`).
/// 3. Registre abaixo: `'Albert Einstein': 'assets/authors/einstein.jpg'`.
/// (Também aceita URL `http(s)://...`.)
class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar({super.key, required this.author, this.size = 44});

  final String author;
  final double size;

  /// Mapa autor → imagem (asset path ou URL). Vazio por padrão: o app usa o
  /// monograma. Preencha para mostrar as fotos P&B reais.
  static const Map<String, String> authorImages = {
    // 'Albert Einstein': 'assets/authors/einstein.jpg',
    // 'Nikola Tesla': 'assets/authors/tesla.jpg',
  };

  /// Filtro que deixa qualquer imagem em preto e branco.
  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  String get _initials {
    final parts = author
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2) // ignora "de", "da", "e"...
        .toList();
    if (parts.isEmpty) return author.isNotEmpty ? author[0].toUpperCase() : '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final image = authorImages[author];
    Widget content;

    if (image != null) {
      final img = image.startsWith('http')
          ? Image.network(image,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _monogram())
          : Image.asset(image,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _monogram());
      content = ColorFiltered(colorFilter: _grayscale, child: img);
    } else {
      content = _monogram();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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

  Widget _monogram() {
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
