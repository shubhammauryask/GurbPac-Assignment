import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;

  ThemeModeNotifier(this._ref) : super(ThemeMode.dark) {
    final local = _ref.watch(localStorageProvider);
    final savedMode = local.getThemeMode();
    state = savedMode == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  void toggleTheme() {
    final local = _ref.read(localStorageProvider);
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      local.setThemeMode('light');
    } else {
      state = ThemeMode.dark;
      local.setThemeMode('dark');
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});
