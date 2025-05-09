// lib/presentation/screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinu/data/services/settings_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/view_long_term_memory_dialog.dart';
import 'package:jinu/presentation/providers/models_provider.dart';
// Import other providers/dialogs if needed

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  // Consistent spacing
  static const double _sectionSpacing = 24.0;
  static const double _itemSpacing = 12.0;
  static const EdgeInsets _listPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );
  static const EdgeInsets _tilePadding = EdgeInsets.symmetric(
    vertical: 4.0,
  ); // For list tiles

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsService = ref.watch(
      settingsServiceProvider.notifier,
    ); // Get the Notifier
    final settings = ref.watch(settingsServiceProvider); // Get the State
    // Watch derived state for available models
    final customModels = ref.watch(customAvailableModelsProvider);
    final data = ref.watch(openAIModelIdsProvider);
    data.whenData((models) {
      // Sort models alphabetically
      models.sort();
      return models;
    });
    // Watch the main API token to check if it's set

    // Handle initial loading state

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          // Reload Models Button
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Reload Models from Custom URL',
            // Use settings state for condition, but call method on service/notifier
            onPressed:
                settings.custoombaseurl.isNotEmpty &&
                        settings.apitokenmain.isNotEmpty
                    ? () async {
                      // Show immediate feedback
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Fetching models from ${settings.custoombaseurl}...',
                          ),
                        ),
                      );
                      try {
                        // Call method on the notifier
                        await settingsService.getModels();
                        ScaffoldMessenger.of(
                          context,
                        ).hideCurrentSnackBar(); // Hide loading message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Models reloaded successfully.'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).hideCurrentSnackBar(); // Hide loading message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error reloading models: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                    : null, // Disable if URL or token is missing
          ),
          // Reset Button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Defaults',
            onPressed:
                () => _showResetConfirmationDialog(context, settingsService),
          ),
          // --- NO EXPLICIT SAVE BUTTON ---
          // The design uses instant save via the setters in SettingsService.
          // If you absolutely need one, add an IconButton here and call a hypothetical
          // settingsService.saveAllPendingChanges() method (which you'd need to implement
          // by modifying the setters to not save immediately).
        ],
      ),
      body: ListView(
        padding: _listPadding, // Consistent padding
        children: [
          // --- Theme Settings ---
          _buildSectionTitle(context, 'Appearance'),
          Padding(
            padding: _tilePadding,
            child: RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              subtitle: const Text('Follow device theme setting'),
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged:
                  (value) =>
                      settingsService.setThemeMode(value ?? ThemeMode.system),
            ),
          ),
          Padding(
            padding: _tilePadding,
            child: RadioListTile<ThemeMode>(
              title: const Text('Light Theme'),
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged:
                  (value) =>
                      settingsService.setThemeMode(value ?? ThemeMode.light),
            ),
          ),
          Padding(
            padding: _tilePadding,
            child: RadioListTile<ThemeMode>(
              title: const Text('Dark Theme'),
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged:
                  (value) =>
                      settingsService.setThemeMode(value ?? ThemeMode.dark),
            ),
          ),

          const SizedBox(height: _sectionSpacing),
// Padding(
//             padding: _tilePadding,
//             child: RadioListTile<ThemeMode>(
//               title: const Text('Fantasy Theme'),
//               value: ThemeMode.values[3],
//               groupValue: settings.themeMode,
//               onChanged:
//                   (value) =>
//                       settingsService.setThemeMode(value ?? ThemeMode.values[3]),
//             ),
//           ),
//           const SizedBox(height: _sectionSpacing),

          // --- Generation Parameters ---
          _buildSectionTitle(context, 'Generation Parameters'),
          _buildSliderSetting(
            context,
            label: 'Temperature: ${settings.temperature.toStringAsFixed(2)}',
            value: settings.temperature,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            onChanged: settingsService.setTemperature,
          ),
          const SizedBox(height: _itemSpacing),
          _buildSliderSetting(
            context,
            label: 'Top P: ${settings.topP.toStringAsFixed(2)}',
            value: settings.topP,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: settingsService.setTopP,
          ),
          const SizedBox(height: _itemSpacing),
          _buildIntInputSetting(
            context,
            label: 'Top K:',
            value:
                settings.topK
                    .toInt(), // Assuming TopK is now Double in state but needs Int input
            onChanged:
                (val) => settingsService.setTopK(
                  val.toDouble(),
                ), // Convert back to double
            minValue: 1,
          ),
          const SizedBox(height: _itemSpacing),
          _buildIntInputSetting(
            context,
            label: 'Max Output Tokens:',
            value: settings.maxOutputTokens,
            onChanged: settingsService.setMaxOutputTokens,
            minValue: 1,
            maxValue: 100000,
          ),

          const SizedBox(height: _sectionSpacing),

          // --- System Instruction ---
          _buildSectionTitle(context, 'System Instruction'),
          _buildTextFieldSetting(
            initialValue: settings.systemInstruction,
            // label: 'System Instruction', No label needed if title is above
            hint: 'Enter system instruction for the AI...',
            maxLines: 6,
            minLines: 3,
            saveAction: settingsService.setSystemInstruction,
          ),

          const SizedBox(height: _sectionSpacing),

          // --- API Configuration ---
          _buildSectionTitle(context, 'API Configuration'),
          _buildTextFieldSetting(
            initialValue: settings.custoombaseurl, // Use corrected name
            label: 'Custom API Base URL',
            hint: 'e.g., https://api.openai.com/v1',
            saveAction:
                (value) => settingsService.setCustoombaseurl(
                  value,
                ), // Use corrected name
          ),
          const SizedBox(height: _itemSpacing),
          _buildTextFieldSetting(
            initialValue: settings.apitokenmain,
            label: 'Main API Token',
            saveAction: (value) => settingsService.setApitokenmain(value),
            obscureText: true,
          ),
          const SizedBox(height: _itemSpacing),
          _buildTextFieldSetting(
            initialValue: settings.geminitoken,
            label: 'Google Gemini API Token',
            saveAction: (value) => settingsService.setGeminitoken(value),
            obscureText: true,
          ),
           _buildSectionTitle(context, 'Developer Options'),
          Padding(
            padding: _tilePadding,
            child: SwitchListTile(
              title: const Text('Enabling AI Studio usage'),
              subtitle: const Text('If you want switch using API keys to AI Studio '),
              value: settings.useaistudiotoken,
              onChanged: (settingsService.setUseaistudiotoken),
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: _sectionSpacing * 2), 
          const SizedBox(height: _itemSpacing),
          _buildTextFieldSetting(
            initialValue: settings.apitokensub,
            label: 'Secondary API Token (Optional)',
            saveAction: (value) => settingsService.setApitokensub(value),
            obscureText: true,
          ),
          const SizedBox(height: _itemSpacing),
          _buildTextFieldSetting(
            initialValue: settings.setapisdkbaseurl,
            label: 'API SDK Base URL (Optional Proxy)',
            hint: 'e.g., https://your-proxy.com/v1',
            saveAction: (value) => settingsService.setApisdkbaseurl(value),
          ),

          const SizedBox(height: _sectionSpacing),

          // --- Model Configuration ---
          _buildSectionTitle(context, 'Model Configuration'),
          _buildDropdownSetting<String>(
            label: 'Default Chat Model',
            value: settings.defaultchatmodel,
            items: data.asData?.value ?? customModels,
            // Ensure a valid model is selected, fallback if current selection disappears
            onSelected: (val) {
              if (val != null && customModels.contains(val)) {
                ref.read(settingsServiceProvider).setDefaultchatmodel(val);
                settingsServiceProvider.overrideWith((ref) => settingsService);
                // else: Do nothing if no models available
              }
            },
            currentValueProvider: () => settings.defaultchatmodel,
            hintWhenEmpty: "Reload models or check URL/Token",
          ),
          const SizedBox(height: _itemSpacing),
          _buildDropdownSetting<String>(
            label: 'Text Processing Model',
            value: settings.textprocessingmodel,
          items: data.asData?.value ?? customModels,
            // Ensure a valid model is selected, fallback if current selection disappears
            onSelected: (val) {
              if (val != null && customModels.contains(val)) {
                ref.read(settingsServiceProvider).setTextprocessingmodel(val);
                settingsServiceProvider.overrideWith((ref) => settingsService);
                // else: Do nothing if no models available
              }
            },
            currentValueProvider: () => settings.textprocessingmodel,
            hintWhenEmpty: "Reload models or check URL/Token",
          ),
          const SizedBox(height: _itemSpacing),
          _buildDropdownSetting<String>(
            label: 'Vision Processing Model',
            value: settings.visionprocessingmodel,
           items: data.asData?.value ?? customModels,
            // Ensure a valid model is selected, fallback if current selection disappears
            onSelected: (val) {
              if (val != null && customModels.contains(val)) {
                ref.read(settingsServiceProvider).setVisionprocessingmodel(val);
                settingsServiceProvider.overrideWith((ref) => settingsService);
                // else: Do nothing if no models available
              }
            },
            currentValueProvider: () => settings.visionprocessingmodel,
            hintWhenEmpty: "Reload models or check URL/Token",
          ),
          const SizedBox(height: _itemSpacing),
          _buildDropdownSetting<String>(
            label: 'Image Analysis Model',
            value: settings.imageanalysismodeldetails,
           items: data.asData?.value ?? customModels,
            // Ensure a valid model is selected, fallback if current selection disappears
            onSelected: (val) {
              if (val != null && customModels.contains(val)) {
                ref.read(settingsServiceProvider).setImageanalysismodeldetails(val);
                settingsServiceProvider.overrideWith((ref) => settingsService);
                // else: Do nothing if no models available
              }
            },
            currentValueProvider: () => settings.imageanalysismodeldetails,
            hintWhenEmpty: "Reload models or check URL/Token",
          ),

          const SizedBox(height: _sectionSpacing),

          // --- Voice and Speech ---
          _buildSectionTitle(context, 'Voice and Speech'),
          _buildDropdownSetting<String>(
            label: 'Voice Generation Model (TTS)',
            // Ensure value exists in items, provide default otherwise
            value:
                ['tts-1', 'tts-1-hd'].contains(settings.voiceprocessingmodel)
                    ? settings.voiceprocessingmodel
                    : 'tts-1',
            items: const ['tts-1', 'tts-1-hd'],
            onSelected:
                (val) =>
                    settingsService.setVoiceprocessingmodel(val ?? 'tts-1'),
            currentValueProvider: () => settings.voiceprocessingmodel,
          ),
          const SizedBox(height: _itemSpacing),
          _buildDropdownSetting<String>(
            label: 'Default Voice',
            value:
                [
                      'alloy',
                      'echo',
                      'fable',
                      'onyx',
                      'nova',
                      'shimmer',
                    ].contains(settings.setdefaultvoice)
                    ? settings.setdefaultvoice
                    : 'shimmer',
            items: const ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'],
            onSelected:
                (val) => settingsService.setDefaultvoice(val ?? 'shimmer'),
            currentValueProvider: () => settings.setdefaultvoice,
          ),

          const SizedBox(height: _sectionSpacing),

          // --- Image Generation ---
          _buildSectionTitle(context, 'Image Generation'),
          _buildDropdownSetting<String>(
            label: 'Image Generation Model',
            value:
                ['dall-e-3', 'dall-e-2'].contains(settings.imagegenerationmodel)
                    ? settings.imagegenerationmodel
                    : 'dall-e-3',
            items: const ['dall-e-3', 'dall-e-2'],
            onSelected:
                (val) =>
                    settingsService.setImagegenerationmodel(val ?? 'dall-e-3'),
            currentValueProvider: () => settings.imagegenerationmodel,
          ),
          const SizedBox(height: _itemSpacing),
          _buildDropdownSetting<String>(
            label: 'Image Quality',
            value:
                ['standard', 'hd'].contains(settings.imagegenerationquality)
                    ? settings.imagegenerationquality
                    : 'standard',
            items: const ['standard', 'hd'],
            onSelected:
                (val) => settingsService.setImagegenerationquality(
                  val ?? 'standard',
                ),
            currentValueProvider: () => settings.imagegenerationquality,
          ),
          const SizedBox(height: _itemSpacing),
          _buildDropdownSetting<String>(
            label: 'Image Size',
            // Add logic here if sizes depend on the selected model
            value:
                [
                      '1024x1024',
                      '1024x1792',
                      '1792x1024',
                      '512x512',
                      '256x256',
                    ].contains(settings.imagegenerationsize)
                    ? settings.imagegenerationsize
                    : '1024x1024',
            items: const [
              '1024x1024',
              '1024x1792',
              '1792x1024',
              '512x512',
              '256x256',
            ],
            onSelected:
                (val) =>
                    settingsService.setImagegenerationsize(val ?? '1024x1024'),
            currentValueProvider: () => settings.imagegenerationsize,
          ),

          const SizedBox(height: _sectionSpacing),

          // --- App Behavior ---
          _buildSectionTitle(context, 'App Behavior'),
          _buildDropdownSetting<String>(
            label: 'Usage Mode',
            value:
                ['normal', 'power', 'minimal'].contains(settings.usagemode)
                    ? settings.usagemode
                    : 'normal',
            items: const ['normal', 'power', 'minimal'],
            onSelected: (val) => settingsService.setUsagemode(val ?? 'normal'),
            currentValueProvider: () => settings.usagemode,
          ),
          const SizedBox(height: _itemSpacing),
          Padding(
            padding: _tilePadding,
            child: SwitchListTile(
              title: const Text('Enable Model Tools'),
              subtitle: const Text('Allow function calling, web search etc.'),
              value:
                  !settings
                      .turnofftools, // UI shows "Enable", so value is inverse of "TurnOff"
              onChanged:
                  (val) =>
                      settingsService.setTurnofftools(!val), // Save the inverse
              contentPadding:
                  EdgeInsets.zero, // Use Padding widget externally if needed
            ),
          ),
          const SizedBox(height: _itemSpacing / 2), // Smaller gap
          Padding(
            padding: _tilePadding,
            child: SwitchListTile(
              title: const Text('Auto Generate Chat Titles'),
              subtitle: const Text(
                'Uses a model for titles based on the first messages',
              ),
              value: settings.autotitle,
              onChanged: settingsService.setAutotitle,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (settings.autotitle) ...[
            // Updated to match the new naming
            const SizedBox(height: _itemSpacing),
            _buildDropdownSetting<String>(
              label: 'Auto Title Model',
              value: settings.autotitlemodel,
              items:
                  customModels.isNotEmpty
                      ? customModels
                      : const [
                        'gpt-3.5-turbo-0125',
                        'gpt-4-turbo-preview',
                      ], // Provide fallbacks
              onSelected:
                  (val) => settingsService.setAutotitlemodel(
                    val ?? '',
                  ), // Allow clearing
              currentValueProvider: () => settings.autotitlemodel,
              hintWhenEmpty: "Select title model or reload models",
            ),
          ],
          //  const SizedBox(height: _itemSpacing),
          //  // Assuming customOutputStyle is a Map, you probably want a dropdown for simple cases
          //  _buildDropdownSetting<String>(
          //     label: 'AI Output Format Preference',
          //     value: settings.customoutputstyle['text'] ?? 'text', // Get primary style
          //     items: const ['text', 'markdown'], // Example basic styles
          //     onSelected: (val) => settingsService.setcus({'text': val ?? 'text'}), // Update map
          //     currentValueProvider: () => settings.customoutputstyle['text'] ?? 'text',
          //  ),
          const SizedBox(height: _itemSpacing),
          _buildDropdownSetting<String>(
            label: 'Location for Custom Search Tool',
            value: settings.customsearchlocation,
            items: const [
              'GB',
              'US',
              'DE',
              'FR',
              'CA',
              'AU',
              'IN',
              'JP',
              'KR',
              'BR',
              'ZA',
            ], // Example countries
            onSelected:
                (val) => settingsService.setCustomsearchlocation(val ?? 'GB'),
            currentValueProvider: () => settings.customsearchlocation,
          ),

          const SizedBox(height: _sectionSpacing),

          // --- History Settings ---
          _buildSectionTitle(context, 'History Settings'),
          Padding(
            padding: _tilePadding,
            child: SwitchListTile(
              title: const Text('Enable Chat History'),
              subtitle: const Text('Save conversations locally'),
              value: settings.historychatenabled,
              onChanged: settingsService.setHistorychatenabled,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (settings.historychatenabled) ...[
            const SizedBox(height: _itemSpacing),
            Padding(
              padding: _tilePadding,
              child: SwitchListTile(
                title: const Text('Send History Context to Model'),
                subtitle: const Text('Include previous messages in API calls'),
                value: settings.historyformodelsenabled,
                onChanged: settingsService.setHistoryformodelsenabled,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (settings.historyformodelsenabled) ...[
              const SizedBox(height: _itemSpacing),
              _buildIntInputSetting(
                context,
                label:
                    'Messages Sent to Model (0=Max):', // Clarify 0 behavior if needed
                value: settings.historybufferlength,
                onChanged: (val) => settingsService.setHistorybufferlength(val),
                minValue: 0,
                maxValue: 50,
              ),
            ],
          ],

          const SizedBox(height: _sectionSpacing),

          // --- Long-Term Memory ---
          Padding(
            padding: _tilePadding,
            child: ListTile(
              leading: const Icon(Icons.memory_outlined),
              title: const Text('Long-Term Memory'),
              subtitle: const Text('View or manually edit saved items'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showDialog(
                  context: context,
                  // Ensure ViewLongTermMemoryDialog is a ConsumerWidget or uses Consumer
                  builder: (_) => const ViewLongTermMemoryDialog(),
                );
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),

          const SizedBox(height: _sectionSpacing),

          // --- Custom Function Tool API (Advanced) ---
          // Use ExpansionTileTheme for cleaner look if desired
          ExpansionTile(
            title: Text(
              'Custom Function Tool API (Advanced)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            childrenPadding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 8.0,
            ), // Pad children
            initiallyExpanded:
                settings.customapiname.isNotEmpty, // Expand if configured
            children: [
              _buildTextFieldSetting(
                initialValue: settings.customapiname,
                label: 'Tool API Name',
                hint: 'e.g., weather_api or stock_quote',
                saveAction:
                    (values) => settingsService.setCustomapiname(values),
              ),
              const SizedBox(height: _itemSpacing),
              _buildTextFieldSetting(
                initialValue: settings.customapiurl,
                label: 'Tool API URL',
                hint: 'https://api.example.com/data?query=%query%',
                keyboardType: TextInputType.url,
                saveAction: (val) => settingsService.setCustomapiurl(val),
              ),
              const SizedBox(height: _itemSpacing),
              _buildDropdownSetting<String>(
                label: 'Tool API Request Type',
                value: settings.customapitype,
                items: const ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
                onSelected:
                    (val) => settingsService.setCustomapitype(val ?? 'GET'),
                currentValueProvider: () => settings.customapitype,
              ),
              const SizedBox(height: _itemSpacing),
              _buildTextFieldSetting(
                initialValue: settings.customapiheaders,
                label: 'Tool API Headers (JSON)',
                hint: '{"Content-Type": "application/json", "X-Api-Key":"..."}',
                maxLines: 4,
                minLines: 2,
                keyboardType: TextInputType.multiline,
                saveAction: (val) => settingsService.setCustomapiheaders(val),
              ),
              const SizedBox(height: _itemSpacing),
              _buildTextFieldSetting(
                initialValue: settings.customapiparam,
                label: 'Tool API Parameters Template (JSON)',
                hint: '{\n  "location": "%query%",\n  "units": "metric"\n}',
                maxLines: 4,
                minLines: 2,
                keyboardType: TextInputType.multiline,
                saveAction: (val) => settingsService.setCustomapiparam(val),
              ),
              const SizedBox(height: _itemSpacing),
              _buildTextFieldSetting(
                // Keep if needed, maybe rename 'API Auth Token'
                initialValue: settings.customapitoken,
                label: 'Tool API Bearer Token (Optional)',
                saveAction: (val) => settingsService.setCustomapitoken(val),
                obscureText: true,
              ),
              const SizedBox(height: _itemSpacing),
              _buildTextFieldSetting(
                // Keep if needed, maybe rename 'API Auth Key'
                initialValue: settings.customapikey,
                label: 'Tool API Key (Header/Query - Optional)',
                saveAction: (val) => settingsService.setCustomapikey(val),
                obscureText: true,
              ),
            ],
          ),

          const SizedBox(height: _sectionSpacing),

          // --- Developer Options ---
          _buildSectionTitle(context, 'Developer Options'),
          Padding(
            padding: _tilePadding,
            child: SwitchListTile(
              title: const Text('Developer Mode'),
              subtitle: const Text('Enable extra logging or features'),
              value: settings.devmod,
              onChanged: (settingsService.setDevmod),
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: _sectionSpacing * 2), // Extra bottom padding
        ],
      ),
    );
  }

  // --- Helper Methods ---

  // Helper for Section Titles
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 16.0,
        bottom: 8.0,
      ), // Add spacing around title
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  // Updated Slider Helper
  Widget _buildSliderSetting(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      // Use Column for better label placement
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(2), // Keep label on slider
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Updated Int Input Helper (Uses FocusNode for saving on focus loss)
  Widget _buildIntInputSetting(
    BuildContext context, {
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int minValue = 0,
    int? maxValue,
  }) {
    return _SettingTextField<int>(
      label: label,
      initialValue: value,
      onSave: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      parser: (text) => int.tryParse(text),
      validator: (val) {
        if (val == null) return value; // Revert if parse fails
        int finalVal = val;
        if (finalVal < minValue) finalVal = minValue;
        if (maxValue != null && finalVal > maxValue) finalVal = maxValue;
        return finalVal;
      },
      textAlign: TextAlign.right,
      width: 80,
    );
  }

  // Updated Text Field Helper (Uses FocusNode for saving on focus loss)
  Widget _buildTextFieldSetting({
    required String initialValue,
    String? label, // Label can be optional if using _buildSectionTitle
    String? hint,
    required Function(String) saveAction,
    bool obscureText = false,
    int maxLines = 1,
    int minLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return _SettingTextField<String>(
      initialValue: initialValue,
      label: label,
      hint: hint,
      onSave: saveAction,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      parser: (text) => text.trim(), // Trim whitespace on save
      validator:
          (val) =>
              val ??
              initialValue, // Revert if parse fails (shouldn't for string)
    );
  }

  // Updated Dropdown Helper
  Widget _buildDropdownSetting<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onSelected,
    String? hintWhenEmpty,
    // Optional: Add a way to get the current value for robust checking
    required T Function() currentValueProvider,
  }) {
    bool isEmpty = items.isEmpty;
    // Ensure the currently selected value is actually in the list,
    // otherwise, fallback or show hint more clearly.
    T? selection = isEmpty ? null : (items.contains(value) ? value : null);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
      ), // Consistent vertical padding
      child: DropdownButtonFormField<T>(
        value: selection,
        isExpanded: true, // Make dropdown take available width
        decoration: InputDecoration(
          labelText: label,
          // hintText: isEmpty ? hintWhenEmpty : (selection == null ? "Select..." : null), // Show hint if empty OR current value not in list
          hintText:
              isEmpty
                  ? hintWhenEmpty
                  : (selection == null
                      ? (items.isNotEmpty
                          ? 'Select a valid model'
                          : 'No models available')
                      : null),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          isDense: true,
          enabled: !isEmpty, // Disable interaction if empty
        ),
        items:
            isEmpty
                ? [] // No items if the list is empty
                : items
                    .map(
                      (item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          item.toString().split('.').last,
                        ), // Attempt to shorten long model names if needed
                      ),
                    )
                    .toList(),
        onChanged:
            isEmpty
                ? null
                : (T? newValue) {
                  // Only call onSelected if the value actually changes
                  if (newValue != null && newValue != currentValueProvider()) {
                    onSelected(newValue);
                  }
                },
      ),
    );
  }

  // Helper method for reset confirmation
  void _showResetConfirmationDialog(
    BuildContext context,
    SettingsService service,
  ) {
    showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Reset Settings?'),
            content: const Text(
              'This will reset all settings to their default values. Reloading the app may be required for all changes to take effect.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Reset'),
              ),
            ],
          ),
    ).then((confirmed) {
      if (confirmed == true) {
        service.resetToDefaults();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to defaults.')),
        );
      }
    });
  }
}

