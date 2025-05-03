// lib/presentation/screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart'; // Corrected path
// Import memory and tool providers if needed for dialogs launched from here
import '../providers/memory_provider.dart';
import '../widgets/view_long_term_memory_dialog.dart'; // Corrected path
// Assuming CustomToolService and its provider exist
// import '../providers/tool_provider.dart';
// import '../widgets/add_edit_custom_tool_dialog.dart';

class SettingsPage extends ConsumerWidget { // Use ConsumerWidget
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Add WidgetRef
    // Use ref.watch to get the service state
    final settings = ref.watch(settingsServiceProvider);
    final customModels = ref.watch(customAvailableModelsProvider); // Watch available models

    // Get tool service if implemented
    // final toolService = ref.watch(customToolServiceProvider);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
           // Reload Models Button
           IconButton(
               icon: const Icon(Icons.sync),
               tooltip: 'Reload Models from Custom URL',
               onPressed: settings.custoombaseurl.isNotEmpty && settings.apitokenmain.isNotEmpty
                   ? () async {
                      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Fetching models from ${settings.custoombaseurl}...')),);
                      try {
                        // Use ref.read() to call methods on the notifier/service
                        await ref.read(settingsServiceProvider).getModels();
                         ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Models reloaded.')),);
                      } catch (e) {
                         ScaffoldMessenger.of(context).hideCurrentSnackBar();
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching models: $e'), backgroundColor: Colors.red),);
                      }
                  }
                   : null, // Disable if URL or token is missing
           ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Defaults',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset Settings?'),
                  content: const Text(
                    'This will reset all generation parameters, instructions, API settings, theme, etc., to their defaults. Long-term memory will not be affected.', // Updated text
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel'),),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.orange,),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                // Use ref.read to call methods
                ref.read(settingsServiceProvider).resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings reset to defaults.')),);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Theme Settings ---
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            subtitle: const Text('Follow device theme setting'),
            value: ThemeMode.system,
            groupValue: settings.themeMode,
            // Use ref.read for actions
            onChanged: (value) => ref.read(settingsServiceProvider).setThemeMode(value ?? ThemeMode.system),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light Theme'),
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (value) => ref.read(settingsServiceProvider).setThemeMode(value ?? ThemeMode.light),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Theme'),
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (value) => ref.read(settingsServiceProvider).setThemeMode(value ?? ThemeMode.dark),
          ),

          const Divider(height: 32),

          // --- Generation Parameters ---
          Text('Generation Parameters', style: Theme.of(context).textTheme.titleLarge,),
          _buildSliderSetting(
             context, ref: ref, // Pass ref
            label: 'Temperature: ${settings.temperature.toStringAsFixed(2)}',
            value: settings.temperature, min: 0.0, max: 2.0, divisions: 20,
            onChanged: (val) => ref.read(settingsServiceProvider).setTemperature(val),
          ),
           _buildSliderSetting( // Top P moved to match UI screenshot
             context, ref: ref,
             label: 'Top P: ${settings.topP.toStringAsFixed(2)}',
             value: settings.topP, min: 0.0, max: 1.0, divisions: 20,
             onChanged: (val) => ref.read(settingsServiceProvider).setTopP(val),
           ),
           _buildIntInputSetting( // Top K
             context, ref: ref,
             label: 'Top K:',
             value: settings.topK.toInt(),
             onChanged: (val) => ref.read(settingsServiceProvider).setTopK(val.toDouble()),
             minValue: 1,
           ),
             _buildIntInputSetting( // Max Tokens
             context, ref: ref,
             label: 'Max Output Tokens:',
             value: settings.maxOutputTokens,
             onChanged: (val) => ref.read(settingsServiceProvider).setMaxOutputTokens(val),
             minValue: 1, // Needs a minimum
             maxValue: 100000, // Example max
           ),


          const Divider(height: 32),

          // --- System Instruction ---
          Text('System Instruction', style: Theme.of(context).textTheme.titleLarge),
           _buildTextFieldSetting( // Use helper for consistency
              ref: ref,
              initialValue: settings.systemInstruction,
              label: 'System Instruction',
              hint: 'Enter system instruction for the AI...',
              maxLines: 6,
              minLines: 3,
              saveAction: (val) => ref.read(settingsServiceProvider).setSystemInstruction(val),
            ),


          const Divider(height: 32),

