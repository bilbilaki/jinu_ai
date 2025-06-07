import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/media_content.dart';
import '../../blocs/media/media_bloc.dart';
import '../common/responsive_card.dart';

class MediaGenerationForm extends StatefulWidget {
  const MediaGenerationForm({super.key});

  @override
  State<MediaGenerationForm> createState() => _MediaGenerationFormState();
}

class _MediaGenerationFormState extends State<MediaGenerationForm> {
  final TextEditingController _promptController = TextEditingController();
  MediaContentType _selectedType = MediaContentType.image;
  final Map<String, dynamic> _parameters = {};

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Media',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          _buildTypeSelector(),
          const SizedBox(height: AppConstants.spacingL),
          _buildPromptInput(),
          const SizedBox(height: AppConstants.spacingL),
          _buildParametersSection(),
          const SizedBox(height: AppConstants.spacingXL),
          _buildGenerateButton(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        SegmentedButton<MediaContentType>(
          segments: const [
            ButtonSegment(
              value: MediaContentType.image,
              label: Text('Image'),
              icon: Icon(Icons.image),
            ),
            ButtonSegment(
              value: MediaContentType.audio,
              label: Text('Audio'),
              icon: Icon(Icons.audiotrack),
            ),
          ],
          selected: {_selectedType},
          onSelectionChanged: (Set<MediaContentType> selection) {
            setState(() {
              _selectedType = selection.first;
              _parameters.clear();
            });
          },
        ),
      ],
    );
  }

  Widget _buildPromptInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prompt',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        TextField(
          controller: _promptController,
          maxLines: ResponsiveUtils.responsiveValue(
            mobile: 4,
            tablet: 6,
            desktop: 8,
          ),
          decoration: InputDecoration(
            hintText: _selectedType == MediaContentType.image
                ? 'Describe the image you want to generate...'
                : 'Enter text to convert to speech...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            contentPadding: const EdgeInsets.all(AppConstants.spacingL),
          ),
        ),
      ],
    );
  }

  Widget _buildParametersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parameters',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        if (_selectedType == MediaContentType.image)
          _buildImageParameters()
        else
          _buildAudioParameters(),
      ],
    );
  }

  Widget _buildImageParameters() {
    return Column(
      children: [
        _buildParameterDropdown(
          'Size',
          ['512x512', '1024x1024', '1792x1024', '1024x1792'],
          _parameters['size'] ?? '1024x1024',
          (value) => setState(() => _parameters['size'] = value),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildParameterDropdown(
          'Quality',
          ['standard', 'hd'],
          _parameters['quality'] ?? 'standard',
          (value) => setState(() => _parameters['quality'] = value),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildParameterSlider(
          'Number of Images',
          1,
          4,
          (_parameters['n'] ?? 1).toDouble(),
          (value) => setState(() => _parameters['n'] = value.round()),
        ),
      ],
    );
  }

  Widget _buildAudioParameters() {
    return Column(
      children: [
        _buildParameterDropdown(
          'Voice',
          ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'],
          _parameters['voice'] ?? 'alloy',
          (value) => setState(() => _parameters['voice'] = value),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildParameterDropdown(
          'Model',
          ['tts-1', 'tts-1-hd'],
          _parameters['model'] ?? 'tts-1',
          (value) => setState(() => _parameters['model'] = value),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildParameterDropdown(
          'Format',
          ['mp3', 'opus', 'aac', 'flac'],
          _parameters['response_format'] ?? 'mp3',
          (value) => setState(() => _parameters['response_format'] = value),
        ),
      ],
    );
  }

  Widget _buildParameterDropdown(
    String label,
    List<String> options,
    String value,
    Function(String) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingS,
              ),
            ),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParameterSlider(
    String label,
    double min,
    double max,
    double value,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              value.round().toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        final isGenerating = state.isGenerating;
        final canGenerate = _promptController.text.trim().isNotEmpty && !isGenerating;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canGenerate ? _generateMedia : null,
            icon: isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_selectedType == MediaContentType.image
                    ? Icons.image
                    : Icons.audiotrack),
            label: Text(
              isGenerating
                  ? 'Generating...'
                  : 'Generate ${_selectedType == MediaContentType.image ? 'Image' : 'Audio'}',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
          ),
        );
      },
    );
  }

  void _generateMedia() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    if (_selectedType == MediaContentType.image) {
      context.read<MediaBloc>().add(
            GenerateImageEvent(
              prompt: prompt,
              parameters: _parameters,
            ),
          );
    } else {
      context.read<MediaBloc>().add(
            GenerateAudioEvent(
              prompt: prompt,
              parameters: _parameters,
            ),
          );
    }

    // Clear the prompt after generation
    _promptController.clear();
  }
}