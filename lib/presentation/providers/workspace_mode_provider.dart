import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinu/data/services/workspace_mode_service.dart';

// Provider for SettingsService
final wmsProvider = Provider<WorkspaceModeService>((ref) {
  return WorkspaceModeService();
});

// State Notifier for managing app settings
class AppWmsNotifier extends StateNotifier<AppWms> {
  final WorkspaceModeService _wms;

  AppWmsNotifier(this._wms) : super(AppWms()) {
    _loadInitialSettings();
  }

  Future<void> _loadInitialSettings() async {
    // Load initial settings from SharedPreferences
    final isVoiceModeEnabled = await _wms.getBoolValue('isVoiceModeEnabled') ?? false;
    final isWebSearchModeEnabled = await _wms.getBoolValue('isWebSearchModeEnabled') ?? false;
    final selectedScript = await _wms.getStringValue('selectedScript') ?? '';
    final isContentIncludeVoiceMode = await _wms.getBoolValue('isContentIncludeVoiceMode') ?? false;
    final isContentIncludeImageMode = await _wms.getBoolValue('isContentIncludeImageMode') ?? false;

    state = state.copyWith(
      isVoiceModeEnabled: isVoiceModeEnabled,
      isWebSearchModeEnabled: isWebSearchModeEnabled,
      selectedScript: selectedScript,
      isContentIncludeVoiceMode : isContentIncludeVoiceMode,
      isContentIncludeImageMode : isContentIncludeImageMode,
    );
  }

  // Toggle Voice Mode
  Future<void> toggleVoiceMode(bool value) async {
    await _wms.saveBoolValue('isVoiceModeEnabled', value);
    state = state.copyWith(isVoiceModeEnabled: value);
  }

  // Toggle Web Search Mode
  Future<void> toggleWebSearchMode(bool value) async {
    await _wms.saveBoolValue('isWebSearchModeEnabled', value);
    state = state.copyWith(isWebSearchModeEnabled: value);
  }

  // Set Selected Script
  Future<void> setSelectedScript(String script) async {
    await _wms.saveStringValue('selectedScript', script);
    state = state.copyWith(selectedScript: script);
  }

  Future<void> toggleContentIncludeVoiceMode(bool value) async {
    await _wms.saveBoolValue('isContentIncludeVoiceMode', value);
    state = state.copyWith(isContentIncludeVoiceMode: value);
  }

  Future<void> toggleContentIncludeImageeMode(bool value) async {
    await _wms.saveBoolValue('isContentIncludeImageMode', value);
    state = state.copyWith(isContentIncludeImageMode: value);
  }
}

// App Settings Model
class AppWms {
  final bool isVoiceModeEnabled;
  final bool isWebSearchModeEnabled;
  final String selectedScript;
  final bool isContentIncludeVoiceMode;
  final bool isContentIncludeImageMode;

  AppWms({
    this.isVoiceModeEnabled = false,
    this.isWebSearchModeEnabled = false,
    this.selectedScript = '',
    this.isContentIncludeVoiceMode = false,
    this.isContentIncludeImageMode = false,
  });

  AppWms copyWith({
    bool? isVoiceModeEnabled,
    bool? isWebSearchModeEnabled,
    String? selectedScript,
    bool? isContentIncludeVoiceMode,
    bool? isContentIncludeImageMode,
  }) {
    return AppWms(
      isVoiceModeEnabled: isVoiceModeEnabled ?? this.isVoiceModeEnabled,
      isWebSearchModeEnabled: isWebSearchModeEnabled ?? this.isWebSearchModeEnabled,
      selectedScript: selectedScript ?? this.selectedScript,
      isContentIncludeVoiceMode : isContentIncludeVoiceMode ?? this.isContentIncludeVoiceMode,
      isContentIncludeImageMode: isContentIncludeImageMode ?? this.isContentIncludeImageMode,
    );
  }
}

// Provider for AppSettingsNotifier
final appwmsProvider = StateNotifierProvider<AppWmsNotifier, AppWms>((ref) {
  final wms = ref.watch(wmsProvider);
  return AppWmsNotifier(wms);
});