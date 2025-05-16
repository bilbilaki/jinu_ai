class AppSettings {
  final String? selectedModel;
  final double temperature;
  final bool structuredOutput;
  final bool codeExecution;
  final bool functionCalling;
  final bool groundingSearch;
  // Add other settings...

  AppSettings({
    this.selectedModel = '', // Default
    this.temperature = 1.0,
    this.structuredOutput = false,
    this.codeExecution = false,
    this.functionCalling = false,
    this.groundingSearch = false,
  });

  AppSettings copyWith({
    String? selectedModel,
    double? temperature,
    bool? structuredOutput,
    bool? codeExecution,
    bool? functionCalling,
    bool? groundingSearch,
  }) {
    return AppSettings(
      selectedModel: selectedModel ?? this.selectedModel,
      temperature: temperature ?? this.temperature,
      structuredOutput: structuredOutput ?? this.structuredOutput,
      codeExecution: codeExecution ?? this.codeExecution,
      functionCalling: functionCalling ?? this.functionCalling,
      groundingSearch: groundingSearch ?? this.groundingSearch,
    );
  }
}