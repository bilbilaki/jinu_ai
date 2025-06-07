part of 'theme_cubit.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final AppSettings settings;
  final String? error;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.settings = const AppSettings(),
    this.error,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    AppSettings? settings,
    String? error,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      settings: settings ?? this.settings,
      error: error,
    );
  }

  @override
  List<Object?> get props => [themeMode, settings, error];
}