          // --- API Configuration ---
          Text('API Configuration', style: Theme.of(context).textTheme.titleLarge),
           _buildTextFieldSetting(
               ref: ref,
               initialValue: settings.custoombaseurl,
               label: 'Custom API Base URL',
               hint: 'e.g., https://api.example.com/v1',
               saveAction: (val) => ref.read(settingsServiceProvider).setCustoombaseurl(val),
             ),
             const SizedBox(height: 16),
             _buildTextFieldSetting(
               ref: ref,
               initialValue: settings.apitokenmain,
               label: 'Main API Token',
               saveAction: (val) => ref.read(settingsServiceProvider).setApitokenmain(val),
               obscureText: true,
             ),
             const SizedBox(height: 16),
             _buildTextFieldSetting(
               ref: ref,
               initialValue: settings.apitokensub,
               label: 'Secondary API Token (Optional)',
               saveAction: (val) => ref.read(settingsServiceProvider).setApitokensub(val),
               obscureText: true,
             ),

            // SDK Settings - commented out in original, maybe keep hidden or remove
            // const SizedBox(height: 16),
            // _buildTextFieldSetting(ref: ref, initialValue: settings.setapisdkmodel, label: 'API SDK Model (Unused?)', saveAction: (val) => ref.read(settingsServiceProvider).setApisdkmodel(val)),
             const SizedBox(height: 16),
             _buildTextFieldSetting(
                 ref: ref,
                 initialValue: settings.setapisdkbaseurl,
                 label: 'API SDK Base URL (OpenAI Proxy?)',
                 hint: 'e.g., https://your-proxy.com/v1',
                 saveAction: (val) => ref.read(settingsServiceProvider).setApisdkbaseurl(val)
             ),


          const Divider(height: 32),

          // --- Model Configuration ---
          Text('Model Configuration', style: Theme.of(context).textTheme.titleLarge),
          _buildDropdownSetting<String>(
            ref: ref,
            label: 'Default Chat Model',
            value: settings.defaultchatmodel,
            items: customModels, // Use models fetched from custom URL
            onSelected: (val) => ref.read(settingsServiceProvider).setDefaultchatmodel(val ?? settings.defaultchatmodel),
            hintWhenEmpty: "Reload models or check URL/Token",
          ),
           _buildDropdownSetting<String>(
             ref: ref,
             label: 'Text Processing Model',
             value: settings.textprocessingmodel,
             items: customModels,
             onSelected: (val) => ref.read(settingsServiceProvider).setTextprocessingmodel(val ?? settings.textprocessingmodel),
             hintWhenEmpty: "Reload models or check URL/Token",
           ),
           _buildDropdownSetting<String>(
             ref: ref,
             label: 'Vision Processing Model',
             value: settings.visionprocessingmodel,
             items: customModels, // Assuming vision models are in the same list
             onSelected: (val) => ref.read(settingsServiceProvider).setVisionprocessingmodel(val ?? settings.visionprocessingmodel),
             hintWhenEmpty: "Reload models or check URL/Token",
           ),
            _buildDropdownSetting<String>( // For Image analysis - assuming same model list
                  ref: ref,
                  label: 'Image Analysis Model',
                  value: settings.imageanalysismodeldetails, // Check key name consistency
                  items: customModels,
                  onSelected: (val) => ref.read(settingsServiceProvider).setImageanalysismodeldetails(val ?? settings.imageanalysismodeldetails),
                  hintWhenEmpty: "Reload models or check URL/Token",
            ),


          const Divider(height: 32),


          // --- Voice and Speech ---
          Text('Voice and Speech', style: Theme.of(context).textTheme.titleLarge),
          _buildDropdownSetting<String>(
              ref: ref,
              label: 'Voice Generation Model (TTS)',
              value: settings.voiceprocessingmodel,
              items: ['tts-1', 'tts-1-hd'], // Example fixed list for TTS models
              onSelected: (val) => ref.read(settingsServiceProvider).setVoiceprocessingmodel(val ?? 'tts-1'),
           ),
           _buildDropdownSetting<String>(
             ref: ref,
              label: 'Default Voice',
              value: settings.setdefaultvoice,
              items: ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'], // Standard OpenAI voices
              onSelected: (val) => ref.read(settingsServiceProvider).setDefaultvoice(val ?? 'shimmer'),
           ),

          const Divider(height: 32),


