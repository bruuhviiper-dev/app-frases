import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frases_status/services/app_state.dart';

int _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day)
      .difference(DateTime(2020))
      .inDays;
}

Future<AppState> _stateWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  return AppState(prefs);
}

void main() {
  test('Sem ofensiva relevante, não há marco para comemorar', () async {
    final state = await _stateWith({
      'streak_count': 1,
      'last_open_day': _today(),
      'celebrated_streak': 0,
    });
    expect(state.milestoneToCelebrate, isNull);
  });

  test('Ao bater 7 dias, comemora o marco 7 (uma única vez)', () async {
    final state = await _stateWith({
      'streak_count': 7,
      'last_open_day': _today(),
      'celebrated_streak': 0,
    });
    expect(state.milestoneToCelebrate, 7);

    state.markStreakCelebrated();
    expect(state.milestoneToCelebrate, isNull);
  });

  test('Marco já comemorado não repete; só o próximo dispara', () async {
    final state = await _stateWith({
      'streak_count': 5,
      'last_open_day': _today(),
      'celebrated_streak': 3, // já viu o marco de 3
    });
    expect(state.milestoneToCelebrate, isNull);
  });

  test('Onboarding e interesses persistem', () async {
    final state = await _stateWith({});
    expect(state.onboardingComplete, isFalse);
    state.setInterests(['amor', 'fe', 'humor']);
    state.completeOnboarding();
    expect(state.onboardingComplete, isTrue);
    expect(state.isInterest('amor'), isTrue);
    expect(state.hasInterests, isTrue);
  });
}
