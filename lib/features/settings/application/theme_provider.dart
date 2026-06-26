import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true; // true for Dark mode, false for Light
  }

  void toggleTheme(bool isDark) {
    state = isDark;
  }
}
