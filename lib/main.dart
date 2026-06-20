import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_theme.dart';
import 'services/ads_service.dart';
import 'services/app_state.dart';
import 'services/content_repository.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Inicializa serviços que não bloqueiam a primeira tela.
  AdsService.instance.init();
  final notifEnabled = prefs.getBool('notif_enabled') ?? true;
  final notifHour = prefs.getInt('notif_hour') ?? 9;
  final notifMinute = prefs.getInt('notif_minute') ?? 0;
  final eveningEnabled = prefs.getBool('notif_evening') ?? false;
  NotificationService.instance.init().then((_) {
    if (notifEnabled) {
      NotificationService.instance.scheduleDaily(
        hour: notifHour,
        minute: notifMinute,
        evening: eveningEnabled,
      );
    }
  });

  final content = ContentRepository(prefs);
  // Busca conteúdo novo em segundo plano (não trava a abertura).
  content.syncFromRemote();

  final appState = AppState(prefs);
  AdsService.instance.adsRemoved = appState.isPremium;
  // Loja: ao concluir/recuperar uma compra, libera o item e atualiza anúncios.
  PurchaseService.instance
    ..onEntitlement((id) {
      appState.grantEntitlement(id);
      AdsService.instance.adsRemoved = appState.isPremium;
    })
    ..onSubscriptionGranted((id) {
      appState.addSubscription(id);
      AdsService.instance.adsRemoved = appState.isPremium;
    })
    ..onSubscriptionsReconciled((ids) {
      appState.setActiveSubscriptions(ids);
      AdsService.instance.adsRemoved = appState.isPremium;
    })
    ..init();

  runApp(FrasesApp(prefs: prefs, content: content, appState: appState));
}

class FrasesApp extends StatelessWidget {
  const FrasesApp({
    super.key,
    required this.prefs,
    required this.content,
    required this.appState,
  });

  final SharedPreferences prefs;
  final ContentRepository content;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: content),
      ],
      child: Consumer<AppState>(
        builder: (context, state, _) => MaterialApp(
          title: 'Frases & Status',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(accent: state.accentColor),
          darkTheme: AppTheme.dark(accent: state.accentColor),
          themeMode: state.themeMode,
          home: const _RootGate(),
        ),
      ),
    );
  }
}

/// Mostra a splash animada por um instante e então entra no app (onboarding na
/// primeira vez, ou a tela inicial), com transição suave.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> with WidgetsBindingObserver {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ao voltar pro app (de segundo plano), mostra o anúncio de abertura
    // — com os limites de frequência definidos no AdsService.
    if (state == AppLifecycleState.resumed && _ready) {
      AdsService.instance.maybeShowAppOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final Widget child = !_ready
        ? const SplashScreen()
        : (state.onboardingComplete
            ? const HomeShell()
            : const OnboardingScreen());
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: child,
    );
  }
}
