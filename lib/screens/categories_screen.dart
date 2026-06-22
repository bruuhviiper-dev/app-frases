import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/app_theme.dart';
import '../data/models.dart';
import '../services/app_state.dart';
import '../services/content_repository.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/share_helper.dart';
import '../widgets/streak_celebration.dart';
import 'card_preview_screen.dart';
import 'category_screen.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'store_screen.dart';

/// Tela inicial: frase do dia, sequência diária e grade de categorias (clean).
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Ao abrir o app, comemora se o usuário bateu um marco de ofensiva.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) StreakCelebration.maybeShow(context);
    });
  }

  Future<void> _refresh() async {
    await context.read<ContentRepository>().syncFromRemote();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final content = context.watch<ContentRepository>();
    // Frase do dia/feed/busca não mostram conteúdo exclusivo a quem não comprou.
    final phrases = content.readablePhrases(state.ownsExclusivePack);
    final lockedIds = state.ownsExclusivePack
        ? const <String>{}
        : content.categories
            .where((c) => content.isExclusive(c.id))
            .map((c) => c.id)
            .toSet();
    final today = DateTime.now().difference(DateTime(2020)).inDays;
    // Frase do dia personalizada: prioriza os temas escolhidos no onboarding.
    final dailyPool = state.hasInterests
        ? phrases.where((p) => state.isInterest(p.categoryId)).toList()
        : phrases;
    final pool = dailyPool.isEmpty ? phrases : dailyPool;
    final daily = pool[today % pool.length];

    // Separa as categorias entre "Para você" (interesses) e o resto.
    final forYou =
        content.categories.where((c) => state.isInterest(c.id)).toList();
    final others =
        content.categories.where((c) => !state.isInterest(c.id)).toList();
    final onSurfaceFaint =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppTheme.brandRed,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const _Logo(),
                        const SizedBox(width: 10),
                        Text('Frases & Status',
                            style: Theme.of(context).textTheme.headlineSmall),
                      ],
                    ),
                    Row(
                      children: [
                        _StreakChip(streak: state.streak),
                        IconButton(
                          icon: Icon(Icons.workspace_premium_rounded,
                              color: state.isPremium
                                  ? const Color(0xFFD9A406)
                                  : null),
                          tooltip: 'Loja Premium',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const StoreScreen()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search_rounded),
                          tooltip: 'Buscar',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SearchScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: _SearchBar(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: _DailyCard(phrase: daily),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradient(state.accentGradient),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(body: FeedScreen()),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Surpreenda-me',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800)),
                                  Text('Frases aleatórias no modo feed',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (forYou.isNotEmpty) ...[
              _CategorySectionHeader(
                title: 'Para você ✨',
                subtitle: 'seus temas favoritos',
                subtitleColor: onSurfaceFaint,
              ),
              _CategoryGrid(categories: forYou, lockedIds: lockedIds),
            ],
            _CategorySectionHeader(
              title: forYou.isEmpty ? 'Categorias' : 'Mais categorias',
              subtitle: '${content.totalPhrases} frases • atualiza sozinho',
              subtitleColor: onSurfaceFaint,
            ),
            _CategoryGrid(categories: others, lockedIds: lockedIds),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}

/// Selo de marca: quadradinho vermelho com aspas.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: AppTheme.gradient(context.watch<AppState>().accentGradient),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(Icons.format_quote_rounded, color: Colors.white, size: 22),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, color: accent, size: 16),
          const SizedBox(width: 5),
          Text('$streak',
              style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.search_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.5), size: 22),
              const SizedBox(width: 10),
              Text('Buscar frase, autor ou tema…',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 15,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.phrase});

  final Phrase phrase;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fav = state.isFavorite(phrase.id);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 16, 8),
      decoration: BoxDecoration(
        gradient: AppTheme.gradient(state.accentGradient),
        borderRadius: BorderRadius.circular(24),
        boxShadow:
            AppTheme.softShadow(Brightness.light, tint: state.accentColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: Colors.white.withValues(alpha: 0.95), size: 16),
              const SizedBox(width: 6),
              Text('FRASE DO DIA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(phrase.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                )),
          ),
          if (phrase.author != null) ...[
            const SizedBox(height: 10),
            Text('— ${phrase.author}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                )),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              _DailyAction(
                icon: fav
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                onTap: () =>
                    context.read<AppState>().toggleFavorite(phrase.id),
              ),
              _DailyAction(
                icon: Icons.copy_rounded,
                onTap: () async {
                  await ShareHelper.copyText(phrase.shareText);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Frase copiada!')),
                    );
                  }
                },
              ),
              _DailyAction(
                icon: Icons.image_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => CardPreviewScreen(phrase: phrase)),
                ),
              ),
              const Spacer(),
              _DailyAction(
                icon: Icons.chat_rounded,
                onTap: () {
                  ShareHelper.shareToWhatsApp(phrase.shareText);
                  context.read<AppState>().registerShared();
                },
              ),
              _DailyAction(
                icon: Icons.share_rounded,
                onTap: () => ShareHelper.shareText(phrase.shareText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyAction extends StatelessWidget {
  const _DailyAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 22),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Cabeçalho de seção de categorias (sliver).
class _CategorySectionHeader extends StatelessWidget {
  const _CategorySectionHeader({
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: subtitleColor)),
          ],
        ),
      ),
    );
  }
}

/// Grade 2 colunas de categorias (sliver).
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories, this.lockedIds = const {}});

  final List<PhraseCategory> categories;
  final Set<String> lockedIds;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final c = categories[i];
            final locked = lockedIds.contains(c.id);
            return _CategoryTile(
              name: c.name,
              emoji: c.emoji,
              gradient: c.gradient,
              count: c.phrases.length,
              locked: locked,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => locked
                        ? const StoreScreen()
                        : CategoryScreen(categoryId: c.id),
                  ),
                );
              },
            );
          },
          childCount: categories.length,
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.emoji,
    required this.gradient,
    required this.count,
    required this.onTap,
    this.locked = false,
  });

  final String name;
  final String emoji;
  final List<Color> gradient;
  final int count;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.gradient(gradient),
            borderRadius: BorderRadius.circular(22),
          ),
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withValues(alpha: 0.18),
            child: Stack(
              children: [
                // Emoji gigante como marca d'água no canto.
                Positioned(
                  right: -6,
                  bottom: -10,
                  child: Text(
                    emoji,
                    style: TextStyle(
                      fontSize: 92,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                // Profundidade: brilho no topo, leve sombra embaixo.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.18),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selo do emoji em vidro fosco arredondado.
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                              width: 1.2),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                      const Spacer(),
                      Text(name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            height: 1.05,
                          )),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                              locked
                                  ? Icons.lock_rounded
                                  : Icons.format_quote_rounded,
                              color: Colors.white.withValues(alpha: 0.85),
                              size: 13),
                          const SizedBox(width: 4),
                          Text(locked ? 'Exclusivo' : '$count frases',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              )),
                          const Spacer(),
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                                locked
                                    ? Icons.lock_rounded
                                    : Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
