import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final String language;
  final bool notificationsEnabled;
  final double fontSize;
  final String aiModel;
  final double temperature;
  final int maxTokens;
  final bool streamingEnabled;
  final Map<String, dynamic> customSettings;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = 'en',
    this.notificationsEnabled = true,
    this.fontSize = 14.0,
    this.aiModel = 'gpt-3.5-turbo',
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.streamingEnabled = true,
    this.customSettings = const {},
  });

  AppSettings copyWith({
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
    return AppSettings(
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

  @override
  List<Object?> get props => [
        themeMode,
        language,
        notificationsEnabled,
        fontSize,
        aiModel,
        temperature,
        maxTokens,
        streamingEnabled,
        customSettings,
      ];
}