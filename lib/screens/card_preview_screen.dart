import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_theme.dart';
import '../data/card_style.dart';
import '../data/models.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../widgets/shareable_card.dart';
import '../widgets/share_helper.dart';

/// Editor completo de imagem (status maker): o usuário escolhe fundo, fonte,
/// formato, alinhamento e tamanho e então salva/compartilha o cartão.
class CardPreviewScreen extends StatefulWidget {
  const CardPreviewScreen({super.key, required this.phrase});

  final Phrase phrase;

  @override
  State<CardPreviewScreen> createState() => _CardPreviewScreenState();
}

class _CardPreviewScreenState extends State<CardPreviewScreen> {
  final _captureKey = GlobalKey();
  late CardStyle _style;
  int _tab = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final bg = widget.phrase.gradient.length >= 2
        ? widget.phrase.gradient
        : AppTheme.shareGradients.first;
    _style = CardStyle(background: bg);
  }

  void _setBackground(List<Color> bg) {
    // Decide a cor do texto pelo brilho do fundo (sólido).
    final light = bg.length < 2 ? bg.first.computeLuminance() < 0.55 : true;
    setState(() => _style = _style.copyWith(background: bg, lightText: light));
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    final ok = await ShareHelper.shareBoundary(
      _captureKey,
      text: widget.phrase.shareText,
    );
    AdsService.instance.registerActionAndMaybeShow();
    if (!mounted) return;
    if (ok) context.read<AppState>().registerShared();
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível gerar a imagem.')),
      );
    } else if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagem baixada! 📥')),
      );
    }
  }

  Future<void> _shareToInstagram() async {
    setState(() => _busy = true);
    final ok = await ShareHelper.shareToInstagramStory(
      _captureKey,
      text: widget.phrase.shareText,
    );
    AdsService.instance.registerActionAndMaybeShow();
    if (!mounted) return;
    if (ok) context.read<AppState>().registerShared();
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o Instagram.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar imagem'),
        actions: [
          IconButton(
            tooltip: 'Copiar texto',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await ShareHelper.copyText(widget.phrase.shareText);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Frase copiada!')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: RepaintBoundary(
                    key: _captureKey,
                    child: ShareableCard(
                      phrase: widget.phrase,
                      style: _style,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _ControlPanel(
            style: _style,
            tab: _tab,
            onTab: (i) => setState(() => _tab = i),
            onBackground: _setBackground,
            onChange: (s) => setState(() => _style = s),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  if (!kIsWeb) ...[
                    _InstagramButton(
                      onTap: _busy ? null : _shareToInstagram,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _share,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4, color: Colors.white),
                            )
                          : Icon(kIsWeb
                              ? Icons.download_rounded
                              : Icons.ios_share_rounded),
                      label: Text(
                          kIsWeb ? 'Baixar imagem' : 'Compartilhar imagem'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painel inferior com abas: Fundo, Fonte e Formato.
class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.style,
    required this.tab,
    required this.onTab,
    required this.onBackground,
    required this.onChange,
  });

  final CardStyle style;
  final int tab;
  final ValueChanged<int> onTab;
  final ValueChanged<List<Color>> onBackground;
  final ValueChanged<CardStyle> onChange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                _TabChip(
                    icon: Icons.palette_rounded,
                    label: 'Fundo',
                    selected: tab == 0,
                    onTap: () => onTab(0)),
                _TabChip(
                    icon: Icons.text_fields_rounded,
                    label: 'Texto',
                    selected: tab == 1,
                    onTap: () => onTab(1)),
                _TabChip(
                    icon: Icons.crop_rounded,
                    label: 'Formato',
                    selected: tab == 2,
                    onTap: () => onTab(2)),
              ],
            ),
          ),
          SizedBox(
            height: 104,
            child: switch (tab) {
              0 => _BackgroundTab(style: style, onBackground: onBackground),
              1 => _TextTab(style: style, onChange: onChange),
              _ => _FormatTab(style: style, onChange: onChange),
            },
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.brandRed.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 19,
                  color: selected
                      ? AppTheme.brandRed
                      : scheme.onSurface.withValues(alpha: 0.55)),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppTheme.brandRed
                        : scheme.onSurface.withValues(alpha: 0.55),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão dedicado para postar direto nos Stories do Instagram (gradiente
/// característico). Quando [onTap] é nulo (ocupado), fica desabilitado.
class _InstagramButton extends StatelessWidget {
  const _InstagramButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color(0xFFFEDA75),
                Color(0xFFFA7E1E),
                Color(0xFFD62976),
                Color(0xFF962FBF),
                Color(0xFF4F5BD5),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Stories',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundTab extends StatelessWidget {
  const _BackgroundTab({required this.style, required this.onBackground});

  final CardStyle style;
  final ValueChanged<List<Color>> onBackground;

  @override
  Widget build(BuildContext context) {
    final options = <List<Color>>[
      ...AppTheme.shareGradients,
      ...AppTheme.shareSolids.map((c) => [c]),
    ];
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        final g = options[i];
        final selected =
            g.first.toARGB32() == style.background.first.toARGB32() &&
                g.length == style.background.length;
        return GestureDetector(
          onTap: () => onBackground(g),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: g.length >= 2 ? AppTheme.gradient(g) : null,
              color: g.length < 2 ? g.first : null,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected ? AppTheme.brandRed : Colors.black12,
                width: selected ? 3 : 1,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TextTab extends StatelessWidget {
  const _TextTab({required this.style, required this.onChange});

  final CardStyle style;
  final ValueChanged<CardStyle> onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            children: [
              for (final f in CardFont.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: style.font == f,
                    onSelected: (_) => onChange(style.copyWith(font: f)),
                  ),
                ),
              const SizedBox(width: 4),
              _ToggleIcon(
                  icon: Icons.format_align_left_rounded,
                  selected: style.align == TextAlign.left,
                  onTap: () =>
                      onChange(style.copyWith(align: TextAlign.left))),
              _ToggleIcon(
                  icon: Icons.format_align_center_rounded,
                  selected: style.align == TextAlign.center,
                  onTap: () =>
                      onChange(style.copyWith(align: TextAlign.center))),
              _ToggleIcon(
                  icon: Icons.format_align_right_rounded,
                  selected: style.align == TextAlign.right,
                  onTap: () =>
                      onChange(style.copyWith(align: TextAlign.right))),
              _ToggleIcon(
                  icon: Icons.invert_colors_rounded,
                  selected: !style.lightText,
                  onTap: () =>
                      onChange(style.copyWith(lightText: !style.lightText))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.text_decrease_rounded, size: 18),
              Expanded(
                child: Slider(
                  value: style.fontScale,
                  min: 0.7,
                  max: 1.6,
                  onChanged: (v) => onChange(style.copyWith(fontScale: v)),
                ),
              ),
              const Icon(Icons.text_increase_rounded, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormatTab extends StatelessWidget {
  const _FormatTab({required this.style, required this.onChange});

  final CardStyle style;
  final ValueChanged<CardStyle> onChange;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          for (final f in CardFormat.values)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                avatar: Icon(
                  switch (f) {
                    CardFormat.story => Icons.crop_portrait_rounded,
                    CardFormat.square => Icons.crop_square_rounded,
                    CardFormat.portrait => Icons.crop_7_5_rounded,
                  },
                  size: 18,
                ),
                label: Text('${f.label} ${f.hint}'),
                selected: style.format == f,
                onSelected: (_) => onChange(style.copyWith(format: f)),
              ),
            ),
          const SizedBox(width: 4),
          FilterChip(
            label: const Text('Autor'),
            selected: style.showAuthor,
            onSelected: (v) => onChange(style.copyWith(showAuthor: v)),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Marca'),
            selected: style.showWatermark,
            onSelected: (v) => onChange(style.copyWith(showWatermark: v)),
          ),
        ],
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  const _ToggleIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon,
          size: 20,
          color: selected
              ? AppTheme.brandRed
              : scheme.onSurface.withValues(alpha: 0.45)),
    );
  }
}
