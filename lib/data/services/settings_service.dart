// lib/data/services/settings_service.dart
import 'dart:convert';
import 'package:flutter/material.dart'; // For ChangeNotifier
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// Import constants if used internally (though your code mainly uses var names as keys)
import '../../core/constants.dart'; // If keys like geminiTemperatureKey are used

// Default System Instruction (keep as before)
const _defaultSystemInstruction = /* ... Your long default instruction ... */
    '''
You are advanced AI agent Assistant for USER ''';

class SettingsService with ChangeNotifier {
  SharedPreferences? _prefs;
  // --- Default Values ---
  double _temperature = 1.0;
  double _topK = 40;
  double _topP = 0.95;
  int _maxOutputTokens = 8192;
  String _systemInstruction = _defaultSystemInstruction;
  int _messageBufferSize = 7;
  ThemeMode _themeMode = ThemeMode.system;

  // Instance variables with default values
  String _custoombaseurl = '';
  String _setdefaultvoice = 'shimmer';
  String _defaultchatmodel = 'gpt-4.1-nano';
  String _apitokenmain = '';
  String _apitokensub = '';
  String _setapisdkmodel = ''; // Seemingly unused based on provided code?
  String _setapisdkbaseurl = '';
  String _usagemode = 'normal';
  bool _turnofftools = false;
  Map<String, dynamic> _getmodels = {}; // Holds raw response from getModels()
  List<String> _availableModels = []; // Holds just the IDs from getModels()
  String _textprocessingmodel = 'gpt-4.1-nano';
  String _voiceprocessingmodel = 'tts-1';
  String _visionprocessingmodel = 'gpt-4.1-nano';
  bool _autotitle = true; // Default from original
  String _autotitlemodel = ''; // Needs a default? e.g., 'gpt-3.5-turbo-0125'
  bool _historyformodelsenabled = true;
  int _historybufferlength = 5;
  bool _historychatenabled = true;
  String _customsearchlocation = 'GB';
  String _imagegenerationmodel = 'dall-e-3';
  String _imagegenerationquality = 'standard';
  String _imagegenerationsize = '1024x1024';
  String _imageanalysismodeldetails = 'gpt-4.1-mini';
  String _credits = '';
  Map<String, String>? _customoutputstyle = {'text': 'text'};
  String _promptsbookmark = '';
  String _customapiname = '';
  String _customapitoken = '';
  String _customapiurl = '';
  String _customapikey = '';
  String _customapiparam = '';
  String _customapiparamvalue = '';
  String _customapiheaders = '';
  String _customapitype = 'GET';
  bool _devmod = false;

  // --- Getters ---
  double get temperature => _temperature;
  double get topK => _topK;
  double get topP => _topP;
  int get maxOutputTokens => _maxOutputTokens;
  String get systemInstruction => _systemInstruction;
  int get messageBufferSize => _messageBufferSize;
  ThemeMode get themeMode => _themeMode;
  String get custoombaseurl => _custoombaseurl;
  String get setdefaultvoice => _setdefaultvoice;
  String get defaultchatmodel => _defaultchatmodel;
  String get apitokenmain => _apitokenmain;
  String get apitokensub => _apitokensub;
  String get setapisdkmodel => _setapisdkmodel;
  String get setapisdkbaseurl => _setapisdkbaseurl;
  String get usagemode => _usagemode;
  bool get turnofftools => _turnofftools;
  @Deprecated(
    'Use availableModels getter for IDs or getModelDetails for full data',
  )
  Map<String, dynamic> get getmodels => _getmodels; // Keep for compatibility? Or remove.
  List<String> get availableModels => _availableModels; // Use this getter
  String get textprocessingmodel => _textprocessingmodel;
  String get voiceprocessingmodel => _voiceprocessingmodel;
  String get visionprocessingmodel => _visionprocessingmodel;
  bool get autotitle => _autotitle;
  String get autotitlemodel => _autotitlemodel;
  bool get historyformodelsenabled => _historyformodelsenabled;
  int get historybufferlength => _historybufferlength;
  bool get historychatenabled => _historychatenabled;
  String get customsearchlocation => _customsearchlocation;
  String get imagegenerationmodel => _imagegenerationmodel;
  String get imagegenerationquality => _imagegenerationquality;
  String get imagegenerationsize => _imagegenerationsize;
  String get imageanalysismodeldetails => _imageanalysismodeldetails;
  String get credits => _credits;
  Map<String, String>? get customoutputstyle => _customoutputstyle;
  String get promptsbookmark => _promptsbookmark;
  String get customapiname => _customapiname;
  String get customapitoken => _customapitoken;
  String get customapiurl => _customapiurl;
  String get customapikey => _customapikey;
  String get customapiparam => _customapiparam;
  String get customapiparamvalue => _customapiparamvalue;
  String get customapiheaders => _customapiheaders;
  String get customapitype => _customapitype;
  bool get devmod => _devmod;

