// lib/presentation/widgets/right_settings_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinu/presentation/providers/settings_provider.dart';
//import '../providers/settings_provider.dart';
import '../providers/models_provider.dart'; // To get model lists

// Internal stateful part to manage expansion panels
class RightSettingsPanel extends ConsumerStatefulWidget {
  const RightSettingsPanel({super.key});
  @override
  ConsumerState<RightSettingsPanel> createState() => _RightSettingsPanelState();
}

class _RightSettingsPanelState extends ConsumerState<RightSettingsPanel> {
  // Local UI state for expansion
  bool _modelParamsExpanded = true; // Start expanded
  bool _advancedExpanded = false; // Start collapsed

  @override
  Widget build(BuildContext context) {
    // Watch the main settings service provider
    final settings = ref.watch(settingsServiceProvider);
    // Watch the combined model list provider
    final modelsAsyncValue = ref.watch(
      currentModelListProvider,
    ); // Use the combined/selected list

    return Column(
      children: [
        // --- Top Bar ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              const Text(
                'Run settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              _buildIconButton(
                context,
                Icons.refresh,
                'Reset Run Settings',
                onPressed:
                    () => _confirmResetSettings(
                      context,
                      ref,
                    ), // Show confirmation
              ),
              // Maybe add close button if this panel can be hidden?
            ],
          ),
        ),
        const Divider(height: 1, color: Color.fromARGB(255, 66, 66, 66)),

        // --- Scrollable Settings ---
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Model Selection ===
                modelsAsyncValue.when(
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  error:
                      (error, stack) => Tooltip(
                        message:
                            "$error\n$stack", // Show error details on hover
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[300],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Error loading models',
                              style: TextStyle(color: Colors.red[300]),
                            ),
                          ],
                        ),
                      ),
                  data: (modelIds) {
                    final currentSelectedModel = settings.defaultchatmodel;
                    // Ensure the current selection is valid within the loaded list
                    final isValidSelection =
                        currentSelectedModel.isNotEmpty &&
                        modelIds.contains(currentSelectedModel);
                    // Determine effective selection: current if valid, first if not, null if empty
                    final effectiveModel =
                        isValidSelection
                            ? currentSelectedModel
                            : (modelIds.isNotEmpty ? modelIds.first : null);

                    // Auto-select the first model if current selection is invalid/empty
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!isValidSelection &&
                          effectiveModel != null &&
                          settings.defaultchatmodel != effectiveModel) {
                        ref
                            .read(settingsServiceProvider)
                            .setDefaultchatmodel(effectiveModel);
                      }
                    });

                    return _buildDropdownSetting<String>(
                      ref: ref,
                      label: "Model",
                      value: effectiveModel, // Use the effective model
                      items: modelIds,
                      onSelected: (newValue) async {
                        if (newValue != null) {
                          ref
                              .read(settingsServiceProvider)
                              .setDefaultchatmodel(newValue);
                          settingsServiceProvider.overrideWith(
                            (ref) => settingsService,
                          );
                        }
                      },
                      hintWhenEmpty:
                          "No models available", // Hint if list is empty
                    );
                  },
                ),
                const SizedBox(height: 20),

                // === Generation Parameters Section ===
                _buildSectionHeader(
                  'Model parameters',
                  _modelParamsExpanded,
                  () => setState(
                    () => _modelParamsExpanded = !_modelParamsExpanded,
                  ),
                ),
                if (_modelParamsExpanded) ...[
                  _buildSliderSetting(
                    // Temperature
                    context,
                    ref: ref,
                    label: 'Temperature', // Label only
                    value: settings.temperature,
                    min: 0.0,
                    max: 2.0,
                    divisions: 20,
                    displayValue: settings.temperature.toStringAsFixed(
                      1,
                    ), // Separate display value
                    onChanged: (val) {
                      ref.read(settingsServiceProvider).setTemperature(val);
                      settingsServiceProvider.overrideWith(
                        (ref) => settingsService,
                      );
                    },
                  ),
                  _buildSliderSetting(
                    // Top P
                    context,
                    ref: ref,
                    label: 'Top P',
                    value: settings.topP,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    displayValue: settings.topP.toStringAsFixed(2),
                    onChanged: (val) {
                      ref.read(settingsServiceProvider).setTopP(val);
                      settingsServiceProvider.overrideWith(
                        (ref) => settingsService,
                      );
                    },
                  ),
                  _buildIntInputSetting(
                    // Top K
                    context,
                    ref: ref,
                    label: 'Top K', // Label only
                    value: settings.topK.toInt(),
                    onChanged: (val) {
                      ref.read(settingsServiceProvider).setTopK(val.toDouble());
                      settingsServiceProvider.overrideWith(
                        (ref) => settingsService,
                      );
                    },
                    minValue: 1,
                    maxValue: 100,
                  ),
                  _buildIntInputSetting(
                    // Max Output Tokens
                    context,
                    ref: ref,
                    label: 'Max Output Tokens',
                    value: settings.maxOutputTokens,
                    onChanged: (val) {
                      ref
                          .read(settingsServiceProvider)
                          .setMaxOutputTokens(val.toInt());
                      settingsServiceProvider.overrideWith(
                        (ref) => settingsService,
                      );
                    },
                    minValue: 1,
                    maxValue: 100000, // Example reasonable max
                  ),
                  const SizedBox(height: 10),
                ],
                const Divider(
                  height: 1,
                  color: Color.fromARGB(255, 97, 97, 97),
                ),
                const SizedBox(height: 10),

                // === Advanced Settings Section ===
                _buildSectionHeader(
                  'Advanced settings',
                  _advancedExpanded,
                  () => setState(() => _advancedExpanded = !_advancedExpanded),
                ),
                if (_advancedExpanded) ...[
                  // Add Stop Sequences Input etc.
                  _buildTextFieldSetting(
                    ref: ref,
                    initialValue:
                        "", // How are stop sequences stored in settings? Assume a comma-separated string
                    label: "Stop sequences",
                    hint: "e.g., User:, AI:",
                    saveAction: (val) {
                      // TODO: Update settings service with stop sequences logic
                      // Example: ref.read(settingsServiceProvider).setStopSequences(val.split(',').map((s)=>s.trim()).toList());
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                const Divider(
                  height: 1,
                  color: Color.fromARGB(255, 97, 97, 97),
                ),
                const SizedBox(height: 10),

                // === Safety Settings Section (Placeholder) ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Safety settings',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    TextButton(
                      onPressed: () {
                        /* TODO: Implement Safety Settings */
                      },
                      child: const Text('Edit'),
                      style: TextButton.styleFrom(
                        minimumSize: Size(40, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // === Tools Section (Placeholder based on Switch from SettingsPage) ===
                SwitchListTile(
                  title: const Text(
                    'Enable Model Tools',
                  ), // Match label from SettingsPage
                  dense: true, // Make it more compact
                  contentPadding: EdgeInsets.zero, // Remove default padding
                  value:
                      !settings
                          .turnofftools, // Use the setting value (inverted logic)
                  onChanged: (val) {
                    ref.read(settingsServiceProvider).setTurnofftools(val);
                    settingsServiceProvider.overrideWith(
                      (ref) => settingsService,
                    );
                  },
                  // Style based on your theme
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Confirmation Dialog for Reset --- (Moved from SettingsPage)
  void _confirmResetSettings(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Reset Run Settings?'),
            content: const Text(
              'Reset Model, Temperature, Top P, Top K, Max Tokens, and Advanced options (like Stop Sequences) to defaults?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                onPressed: () {
                  try {
                    resetSuccess() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('settings Successfully reset!'),
                      ),
                    );
                  }
                  } catch (e) {
                    debugPrint("Error resetting settings: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error resetting settings.'),
                      ),
                    );
                    
                  }
                  Navigator.of(ctx).pop();
                  
                },
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }

  // --- Helper Widgets (Adapted from SettingsPage) ---

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    String tooltip, {
    VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.grey[400], size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 20,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
    );
  }

  Widget _buildSectionHeader(
    String title,
    bool isExpanded,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[300],
              ),
            ),
            Icon(
              isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // Slider with Label and Value Display
  Widget _buildSliderSetting(
    BuildContext context, {
    required WidgetRef ref,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue, // Separate display value string
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey[400])),
          ), // Fixed width label
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: displayValue, // Label on slider thumb (can be verbose)
              onChanged: onChanged,
            ),
          ),
          Container(
            // Value display box
            width: 45,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[700]?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(displayValue, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // Int Input with Label (using helper from SettingsPage)
  Widget _buildIntInputSetting(
    BuildContext context, {
    required WidgetRef ref,
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int minValue = 0,
    int? maxValue,
  }) {
    // Reusing the validated input logic
    return StatefulBuilder(
      builder: (context, setState) {
        final controller = TextEditingController(text: value.toString());
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(label, style: TextStyle(color: Colors.grey[400])),
              ),
              Expanded(
                child: SizedBox(width: 60),
              ), // Spacer to push input right
              SizedBox(
                width: 70, // Width for input field
                height: 35, // Control height
                child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.center, // Center text
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                    ), // Adjust padding
                    filled: true,
                    fillColor: Colors.grey[700]?.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onFieldSubmitted: (newValue) {
                    final intVal = int.tryParse(newValue);
                    if (intVal != null) {
                      int finalVal = intVal.clamp(
                        minValue,
                        maxValue ?? 999999,
                      ); // Apply clamp
                      onChanged(finalVal);
                      if (finalVal.toString() != controller.text) {
                        controller.text = finalVal.toString();
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                      }
                    } else {
                      controller.text = value.toString();
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                    }
                  },
                  onEditingComplete: () {
                    // Also save on losing focus
                    final intVal = int.tryParse(controller.text);
                    if (intVal != null) {
                      int finalVal = intVal.clamp(minValue, maxValue ?? 999999);
                      if (finalVal != value)
                        onChanged(finalVal); // Only call if changed
                      if (finalVal.toString() != controller.text) {
                        controller.text = finalVal.toString();
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                      }
                    } else {
                      controller.text = value.toString();
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                    }
                    FocusScope.of(context).unfocus(); // Hide keyboard
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Text Input Helper (reused)
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
    return StatefulBuilder(
      builder: (context, setState) {
        final controller = TextEditingController(text: initialValue);
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            obscureText: obscureText,
            maxLines: maxLines,
            minLines: minLines,
            keyboardType: keyboardType,
            // Save on focus lost
            onEditingComplete: () {
              saveAction(controller.text.trim());
              FocusScope.of(context).unfocus();
            },
          ),
        );
      },
    );
  }

  // Dropdown Helper (reused)
  Widget _buildDropdownSetting<T>({
    required WidgetRef ref,
    required String label,
    required T? value, // Value can be null if no selection/empty list
    required List<T> items,
    required ValueChanged<T?> onSelected,
    String? hintWhenEmpty,
  }) {
    bool isEmpty = items.isEmpty;
    // Ensure value is valid within items if list is not empty
    final effectiveValue =
        (!isEmpty && value != null && items.contains(value)) ? value : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownMenu<T>(
        label: Text(label),
        initialSelection: value,
        enabled: !isEmpty,
        hintText:
            isEmpty
                ? hintWhenEmpty
                : (effectiveValue == null ? "Select..." : null),
        width:
            MediaQuery.of(context).size.width *
            0.8, // Adjust width based on panel size if needed
        dropdownMenuEntries:
            items
                .map(
                  (item) =>
                      DropdownMenuEntry<T>(value: item, label: item.toString()),
                )
                .toList(),
        onSelected: onSelected,
      ),
    );
  }
} // End of _RightSettingsPanelState