          // --- Image Generation ---
          Text('Image Generation', style: Theme.of(context).textTheme.titleLarge),
           _buildDropdownSetting<String>(
             ref: ref,
              label: 'Image Generation Model',
              value: settings.imagegenerationmodel,
              items: ['dall-e-3', 'dall-e-2'], // Example DALL-E models
              onSelected: (val) => ref.read(settingsServiceProvider).setImagegenerationmodel(val ?? 'dall-e-3'),
           ),
           _buildDropdownSetting<String>(
             ref: ref,
              label: 'Image Quality',
              value: settings.imagegenerationquality,
              items: ['standard', 'hd'],
              onSelected: (val) => ref.read(settingsServiceProvider).setImagegenerationquality(val ?? 'standard'),
           ),
           _buildDropdownSetting<String>(
             ref: ref,
             label: 'Image Size',
             value: settings.imagegenerationsize,
             // Use items specific to the selected model if possible, otherwise show all
             items: ['1024x1024', '1024x1792', '1792x1024', /* DALL-E 2 sizes:*/ '512x512', '256x256'],
             onSelected: (val) => ref.read(settingsServiceProvider).setImagegenerationsize(val ?? '1024x1024'),
           ),

           const Divider(height: 32),

          // --- App Behavior ---
          Text('App Behavior', style: Theme.of(context).textTheme.titleLarge),
           _buildDropdownSetting<String>(
             ref: ref,
             label: 'Usage Mode',
             value: settings.usagemode,
             items: ['normal', 'power', 'minimal'],
             onSelected: (val) => ref.read(settingsServiceProvider).setUsagemode(val ?? 'normal')
           ),
             SwitchListTile(
              title: const Text('Enable Model Tools'),
              subtitle: const Text('Allow model to use function calling, etc.'),
               // Note: turnofftools is true when tools are OFF. So value is inversed.
              value: !settings.turnofftools,
              onChanged: (val) => ref.read(settingsServiceProvider).setTurnofftools(!val), // Invert logic for saving
            ),
            SwitchListTile(
             title: const Text('Auto Generate Chat Titles'),
             subtitle: const Text('Uses a model to create titles based on the first message'),
             value: settings.autotitle,
             onChanged: (val) => ref.read(settingsServiceProvider).setAutotitle(val),
           ),
            // Add dropdown for Auto Title Model if `autotitle` is true
             if(settings.autotitle)
                _buildDropdownSetting<String>(
                  ref: ref,
                  label: 'Auto Title Model',
                  value: settings.autotitlemodel,
                  items: customModels.isNotEmpty ? customModels : ['gpt-3.5-turbo-0125', 'gpt-4.1-nano'], // Provide fallbacks
                  onSelected: (val) => ref.read(settingsServiceProvider).setAutotitlemodel(val ?? ''), // Allow clearing
                   hintWhenEmpty: "Select a model for titles",
                ),
              _buildDropdownSetting<String>(
                ref: ref,
                label: 'AI Output Style Preference',
                value: settings.customoutputstyle.toString(),
                 items: ['text', 'markdown'],
                 onSelected: (val) => ref.read(settingsServiceProvider).setCustomoutputstyle(val ?? 'text'),
             ),
             _buildDropdownSetting<String>(
                ref: ref,
                label: 'Location for Custom Search Tool',
               value: settings.customsearchlocation,
                items: ['GB', 'US', 'DE', 'FR', 'CA', 'AU', 'IN', 'JP', 'KR', 'BR', 'ZA'], // Example countries
                onSelected: (val) => ref.read(settingsServiceProvider).setCustomsearchlocation(val ?? 'GB'),
             ),

           const Divider(height: 32),

          // --- History Settings ---
          Text('History Settings', style: Theme.of(context).textTheme.titleLarge),
            SwitchListTile(
             title: const Text('Enable Chat History'),
             subtitle: const Text('Save conversations locally'),
             value: settings.historychatenabled,
             onChanged: (val) => ref.read(settingsServiceProvider).setHistorychatenabled(val),
            ),
           // Only show buffer length if history is enabled
           if (settings.historychatenabled) ...[
               SwitchListTile(
                title: const Text('Send History Context to Model'),
                subtitle: const Text('Include previous messages in API calls'),
                value: settings.historyformodelsenabled,
                onChanged: (val) => ref.read(settingsServiceProvider).setHistoryformodelsenabled(val),
              ),
              // Only show buffer length adjustment if model history is enabled
              if (settings.historyformodelsenabled)
                 _buildIntInputSetting(
                  context, ref: ref,
                  label: 'Messages Sent to Model (0=All):', // Renamed label
                  value: settings.historybufferlength, // Check key name consistency
                  onChanged: (val) => ref.read(settingsServiceProvider).setHistorybufferlength(val), // Check key name
                  minValue: 0,
                  maxValue: 50, // Match service limit
                ),
            ],