  SettingsService() {
    _init();
  }

  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await loadSettings();
  }

  Future<void> loadSettings() async {
    _prefs ??= await SharedPreferences.getInstance();

    // Load basic generation parameters (previously combined in 'settings')
    _temperature = _prefs!.getDouble(geminiTemperatureKey) ?? _temperature;
    _topK = _prefs!.getDouble(geminiTopKKey) ?? _topK;
    _topP = _prefs!.getDouble(geminiTopPKey) ?? _topP;
    _maxOutputTokens = _prefs!.getInt(geminiMaxTokensKey) ?? _maxOutputTokens;
    _systemInstruction =
        _prefs!.getString(geminiSystemInstructionKey) ?? _systemInstruction;
    _messageBufferSize =
        _prefs!.getInt(geminiMessageBufferSizeKey) ?? _messageBufferSize;

    // Load theme mode
    final themeString = _prefs!.getString(appThemeModeKey);
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeString,
        orElse: () => ThemeMode.system,
      );
    } else {
      _themeMode = ThemeMode.system;
    }

    // Load other individual settings using variable names as keys (as per original code)
    _custoombaseurl = _prefs!.getString('custoombaseurl') ?? '';
    _defaultchatmodel = _prefs!.getString('defaultchatmodel') ?? 'gpt-4.1-nano';
    _apitokenmain = _prefs!.getString('apitokenmain') ?? '';
    _apitokensub = _prefs!.getString('apitokensub') ?? '';
    _setapisdkmodel = _prefs!.getString('setapisdkmodel') ?? '';
    _setapisdkbaseurl =
        _prefs!.getString(settingsCustomBaseUrlKey) ??
        ''; // Use const for this specific key
    _usagemode = _prefs!.getString('usagemode') ?? 'normal';
    _turnofftools =
        _prefs!.getBool('turnofftools') ?? false; // Use string key for bool

    // Load models fetched previously (both raw data and just IDs)
    _getmodels =
        (_prefs!.getString('modelsData') != null)
            ? json.decode(_prefs!.getString('modelsData')!)
                as Map<String, dynamic>
            : {};
    _availableModels =
        (_prefs!.getString('availableModels') != null)
            ? List<String>.from(
              json.decode(_prefs!.getString('availableModels')!),
            )
            : [];

    _textprocessingmodel =
        _prefs!.getString('textprocessingmodel') ?? 'gpt-4.1-nano';
    _voiceprocessingmodel =
        _prefs!.getString('voiceprocessingmodel') ?? 'tts-1';
    _setdefaultvoice = _prefs!.getString('setdefaultvoice') ?? 'shimmer';
    _visionprocessingmodel =
        _prefs!.getString('visionprocessingmodel') ?? 'gpt-4.1-nano';
    _autotitle =
        _prefs!.getBool('autotitle') ?? true; // Use string key for bool
    _autotitlemodel = _prefs!.getString('autotitlemodel') ?? ''; // Add default?
    _historyformodelsenabled =
        _prefs!.getBool('historyformodelsenabled') ??
        true; // Use string key for bool
    _historybufferlength =
        _prefs!.getInt('historybufferlength') ?? 5; // Use string key for int
    _historychatenabled =
        _prefs!.getBool('historychatenabled') ??
        true; // Use string key for bool
    _customsearchlocation = _prefs!.getString('customsearchlocation') ?? 'GB';
    _imagegenerationmodel =
        _prefs!.getString('imagegenerationmodel') ?? 'dall-e-3';
    _imagegenerationquality =
        _prefs!.getString('imagegenerationquality') ?? 'standard';
    _imagegenerationsize =
        _prefs!.getString('imagegenerationsize') ?? '1024x1024';
    _imageanalysismodeldetails =
        _prefs!.getString('imageanalysismodeldetails') ?? 'gpt-4.1-mini';
    _credits = _prefs!.getString('credits') ?? '';
    _promptsbookmark = _prefs!.getString('promptsbookmark') ?? '';
    _customapiname = _prefs!.getString('customapiname') ?? '';
    _customapitoken = _prefs!.getString('customapitoken') ?? '';
    _customapiurl = _prefs!.getString('customapiurl') ?? '';
    _customapikey = _prefs!.getString('customapikey') ?? '';
    _customapiparam = _prefs!.getString('customapiparam') ?? '';
    _customapiparamvalue = _prefs!.getString('customapiparamvalue') ?? '';
    _customapiheaders = _prefs!.getString('customapiheaders') ?? '';
    _customapitype = _prefs!.getString('customapitype') ?? 'GET';
    _devmod = _prefs!.getBool('devmod') ?? false; // Use string key for bool

    notifyListeners();
  }

  // --- Setters (Save on change) ---

  Future<void> getModels() async {
    if (custoombaseurl.isEmpty || apitokenmain.isEmpty) {
      debugPrint(
        "Cannot fetch models: Custom Base URL or Main API Token is missing.",
      );
      _availableModels = [];
      _getmodels = {'error': 'URL or Token missing'};
      await _prefs?.remove('availableModels');
      await _prefs?.remove('modelsData');
      notifyListeners();
      return; // Exit early
    }
    if (!Uri.tryParse(custoombaseurl)!.hasAbsolutePath ?? true) {
      debugPrint("Cannot fetch models: Invalid Base URL format.");
      _availableModels = [];
      _getmodels = {'error': 'Invalid Base URL format'};
      await _prefs?.remove('availableModels');
      await _prefs?.remove('modelsData');
      notifyListeners();
      return;
    }

    // Ensure the URL ends with /models if not already present
    String fetchUrl =
        custoombaseurl.endsWith('/models')
            ? custoombaseurl
            : (custoombaseurl.endsWith('/')
                ? '${custoombaseurl}models'
                : '$custoombaseurl/models');

    debugPrint("Fetching models from: $fetchUrl");

    try {
      http.Response response = await http.get(
        Uri.parse(fetchUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apitokenmain',
        },
      );

      debugPrint("Get Models Status Code: ${response.statusCode}");
      // debugPrint("Get Models Response Body: ${response.body}"); // Careful logging potentially large/sensitive data

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(
          utf8.decode(response.bodyBytes),
        ); // Handle encoding

        // Extract the list of models from the "data" field
        List<dynamic> modelsList = responseData['data'] ?? [];

        // Create a list of model IDs
        _availableModels =
            modelsList
                .map<String?>(
                  (model) => model is Map ? model['id']?.toString() : null,
                )
                .where((id) => id != null) // Filter out null IDs
                .cast<String>() // Cast to non-nullable list
                .toList();
        _availableModels.sort(); // Sort for display

        // Store the full models data (optional, could be large)
        _getmodels = responseData;
        await _prefs?.setString(
          'modelsData',
          json.encode(_getmodels),
        ); // Encode before saving

        String availableModelsJson = json.encode(_availableModels);
        await _prefs?.setString('availableModels', availableModelsJson);
      } else {
        debugPrint(
          "Error fetching models: Status code ${response.statusCode}, Body: ${response.body}",
        );
        _getmodels = {
          'error': 'Status code ${response.statusCode}',
          'body': response.body,
        };
        _availableModels = [];
        await _prefs?.remove('availableModels');
        await _prefs?.remove(
          'modelsData',
        ); // Optionally clear old data on error
      }

      notifyListeners();
    } catch (e, s) {
      print('Error fetching models: $e\nStack: $s');
      _getmodels = {'error': e.toString()};
      _availableModels = [];
      await _prefs?.remove('availableModels');
      await _prefs?.remove('modelsData');
      notifyListeners();
    }
  }

  // If you need to get a specific model's details from the custom fetch
  Map<String, dynamic>? getModelDetails(String modelId) {
    if (_getmodels['data'] is List) {
      List<dynamic> models = _getmodels['data'];
      for (var model in models) {
        if (model is Map && model['id'] == modelId) {
          return Map<String, dynamic>.from(
            model,
          ); // Ensure it's the correct type
        }
      }
    }
    return null;
  }

  // Generic String Setter
  Future<void> _setString(
    String key,
    String newValue,
    String currentValue,
  ) async {
    if (currentValue == newValue) return;
    // Update internal state immediately for responsiveness
    switch (key) {
      case 'custoombaseurl':
        _custoombaseurl = newValue;
        break;
      case 'defaultchatmodel':
        _defaultchatmodel = newValue;
        break;
      case 'apitokenmain':
        _apitokenmain = newValue;
        break;
      case 'apitokensub':
        _apitokensub = newValue;
        break;
      case 'setapisdkmodel':
        _setapisdkmodel = newValue;
        break;
      case settingsCustomBaseUrlKey:
        _setapisdkbaseurl = newValue;
        break; // Use const key
      case 'usagemode':
        _usagemode = newValue;
        break;
      case 'textprocessingmodel':
        _textprocessingmodel = newValue;
        break;
      case 'voiceprocessingmodel':
        _voiceprocessingmodel = newValue;
        break;
      case 'setdefaultvoice':
        _setdefaultvoice = newValue;
        break;
      case 'visionprocessingmodel':
        _visionprocessingmodel = newValue;
        break;
      case 'autotitlemodel':
        _autotitlemodel = newValue;
        break;
      case 'customsearchlocation':
        _customsearchlocation = newValue;
        break;
      case 'imagegenerationmodel':
        _imagegenerationmodel = newValue;
        break;
      case 'imagegenerationquality':
        _imagegenerationquality = newValue;
        break;
      case 'imagegenerationsize':
        _imagegenerationsize = newValue;
        break;
      case 'imageanalysismodeldetails':
        _imageanalysismodeldetails = newValue;
        break;
      case 'credits':
        _credits = newValue;
        break;
      case 'customoutputstyle':
        _customoutputstyle = newValue as Map<String, String>?;
        break;
      case 'promptsbookmark':
        _promptsbookmark = newValue;
        break;
      case 'customapiname':
        _customapiname = newValue;
        break;
      case 'customapitoken':
        _customapitoken = newValue;
        break;
      case 'customapiurl':
        _customapiurl = newValue;
        break;
      case 'customapikey':
        _customapikey = newValue;
        break;
      case 'customapiparam':
        _customapiparam = newValue;
        break;
      case 'customapiparamvalue':
        _customapiparamvalue = newValue;
        break;
      case 'customapiheaders':
        _customapiheaders = newValue;
        break;
      case 'customapitype':
        _customapitype = newValue;
        break;
      case geminiSystemInstructionKey:
        _systemInstruction = newValue;
        break; // Use const key
      default:
        debugPrint("Warning: Unhandled key in _setString: $key");
        return;
    }
    notifyListeners(); // Notify UI immediately
    await _prefs?.setString(key, newValue); // Save asynchronously
  }

  // Generic Bool Setter
  Future<void> _setBool(String key, bool newValue, bool currentValue) async {
    if (currentValue == newValue) return;
    switch (key) {
      case 'turnofftools':
        _turnofftools = newValue;
        break;
      case 'autotitle':
        _autotitle = newValue;
        break;
      case 'historyformodelsenabled':
        _historyformodelsenabled = newValue;
        break;
      case 'historychatenabled':
        _historychatenabled = newValue;
        break;
      case 'devmod':
        _devmod = newValue;
        break;
      default:
        debugPrint("Warning: Unhandled key in _setBool: $key");
        return;
    }
    notifyListeners();
    await _prefs?.setBool(
      key,
      newValue,
    ); // Use string key for bools per original load logic
  }

  // Generic Int Setter
  Future<void> _setInt(String key, int newValue, int currentValue) async {
    if (currentValue == newValue) return;
    switch (key) {
      case geminiMaxTokensKey:
        _maxOutputTokens = newValue.clamp(1, 100000);
        break;
      case geminiMessageBufferSizeKey:
        _messageBufferSize = newValue.clamp(0, 50);
        break;
      case 'historybufferlength':
        _historybufferlength = newValue.clamp(0, 50);
        break;
      default:
        debugPrint("Warning: Unhandled key in _setInt: $key");
        return;
    }
    notifyListeners();
    // Use const keys for specific Gemini params
    if (key == geminiTopKKey ||
        key == geminiMaxTokensKey ||
        key == geminiMessageBufferSizeKey) {
      await _prefs?.setInt(key, _getIntValue(key)); // Save clamped value
    } else {
      await _prefs?.setInt(
        key,
        _getIntValue(key),
      ); // Save potentially unclamped value using string key
    }
  }

  // Helper to get current int value after potential clamping
  int _getIntValue(String key) {
    switch (key) {
      case geminiMaxTokensKey:
        return _maxOutputTokens;
      case geminiMessageBufferSizeKey:
        return _messageBufferSize;
      case 'historybufferlength':
        return _historybufferlength;
      default:
        return 0; // Should not happen
    }
  }

  // Generic Double Setter
  Future<void> _setDouble(
    String key,
    double newValue,
    double currentValue,
  ) async {
    if (currentValue == newValue) return;
    switch (key) {
      case geminiTopKKey:
        _topK = newValue.clamp(1, 1000);
        break; // Add validation/clamp

      case geminiTemperatureKey:
        _temperature = newValue.clamp(0.0, 2.0);
        break;
      case geminiTopPKey:
        _topP = newValue.clamp(0.0, 1.0);
        break;
      default:
        debugPrint("Warning: Unhandled key in _setDouble: $key");
        return;
    }
    notifyListeners();
    // Use const keys for specific Gemini params
    await _prefs?.setDouble(
      key,
      _getDoubleValue(key),
    ); // Save potentially clamped value
  }

  // Helper to get current double value after clamping
  double _getDoubleValue(String key) {
    switch (key) {
      case geminiTopKKey:
        return _topK;
      case geminiTemperatureKey:
        return _temperature;
      case geminiTopPKey:
        return _topP;
      default:
        return 0.0; // Should not happen
    }
  }

  // Specific Setters using the generic helpers
  Future<void> setCustoombaseurl(String value) =>
      _setString('custoombaseurl', value, _custoombaseurl);
  Future<void> setDefaultchatmodel(String value) =>
      _setString('defaultchatmodel', value, _defaultchatmodel);
  Future<void> setApitokenmain(String value) =>
      _setString('apitokenmain', value, _apitokenmain);
  Future<void> setApitokensub(String value) =>
      _setString('apitokensub', value, _apitokensub);
  Future<void> setApisdkmodel(String value) =>
      _setString('setapisdkmodel', value, _setapisdkmodel);
  Future<void> setApisdkbaseurl(String value) => _setString(
    settingsCustomBaseUrlKey,
    value,
    _setapisdkbaseurl,
  ); // Use Const Key
  Future<void> setUsagemode(String value) =>
      _setString('usagemode', value, _usagemode);
  Future<void> setTurnofftools(bool value) =>
      _setBool('turnofftools', value, _turnofftools);
  // setGetmodels is not needed, it's populated by getModels()
  Future<void> setTextprocessingmodel(String value) =>
      _setString('textprocessingmodel', value, _textprocessingmodel);
  Future<void> setVoiceprocessingmodel(String value) =>
      _setString('voiceprocessingmodel', value, _voiceprocessingmodel);
  Future<void> setDefaultvoice(String value) =>
      _setString('setdefaultvoice', value, _setdefaultvoice);
  Future<void> setVisionprocessingmodel(String value) =>
      _setString('visionprocessingmodel', value, _visionprocessingmodel);
  Future<void> setAutotitle(bool value) =>
      _setBool('autotitle', value, _autotitle);
  Future<void> setAutotitlemodel(String value) =>
      _setString('autotitlemodel', value, _autotitlemodel);
  Future<void> setHistoryformodelsenabled(bool value) =>
      _setBool('historyformodelsenabled', value, _historyformodelsenabled);
  Future<void> setHistorybufferlength(int value) =>
      _setInt('historybufferlength', value, _historybufferlength);
  Future<void> setHistorychatenabled(bool value) =>
      _setBool('historychatenabled', value, _historychatenabled);
  Future<void> setCustomsearchlocation(String value) =>
      _setString('customsearchlocation', value, _customsearchlocation);
  Future<void> setImagegenerationmodel(String value) =>
      _setString('imagegenerationmodel', value, _imagegenerationmodel);
  Future<void> setImagegenerationquality(String value) =>
      _setString('imagegenerationquality', value, _imagegenerationquality);
  Future<void> setImagegenerationsize(String value) =>
      _setString('imagegenerationsize', value, _imagegenerationsize);
  Future<void> setImageanalysismodeldetails(String value) => _setString(
    'imageanalysismodeldetails',
    value,
    _imageanalysismodeldetails,
  );
  Future<void> setCredits(String value) =>
      _setString('credits', value, _credits);
  Future<void> setPromptsbookmark(String value) =>
      _setString('promptsbookmark', value, _promptsbookmark);
  Future<void> setCustomapiname(String value) =>
      _setString('customapiname', value, _customapiname);
  Future<void> setCustomapitoken(String value) =>
      _setString('customapitoken', value, _customapitoken);
  Future<void> setCustomapiurl(String value) =>
      _setString('customapiurl', value, _customapiurl);
  Future<void> setCustomapikey(String value) =>
      _setString('customapikey', value, _customapikey);
  Future<void> setCustomapiparam(String value) =>
      _setString('customapiparam', value, _customapiparam);
  Future<void> setCustomapiparamvalue(String value) =>
      _setString('customapiparamvalue', value, _customapiparamvalue);
  Future<void> setCustomapiheaders(String value) =>
      _setString('customapiheaders', value, _customapiheaders);
  Future<void> setCustomapitype(String value) =>
      _setString('customapitype', value, _customapitype);
  Future<void> setDevmod(bool value) => _setBool('devmod', value, _devmod);

  // Gemini Params Setters
  Future<void> setTemperature(double value) =>
      _setDouble(geminiTemperatureKey, value, _temperature); // Use Const Key
  Future<void> setTopK(double value) =>
      _setDouble(geminiTopKKey, value, _topK); // Use Const Key
  Future<void> setTopP(double value) =>
      _setDouble(geminiTopPKey, value, _topP); // Use Const Key
  Future<void> setMaxOutputTokens(int value) =>
      _setInt(geminiMaxTokensKey, value, _maxOutputTokens); // Use Const Key
  Future<void> setSystemInstruction(String value) => _setString(
    geminiSystemInstructionKey,
    value,
    _systemInstruction,
  ); // Use Const Key
  Future<void> setMessageBufferSize(int value) => _setInt(
    geminiMessageBufferSizeKey,
    value,
    _messageBufferSize,
  ); // Use Const Key

  // Setter for ThemeMode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners(); // Update UI immediately
    await _prefs?.setString(
      appThemeModeKey,
      mode.toString(),
    ); // Save asynchronously
  }

  // getValue Method (kept from original for potential use)
  dynamic getValue(String key) {
    switch (key) {
      // Gemini Specific
      case 'temperature':
      case geminiTemperatureKey:
        return _temperature;
      case 'topK':
      case geminiTopKKey:
        return _topK;
      case 'topP':
      case geminiTopPKey:
        return _topP;
      case 'maxOutputTokens':
      case geminiMaxTokensKey:
        return _maxOutputTokens;
      case 'systemInstruction':
      case geminiSystemInstructionKey:
        return _systemInstruction;
      case 'messageBufferSize':
      case geminiMessageBufferSizeKey:
        return _messageBufferSize;
      // App Theme
      case 'themeMode':
      case appThemeModeKey:
        return _themeMode;
      // Other Settings (Using variable names mostly)
      case 'custoombaseurl':
        return _custoombaseurl;
      case 'setdefaultvoice':
        return _setdefaultvoice;
      case 'defaultchatmodel':
        return _defaultchatmodel;
      case 'apitokenmain':
        return _apitokenmain;
      case 'apitokensub':
        return _apitokensub;
      case 'setapisdkmodel':
        return _setapisdkmodel;
      case 'setapisdkbaseurl':
      case settingsCustomBaseUrlKey:
        return _setapisdkbaseurl; // Handles both
      case 'usagemode':
        return _usagemode;
      case 'turnofftools':
        return _turnofftools;
      case 'getmodels':
        return _getmodels;
      case 'availableModels':
        return availableModels;
      case 'textprocessingmodel':
        return _textprocessingmodel;
      case 'voiceprocessingmodel':
        return _voiceprocessingmodel;
      case 'visionprocessingmodel':
        return _visionprocessingmodel;
      case 'autotitle':
        return _autotitle;
      case 'autotitlemodel':
        return _autotitlemodel;
      case 'historyformodelsenabled':
        return _historyformodelsenabled;
      case 'historybufferlength':
        return _historybufferlength;
      case 'historychatenabled':
        return _historychatenabled;
      case 'customsearchlocation':
        return _customsearchlocation;
      case 'imagegenerationmodel':
        return _imagegenerationmodel;
      case 'imagegenerationquality':
        return _imagegenerationquality;
      case 'imagegenerationsize':
        return _imagegenerationsize;
      case 'imageanalysismodeldetails':
        return _imageanalysismodeldetails;
      case 'credits':
        return _credits;
      case 'customoutputstyle':
        return _customoutputstyle;
      case 'promptsbookmark':
        return _promptsbookmark;
      case 'customapiname':
        return _customapiname;
      case 'customapitoken':
        return _customapitoken;
      case 'customapiurl':
        return _customapiurl;
      case 'customapikey':
        return _customapikey;
      case 'customapiparam':
        return _customapiparam;
      case 'customapiparamvalue':
        return _customapiparamvalue;
      case 'customapiheaders':
        return _customapiheaders;
      case 'customapitype':
        return _customapitype;
      case 'devmod':
        return _devmod;
      default:
        debugPrint(
          'SettingsService: Unknown setting key requested in getValue: $key',
        );
        return null;
    }
  }

  Future<void> resetToDefaults() async {
    // Reset internal state variables
    _temperature = 1.0;
    _topK = 40;
    _topP = 0.95;
    _maxOutputTokens = 8192;
    _systemInstruction = _defaultSystemInstruction;
    _messageBufferSize = 7;
    _themeMode = ThemeMode.system;
    _custoombaseurl = '';
    _setdefaultvoice = 'shimmer';
    _defaultchatmodel = 'gpt-4.1-nano';
    _apitokenmain = '';
    _apitokensub = '';
    _setapisdkmodel = '';
    _setapisdkbaseurl = '';
    _usagemode = 'normal';
    _turnofftools = false;
    _getmodels = {};
    _availableModels = [];
    _textprocessingmodel = 'gpt-4.1-nano';
    _voiceprocessingmodel = 'tts-1';
    _visionprocessingmodel = 'gpt-4.1-nano';
    _autotitle = true;
    _autotitlemodel = '';
    _historyformodelsenabled = true;
    _historybufferlength = 5;
    _historychatenabled = true;
    _customsearchlocation = 'GB';
    _imagegenerationmodel = 'dall-e-3';
    _imagegenerationquality = 'standard';
    _imagegenerationsize = '1024x1024';
    _imageanalysismodeldetails = 'gpt-4.1-mini';
    _credits = '';
    _customoutputstyle = {'text': 'text'};
    _promptsbookmark = '';
    _customapiname = '';
    _customapitoken = '';
    _customapiurl = '';
    _customapikey = '';
    _customapiparam = '';
    _customapiparamvalue = '';
    _customapiheaders = '';
    _customapitype = 'GET';
    _devmod = false;

    notifyListeners(); // Update UI immediately

    // Remove keys from prefs asynchronously
    await _prefs?.remove(geminiTemperatureKey);
    await _prefs?.remove(geminiTopKKey);
    await _prefs?.remove(geminiTopPKey);
    await _prefs?.remove(geminiMaxTokensKey);
    await _prefs?.remove(geminiSystemInstructionKey);
    await _prefs?.remove(geminiMessageBufferSizeKey);
    await _prefs?.remove(appThemeModeKey);
    await _prefs?.remove('custoombaseurl');
    await _prefs?.remove('defaultchatmodel');
    await _prefs?.remove('apitokenmain');
    await _prefs?.remove('apitokensub');
    await _prefs?.remove('setapisdkmodel');
    await _prefs?.remove(settingsCustomBaseUrlKey);
    await _prefs?.remove('usagemode');
    await _prefs?.remove('turnofftools');
    await _prefs?.remove('modelsData'); // Clear fetched models raw data
    await _prefs?.remove('availableModels'); // Clear fetched model IDs
    await _prefs?.remove('textprocessingmodel');
    await _prefs?.remove('voiceprocessingmodel');
    await _prefs?.remove('setdefaultvoice');
    await _prefs?.remove('visionprocessingmodel');
    await _prefs?.remove('autotitle');
    await _prefs?.remove('autotitlemodel');
    await _prefs?.remove('historyformodelsenabled');
    await _prefs?.remove('historybufferlength');
    await _prefs?.remove('historychatenabled');
    await _prefs?.remove('customsearchlocation');
    await _prefs?.remove('imagegenerationmodel');
    await _prefs?.remove('imagegenerationquality');
    await _prefs?.remove('imagegenerationsize');
    await _prefs?.remove('imageanalysismodeldetails');
    await _prefs?.remove('credits');
    await _prefs?.remove('customoutputstyle');
    await _prefs?.remove('promptsbookmark');
    await _prefs?.remove('customapiname');
    await _prefs?.remove('customapitoken');
    await _prefs?.remove('customapiurl');
    await _prefs?.remove('customapikey');
    await _prefs?.remove('customapiparam');
    await _prefs?.remove('customapiparamvalue');
    await _prefs?.remove('customapiheaders');
    await _prefs?.remove('customapitype');
    await _prefs?.remove('devmod');

    debugPrint("Settings reset to defaults.");
  }
}
