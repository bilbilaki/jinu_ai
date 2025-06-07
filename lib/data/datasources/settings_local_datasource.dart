import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings_model.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettingsModel> getSettings();
  Future<void> saveSettings(AppSettingsModel settings);
  Future<void> clearSettings();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String settingsKey = 'app_settings';

  SettingsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<AppSettingsModel> getSettings() async {
    final jsonString = sharedPreferences.getString(settingsKey);
    if (jsonString != null) {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettingsModel.fromJson(json);
    }
    return const AppSettingsModel();
  }

  @override
  Future<void> saveSettings(AppSettingsModel settings) async {
    final jsonString = jsonEncode(settings.toJson());
    await sharedPreferences.setString(settingsKey, jsonString);
  }

  @override
  Future<void> clearSettings() async {
    await sharedPreferences.remove(settingsKey);
  }
}