           const Divider(height: 32),

          // --- Long-Term Memory ---
          ListTile(
            leading: const Icon(Icons.memory_outlined),
            title: Text('Long-Term Memory', style: Theme.of(context).textTheme.titleLarge),
            subtitle: const Text('View or manually edit saved items'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Ensure the dialog is a ConsumerWidget or uses Consumer
              showDialog(
                context: context,
                builder: (_) => const ViewLongTermMemoryDialog(), // Use the correct dialog widget
              );
            },
          ),

           const Divider(height: 32),

          // --- Custom API Configuration (Optional Section) ---
          ExpansionTile( // Make this section collapsible
            title: Text('Custom Function Tool API (Advanced)', style: Theme.of(context).textTheme.titleMedium),
             initiallyExpanded: settings.customapiname.isNotEmpty, // Expand if already configured
             childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
             children: [
               _buildTextFieldSetting(
                     ref: ref,
                    initialValue: settings.customapiname,
                     label: 'Tool API Name',
                     hint: 'e.g., weather_api',
                     saveAction: (val) => ref.read(settingsServiceProvider).setCustomapiname(val)
                ),
                 const SizedBox(height: 16),
                 _buildTextFieldSetting(
                     ref: ref,
                     initialValue: settings.customapiurl,
                     label: 'Tool API URL',
                     hint: 'https://api.weather.com/current',
                     saveAction: (val) => ref.read(settingsServiceProvider).setCustomapiurl(val)
                 ),
                 const SizedBox(height: 16),
                  _buildDropdownSetting<String>( // API Type dropdown
                     ref: ref,
                    label: 'Tool API Request Type',
                     value: settings.customapitype,
                     items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
                     onSelected: (val) => ref.read(settingsServiceProvider).setCustomapitype(val ?? 'GET'),
                 ),
                 const SizedBox(height: 16),
                 _buildTextFieldSetting( // API Headers
                     ref: ref,
                     initialValue: settings.customapiheaders,
                    label: 'Tool API Headers (JSON)',
                     hint: '{"Content-Type": "application/json", "X-Api-Key":"..."}',
                    maxLines: 4, minLines: 2,
                    saveAction: (val) => ref.read(settingsServiceProvider).setCustomapiheaders(val)
                 ),
                 const SizedBox(height: 16),
                  _buildTextFieldSetting( // API Params (JSON - potentially for GET query or POST body structure)
                    ref: ref,
                     initialValue: settings.customapiparam,
                     label: 'Tool API Parameters (JSON)',
                     hint: '{"location": "%query%", "units": "metric"}',
                     maxLines: 4, minLines: 2,
                     saveAction: (val) => ref.read(settingsServiceProvider).setCustomapiparam(val)
                 ),
                // Note: customapiparamvalue seems redundant if params are defined above. Remove?
                // Or is it for a single dynamic value replacement? Clarify purpose.
                 // _buildTextFieldSetting(ref: ref, initialValue: settings.customapiparamvalue, label: 'Custom API Param Value', saveAction: (val) => ref.read(settingsServiceProvider).setCustomapiparamvalue(val)),

                 // Authentication fields (Optional, maybe hide individually if not needed)
                const SizedBox(height: 16),
                 _buildTextFieldSetting(
                       ref: ref,
                       initialValue: settings.customapitoken,
                       label: 'Tool API Bearer Token (Optional)',
                      saveAction: (val) => ref.read(settingsServiceProvider).setCustomapitoken(val),
                       obscureText: true
                 ),
                 const SizedBox(height: 8),
                 _buildTextFieldSetting(
                      ref: ref,
                      initialValue: settings.customapikey,
                      label: 'Tool API Key (Header/Query - Optional)', // Specify where key is used in headers/params
                      saveAction: (val) => ref.read(settingsServiceProvider).setCustomapikey(val),
                      obscureText: true
                 ),

             ],
          ),

          const Divider(height: 32),

          // --- Developer Options ---
          Text('Developer Options', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            title: const Text('Developer Mode'),
            subtitle: const Text('Enable extra logging or features'),
            value: settings.devmod,
            onChanged: (val) => ref.read(settingsServiceProvider).setDevmod(val),
          ),
          // Add other dev options here if needed

