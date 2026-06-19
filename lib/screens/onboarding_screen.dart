import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_theme.dart';
import '../services/app_state.dart';
import '../services/content_repository.dart';

/// Primeira execução: dá as boas-vindas e deixa o usuário escolher seus temas
/// favoritos. Isso personaliza a tela inicial ("Para você") — recurso presente
/// nos maiores apps de frases/motivação do mundo.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Set<String> _selected = {};

  void _finish(BuildContext context) {
    final state = context.read<AppState>();
    state.setInterests(_selected);
    state.completeOnboarding();
    // Se foi reaberto pelos Ajustes (rota empurrada), fecha ao concluir.
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    // Reaberto pelos Ajustes: começa com os temas já escolhidos marcados.
    final current = context.read<AppState>().interests;
    _selected.addAll(current);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ContentRepository>().categories;
    final scheme = Theme.of(context).colorScheme;
    final canContinue = _selected.length >= 3;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppTheme.gradient(AppTheme.redGradient),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.format_quote_rounded,
                                color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 20),
                          Text('Bem-vindo ao\nFrases & Status 💜',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium),
                          const SizedBox(height: 10),
                          Text(
                            'Escolha os temas que mais combinam com você. '
                            'Vamos deixar suas frases com a sua cara.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color:
                                  scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Seus temas favoritos',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(
                                '${_selected.length} escolhidos',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: canContinue
                                      ? AppTheme.brandRed
                                      : scheme.onSurface
                                          .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final c in categories)
                            _InterestChip(
                              label: c.name,
                              emoji: c.emoji,
                              gradient: c.gradient,
                              selected: _selected.contains(c.id),
                              onTap: () => setState(() {
                                if (!_selected.remove(c.id)) {
                                  _selected.add(c.id);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          canContinue ? () => _finish(context) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(canContinue
                            ? 'Começar'
                            : 'Escolha pelo menos 3 temas'),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _finish(context),
                    child: Text('Pular por agora',
                        style: TextStyle(
                            color:
                                scheme.onSurface.withValues(alpha: 0.55))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.emoji,
    required this.gradient,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final List<Color> gradient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.gradient(gradient) : null,
          color: selected ? null : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : scheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : scheme.onSurface,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
