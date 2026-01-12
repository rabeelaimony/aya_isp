import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple cubit to control theme mode across the app with persistence.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light) {
    _loadTheme();
  }

  static const _prefsKey = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == 'dark') {
      emit(ThemeMode.dark);
    } else if (stored == 'light') {
      emit(ThemeMode.light);
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> toggle() => setTheme(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}
