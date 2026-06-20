import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_theme.dart';
import '../services/app_state.dart';
import '../services/content_repository.dart';
import '../services/notification_service.dart';
import '../widgets/share_helper.dart';
import 'history_screen.dart';
import 'onboarding_screen.dart';
import 'store_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Diálogo para definir a marca/assinatura personalizada (premium).
  Future<void> _editSignature(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marca personalizada'),
        content: TextField(
          controller: controller,
          maxLength: 24,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Seu nome ou @usuario',
            helperText: 'Aparece no rodapé das imagens que você criar.',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (result != null && context.mounted) {
      context.read<AppState>().setCustomSignature(result);
    }
  }

  /// Reagenda as notificações conforme as preferências atuais.
  Future<void> _reschedule(AppState state) async {
    await NotificationService.instance.scheduleDaily(
      hour: state.notifHour,
      minute: state.notifMinute,
      evening: state.eveningEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final content = context.watch<ContentRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionTitle('Premium'),
          ListTile(
            leading: Icon(Icons.workspace_premium_rounded,
                color: state.isPremium ? const Color(0xFFD9A406) : null),
            title: Text(state.isPremium ? 'Você é Premium 👑' : 'Loja Premium'),
            subtitle: Text(state.isPremium
                ? 'Obrigado pelo apoio! Escolha seus temas.'
                : 'Remover anúncios e desbloquear temas'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StoreScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline_rounded,
                color: Color(0xFF0EA5E9)),
            title: const Text('Marca personalizada'),
            subtitle: Text(state.canCustomSignature
                ? (state.customSignature.isEmpty
                    ? 'Toque para definir seu nome/@'
                    : 'Assinatura: ${state.customSignature}')
                : 'Premium: use seu nome/@ nas imagens'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              if (state.canCustomSignature) {
                _editSignature(context, state.customSignature);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StoreScreen()),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: const Text('Compartilhar o app'),
            subtitle: const Text('Convide amigos e ajude o app a crescer 💜'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => ShareHelper.shareText(
              'Baixe o Frases & Status: frases e mensagens prontas pra '
              'compartilhar! 💜\n'
              'https://play.google.com/store/apps/details?id=com.frasesstatus.frases_status',
            ),
          ),
          const Divider(),
          _SectionTitle('Conteúdo'),
          ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: const Text('Frases disponíveis'),
            trailing: Text('${content.totalPhrases}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          ListTile(
            leading: content.isUpdating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.cloud_download_rounded),
            title: const Text('Atualizar frases agora'),
            subtitle: const Text('Busca novas frases publicadas online'),
            onTap: content.isUpdating
                ? null
                : () async {
                    await content.syncFromRemote();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Conteúdo atualizado: ${content.totalPhrases} frases.')),
                      );
                    }
                  },
          ),
          ListTile(
            leading: const Icon(Icons.interests_rounded),
            title: const Text('Meus temas favoritos'),
            subtitle: Text(state.hasInterests
                ? '${state.interests.length} temas na sua tela inicial'
                : 'Personalize a sua tela inicial'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('Vistas recentes'),
            subtitle: const Text('Reencontre frases que você já viu'),
            trailing: state.hasHistory
                ? Text('${state.history.length}',
                    style: const TextStyle(fontWeight: FontWeight.w800))
                : null,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          const Divider(),
          _SectionTitle('Sua ofensiva 🔥'),
          ListTile(
            leading: const Icon(Icons.local_fire_department_rounded,
                color: AppTheme.brandRed),
            title: const Text('Sequência atual'),
            trailing: Text('${state.streak} dias',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_rounded),
            title: const Text('Melhor sequência'),
            trailing: Text('${state.bestStreak} dias',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          ListTile(
            leading: const Icon(Icons.visibility_rounded),
            title: const Text('Frases vistas'),
            trailing: Text('${state.seenCount}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          ListTile(
            leading: const Icon(Icons.send_rounded),
            title: const Text('Frases compartilhadas'),
            trailing: Text('${state.sharedCount}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const Divider(),
          _SectionTitle('Aparência'),
          RadioGroup<ThemeMode>(
            groupValue: state.themeMode,
            onChanged: (v) {
              if (v != null) context.read<AppState>().setThemeMode(v);
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                    value: ThemeMode.dark, title: Text('Escuro')),
                RadioListTile<ThemeMode>(
                    value: ThemeMode.light, title: Text('Claro')),
                RadioListTile<ThemeMode>(
                    value: ThemeMode.system, title: Text('Padrão do sistema')),
              ],
            ),
          ),
          const Divider(),
          _SectionTitle('Notificações'),
          SwitchListTile(
            value: state.notificationsEnabled,
            title: const Text('Frase do dia'),
            subtitle: Text(
                'Receba uma frase nova todo dia às ${state.notifTimeLabel}'),
            onChanged: (v) async {
              context.read<AppState>().setNotificationsEnabled(v);
              if (v) {
                await NotificationService.instance.requestPermissions();
                await _reschedule(state);
              } else {
                await NotificationService.instance.cancelAll();
              }
            },
          ),
          if (state.notificationsEnabled) ...[
            ListTile(
              leading: const Icon(Icons.schedule_rounded),
              title: const Text('Horário da frase do dia'),
              trailing: Text(state.notifTimeLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime:
                      TimeOfDay(hour: state.notifHour, minute: state.notifMinute),
                );
                if (picked != null && context.mounted) {
                  final appState = context.read<AppState>();
                  appState.setNotificationTime(picked.hour, picked.minute);
                  await _reschedule(appState);
                }
              },
            ),
            SwitchListTile(
              value: state.eveningEnabled,
              secondary: const Icon(Icons.nightlight_round),
              title: const Text('Frase da noite'),
              subtitle: const Text('Uma segunda frase às 20h'),
              onChanged: (v) async {
                context.read<AppState>().setEveningEnabled(v);
                await _reschedule(context.read<AppState>());
              },
            ),
          ],
          const Divider(),
          _SectionTitle('Sobre'),
          ListTile(
            leading: const Icon(Icons.star_rounded, color: AppTheme.brandRed),
            title: const Text('Avaliar na Play Store'),
            onTap: () => launchUrl(
              Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.frasesstatus.frases_status'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('Compartilhar o app'),
            onTap: () => launchUrl(Uri.parse('https://play.google.com/store')),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Versão'),
            trailing: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          )),
    );
  }
}