// --- Reusable Stateful Helper Widget for Text Fields ---
// This manages controller and focus node lifecycle and saves on focus loss
class _SettingTextField<T> extends StatefulWidget {
  final T initialValue;
  final String? label;
  final String? hint;
  final Function(T) onSave;
  final bool obscureText;
  final int maxLines;
  final int minLines;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final T? Function(String) parser; // Function to parse text to type T
  final T Function(T?) validator; // Function to validate/clamp parsed value
  final TextAlign textAlign;
  final double? width; // Optional fixed width

  const _SettingTextField({
    super.key,
    required this.initialValue,
    this.label,
    this.hint,
    required this.onSave,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    required this.parser,
    required this.validator,
    this.textAlign = TextAlign.start,
    this.width,
  });

  @override
  State<_SettingTextField<T>> createState() => _SettingTextFieldState<T>();
}

class _SettingTextFieldState<T> extends State<_SettingTextField<T>> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late T _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _controller = TextEditingController(text: widget.initialValue.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _saveValue();
    }
  }

  void _saveValue() {
    final parsed = widget.parser(_controller.text);
    final validatedValue = widget.validator(parsed);

    // Only trigger save if the value has actually changed
    if (validatedValue != _currentValue) {
      widget.onSave(validatedValue);
      _currentValue = validatedValue; // Update internal state tracking
      // Update controller text only if validation changed it (e.g., clamping)
      if (_controller.text != validatedValue.toString()) {
        final newText = validatedValue.toString();
        _controller.text = newText;
        // Optionally move cursor to end after programmatic change
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: newText.length),
        );
      }
    } else {
      // If validation didn't change the value, but parsing failed or resulted
      // in the same value, ensure the text field reflects the known good state.
      // This handles cases where the user types invalid chars then clicks away.
      if (_controller.text != _currentValue.toString()) {
        _controller.text = _currentValue.toString();
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SettingTextField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the initialValue coming from the provider changes externally
    // (e.g., due to reset), update the text field.
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _currentValue) {
      _currentValue = widget.initialValue;
      _controller.text = widget.initialValue.toString();
      // Move cursor to end if needed
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget textField = TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textAlign: widget.textAlign,
      // Save on submission (e.g., pressing Enter on keyboard)
      onFieldSubmitted: (_) => _saveValue(),
    );

    // Wrap with SizedBox if width is specified
    if (widget.width != null) {
      textField = SizedBox(width: widget.width, child: textField);
    }

    // If label is provided standalone (not part of InputDecoration)
    if (widget.label != null && widget.width != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            textField, // SizedBox is now inside the 'textField' variable
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: textField, // Regular text field, label is inside InputDecoration
      );
    }
  }
}
