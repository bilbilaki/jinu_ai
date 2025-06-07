import 'package:flutter/material.dart';
import '../../domain/entities/app_settings.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    super.themeMode,
    super.language,
    super.notificationsEnabled,
    super.fontSize,
    super.aiModel,
    super.temperature,
    super.maxTokens,
    super.streamingEnabled,
    super.customSettings,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      themeMode: _parseThemeMode(json['themeMode'] as String?),
      language: json['language'] as String? ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      aiModel: json['aiModel'] as String? ?? 'gpt-3.5-turbo',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 4096,
      streamingEnabled: json['streamingEnabled'] as bool? ?? true,
      customSettings: json['customSettings'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.toString().split('.').last,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'fontSize': fontSize,
      'aiModel': aiModel,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'streamingEnabled': streamingEnabled,
      'customSettings': customSettings,
    };
  }

  static ThemeMode _parseThemeMode(String? themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  factory AppSettingsModel.fromEntity(AppSettings settings) {
    return AppSettingsModel(
      themeMode: settings.themeMode,
      language: settings.language,
      notificationsEnabled: settings.notificationsEnabled,
      fontSize: settings.fontSize,
      aiModel: settings.aiModel,
      temperature: settings.temperature,
      maxTokens: settings.maxTokens,
      streamingEnabled: settings.streamingEnabled,
      customSettings: settings.customSettings,
    );
  }

  AppSettingsModel copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? notificationsEnabled,
    double? fontSize,
    String? aiModel,
    double? temperature,
    int? maxTokens,
    bool? streamingEnabled,
    Map<String, dynamic>? customSettings,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      fontSize: fontSize ?? this.fontSize,
      aiModel: aiModel ?? this.aiModel,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      streamingEnabled: streamingEnabled ?? this.streamingEnabled,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}