import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:system_theme/system_theme.dart';

part 'theme.g.dart';
part 'theme.freezed.dart';

enum NavigationIndicators { sticky, end }

AccentColor get systemAccentColor {
  if (defaultTargetPlatform.supportsAccentColor) {
    return AccentColor.swatch({
      'darkest': SystemTheme.accentColor.darkest,
      'darker': SystemTheme.accentColor.darker,
      'dark': SystemTheme.accentColor.dark,
      'normal': SystemTheme.accentColor.accent,
      'light': SystemTheme.accentColor.light,
      'lighter': SystemTheme.accentColor.lighter,
      'lightest': SystemTheme.accentColor.lightest,
    });
  }
  return Colors.blue;
}

@freezed
abstract class AppThemeData with _$AppThemeData {
  const factory AppThemeData({
    required AccentColor color,
    @Default(ThemeMode.system) ThemeMode mode,
    @Default(PaneDisplayMode.auto) PaneDisplayMode displayMode,
    @Default(NavigationIndicators.sticky) NavigationIndicators indicator,
    @Default(WindowEffect.disabled) WindowEffect windowEffect,
    @Default(TextDirection.ltr) TextDirection textDirection,
    Locale? locale,
    @Default(VisualDensity.standard) VisualDensity visualDensity,
  }) = _AppThemeData;

  factory AppThemeData.withDefault() {
    return AppThemeData(color: systemAccentColor);
  }
}

@riverpod
class AppTheme extends _$AppTheme {
  @override
  AppThemeData build() {
    return AppThemeData.withDefault();
  }

  void update(AppThemeData Function(AppThemeData currentState) callback) {
    state = callback(state);
  }

  // ignore: riverpod_lint/avoid_build_context_in_providers
  void setEffect(final WindowEffect effect, final BuildContext context) {
    final theme = FluentTheme.of(context);
    Window.setEffect(
      effect: effect,
      color: [WindowEffect.solid, WindowEffect.acrylic].contains(effect)
          ? theme.micaBackgroundColor.withValues(alpha: 0.05)
          : Colors.transparent,
      dark: theme.brightness == .dark,
    );
  }

  // ignore: riverpod_lint/avoid_build_context_in_providers
  FluentThemeData getTheme(bool isDark, final BuildContext context) =>
      FluentThemeData(
        brightness: isDark ? .dark : .light,
        accentColor: state.color,
        visualDensity: state.visualDensity,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
        fontFamily: kIsWeb ? 'Segoe UI' : null,
      );
}
