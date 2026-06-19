import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_theme.dart';
import '../services/app_state.dart';

/// Celebração de marcos da ofensiva (3, 7, 14, 30… dias seguidos) — o gatilho
/// de retenção que os melhores apps usam para o usuário voltar todo dia.
class StreakCelebration {
  StreakCelebration._();

  static const Map<int, String> _messages = {
    3: 'Três dias seguidos! O hábito está nascendo. 🌱',
    7: 'Uma semana inteira! Você está pegando o jeito. 💪',
    14: 'Duas semanas! Isso já virou rotina boa. ✨',
    30: 'Um mês inteiro! Você é constância pura. 🏆',
    60: 'Dois meses! Poucos chegam até aqui. 🚀',
    100: '100 dias! Você é lenda. 👑',
    180: 'Meio ano! Inspiração todo santo dia. 🌟',
    365: 'UM ANO INTEIRO! Imparável. 🎉',
  };

  static Future<void> maybeShow(BuildContext context) async {
    final state = context.read<AppState>();
    final milestone = state.milestoneToCelebrate;
    if (milestone == null) return;
    state.markStreakCelebrated();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => _CelebrationDialog(
        days: milestone,
        message: _messages[milestone] ?? 'Que sequência incrível!',
      ),
    );
  }
}

class _CelebrationDialog extends StatefulWidget {
  const _CelebrationDialog({required this.days, required this.message});

  final int days;
  final String message;

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: curved,
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.gradient(
                      const [Color(0xFFFF512F), Color(0xFFF09819)]),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF512F).withValues(alpha: 0.5),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 18),
            Text('${widget.days} dias seguidos!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(widget.message,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Bora continuar! 🚀'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
