import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/app_settings.dart';
import '../../../domain/usecases/settings/get_settings.dart';
import '../../../domain/usecases/settings/update_settings.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final GetSettings getSettings;
  final UpdateSettings updateSettings;

  ThemeCubit({
    required this.getSettings,
    required this.updateSettings,
  }) : super(const ThemeState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final result = await getSettings();
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (settings) => emit(state.copyWith(
        themeMode: settings.themeMode,
        settings: settings,
      )),
    );
  }

  Future<void> changeTheme(ThemeMode themeMode) async {
    final updatedSettings = state.settings.copyWith(themeMode: themeMode);
    
    emit(state.copyWith(themeMode: themeMode, settings: updatedSettings));
    
    final result = await updateSettings(updatedSettings);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => {},
    );
  }

  Future<void> updateAppSettings(AppSettings settings) async {
    emit(state.copyWith(settings: settings, themeMode: settings.themeMode));
    
    final result = await updateSettings(settings);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => {},
    );
  }
}