          const SizedBox(height: 32), // Bottom padding
        ],
      ),
    );
  }


 // --- Helper Methods ---

 Widget _buildSliderSetting(
      BuildContext context, {
        required WidgetRef ref, // Pass ref
        required String label,
        required double value,
        required double min,
        required double max,
        required int divisions,
        required ValueChanged<double> onChanged,
      }) {
    return Padding(
       padding: const EdgeInsets.symmetric(vertical: 8.0),
       child: Row(
          children: [
            Expanded(flex: 3, child: Text(label, style: Theme.of(context).textTheme.bodyLarge)), // Adjust flex
            Expanded(
              flex: 5, // Adjust flex
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: value.toStringAsFixed(2),
                onChanged: onChanged, // Direct call
              ),
            ),
          ],
       ),
    );
  }

  Widget _buildIntInputSetting(
      BuildContext context, {
        required WidgetRef ref, // Pass ref
        required String label,
        required int value,
        required ValueChanged<int> onChanged,
        int minValue = 0,
        int? maxValue,
      }) {
    // Use stateful builder or separate stateful widget to manage controller lifecycle
    return StatefulBuilder(
        builder: (context, setState) {
         // Create controller inside builder if not using separate widget
         // This is less ideal for performance but simple for this example.
         // A dedicated StatefulWidget is better.
         final controller = TextEditingController(text: value.toString());
         controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));

         return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
               children: [
                 Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
                 SizedBox(
                    width: 80,
                    child: TextFormField(
                    controller: controller,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(isDense: true),
                    onFieldSubmitted: (newValue) {
                       final intVal = int.tryParse(newValue);
                       if (intVal != null) {
                         int finalVal = intVal;
                         if (finalVal < minValue) finalVal = minValue;
                         if (maxValue != null && finalVal > maxValue) finalVal = maxValue;
                         onChanged(finalVal); // Call the provider update
                         // Update text field only if value was clamped/changed
                         if (finalVal.toString() != controller.text) {
                           controller.text = finalVal.toString();
                           controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                         }
                       } else {
                         // Reset field to original value if parse fails
                           controller.text = value.toString();
                           controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                       }
                    },
                     // Optional: Update on focus lost as well
                    // onEditingComplete: () { ... similar logic ... },
                 ),
                ),
               ],
            ),
         );
        }
    );
  }

 // Helper for TextFields to reduce repetition
  Widget _buildTextFieldSetting({
    required WidgetRef ref,
    required String initialValue,
    required String label,
    String? hint,
    required Function(String) saveAction,
    bool obscureText = false,
    int maxLines = 1,
    int minLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
     // Use StatefulBuilder for local controller management
     return StatefulBuilder(
        builder: (context, setState) {
           final controller = TextEditingController(text: initialValue);
           // Move cursor to end initially
           controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));

           return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField( // Use TextFormField for potential validation later
                 controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Adjust padding
                 ),
                  obscureText: obscureText,
                  maxLines: maxLines,
                  minLines: minLines,
                  keyboardType: keyboardType,
                  // Save on focus loss or explicit action needed?
                  // Using onFieldSubmitted for simplicity here.
                  onFieldSubmitted: (value) => saveAction(value.trim()),
                  // Could also use onEditingComplete or a debounce on onChanged
                 onChanged: (value) {
                     // Optional: Live update (use debounce for performance)
                     // saveAction(value.trim());
                 },
              ),
           );
        }
    );
  }

  // Helper for Dropdown Menus
 Widget _buildDropdownSetting<T>({
   required WidgetRef ref,
   required String label,
   required T value,
   required List<T> items,
   required ValueChanged<T?> onSelected,
   String? hintWhenEmpty, // Optional hint when items list is empty
 }) {
   bool isEmpty = items.isEmpty;

   return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownMenu<T>(
         label: Text(label),
         // width: MediaQuery.of(context).size.width - 32, // Full width minus padding
         // Use requestFocusOnTap for better accessibility if needed
         initialSelection: isEmpty ? null : value, // Don't set initial if empty
         enabled: !isEmpty, // Disable if list is empty
         hintText: isEmpty ? hintWhenEmpty : null, // Show hint if empty
         dropdownMenuEntries: items.map((item) => DropdownMenuEntry<T>(
             value: item,
             // Assume item.toString() is a reasonable label
             label: item.toString(),
         )).toList(),
         onSelected: onSelected, // Direct call to provider update
      ),
   );
 }

}