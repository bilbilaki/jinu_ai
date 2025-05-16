// lib/core/constants.dart

// History Service Keys
const String prefsHistoryIndexKey = 'chat_history_index_v3'; // Use distinct keys
const String prefsHistoryPrefix = 'chat_history_session_v3_';
const String prefsActiveChatIdKey = 'chat_history_active_id_v3';

// Memory Service Key
const String prefsLtmKey = 'long_term_memory_v3';

// Settings Service Keys (Mainly using variable names directly now)
const String prefsSettingsKey = 'app_settings_v3'; // General settings key if needed

// Gemini Parameter Keys (Matching consts in SettingsService if used directly)
const String geminiTemperatureKey = 'gemini_temperature';
const String geminiTopKKey = 'gemini_top_k';
const String geminiTopPKey = 'gemini_top_p';
const String geminiMaxTokensKey = 'gemini_max_output_tokens';
const String geminiSystemInstructionKey = 'gemini_system_instruction';
const String geminiMessageBufferSizeKey = 'gemini_message_buffer_size';
const String appThemeModeKey = 'app_theme_mode';

// Custom Base URL Key (Matching const in SettingsService if used directly)
const String settingsCustomBaseUrlKey = 'setapisdkbaseurl';