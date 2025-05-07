import 'dart:convert';
import 'dart:typed_data';
// import 'dart:ui' as ui; // Not used, can be removed
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart'; // Not strictly needed for direct gallery save
// import 'dart:io'; // Not strictly needed for direct gallery save
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:device_info_plus/device_info_plus.dart';
class ImageGenerationDrawer extends StatefulWidget {
  @override
  _ImageGenerationDrawerState createState() => _ImageGenerationDrawerState();
}

class _ImageGenerationDrawerState extends State<ImageGenerationDrawer> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativePromptController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController(text: ""); // Default empty

  String _selectedModel = "stabilityai/stable-diffusion-3.5-large";
  bool _isLoading = false;
  Uint8List? _generatedImage;

  final List<String> _availableModels = [
    "stabilityai/stable-diffusion-3.5-large",
    "stabilityai/stable-diffusion-3-medium-diffusers",
    "black-forest-labs/FLUX.1-dev",
    "Kwai-Kolors/Kolors",
    "latent-consistency/lcm-lora-sdxl",
  ];

  // Removed saveLocalImage as ImageGallerySaver.saveImage can take Uint8List directly.

  Future<void> _generateImage() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a prompt")));
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedImage = null; // Clear previous image if any
    });

    try {
      final Map<String, dynamic> requestData = {
        "inputs": {"prompt": _promptController.text},
      };

      if (_negativePromptController.text.isNotEmpty) {
        requestData["inputs"]["negative_prompt"] = _negativePromptController.text;
      }

      if (_stepsController.text.isNotEmpty) {
        final steps = int.tryParse(_stepsController.text);
        if (steps != null && steps > 0) { // Added validation for steps
          requestData["inputs"]["num_inference_steps"] = steps;
        } else if (_stepsController.text.isNotEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid value for steps.")));
           setState(() => _isLoading = false);
           return;
        }
      }

      final response = await http.post(
        Uri.parse('https://router.huggingface.co/hf-inference/models/$_selectedModel'),
        headers: {
          'Authorization': 'Bearer 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', // Replace with your actual token
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        setState(() {
          _generatedImage = response.bodyBytes;
          _isLoading = false;
        });
        _showImageDialog();
      } else {
        setState(() => _isLoading = false); // Ensure loading state is reset on error
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to generate image: ${response.statusCode} ${response.reasonPhrase}\nBody: ${response.body.length > 200 ? response.body.substring(0,200) + "..." : response.body }'), // Show more details
          duration: Duration(seconds: 5),
        ));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<void> _saveImage() async {
    if (_generatedImage == null) return;

    try {
      // Request permission. For Android 10+ saving to gallery often doesn't need explicit
      // WRITE_EXTERNAL_STORAGE if the plugin uses MediaStore.
      // Permission.storage is a general one. For photos, Permission.photos (on newer APIs) might be more specific.
      // image_gallery_saver's documentation suggests no permission needed for API 29+.
      // However, it's good to request to cover older versions or specific plugin behavior.
      var status = await Permission.storage.request(); // For older Android
      if (TargetPlatform.android == defaultTargetPlatform) { // More specific for Android 13+
          final androidInfo = await DeviceInfoPlugin().androidInfo; // You'll need device_info_plus package
          if (androidInfo.version.sdkInt >= 33) { // Android 13+
              status = await Permission.photos.request();
          }
      } else if (TargetPlatform.iOS == defaultTargetPlatform) {
          status = await Permission.photos.request(); // For iOS, NSPhotoLibraryAddUsageDescription
      }


      if (status.isGranted) {
        final result = await ImageGallerySaver.saveImage(
          _generatedImage!,
          quality: 90, // Optional: quality from 0 to 100
          name: "ai_image_${DateTime.now().millisecondsSinceEpoch}", // Optional: filename
        );

        if (kDebugMode) {
          print(result); // result is a Map, e.g., {isSuccess: true, filePath: "path_to_file_if_successful"}
        }

        if (result != null && result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Image saved to gallery! Path: ${result['filePath'] ?? ''}")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to save image to gallery. Error: ${result?['errorMessage'] ?? 'Unknown error'}")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Photo Library or Storage permission denied")));
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error saving image: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save image: ${e.toString()}")),
      );
    }
  }

  void _showImageDialog() {
    if (_generatedImage == null) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important for Dialog content sizing
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                // Use InteractiveViewer for pinch-to-zoom if desired
                child: InteractiveViewer( // Added for better image viewing
                  panEnabled: false, // Set it to true if you want to allow panning
                  boundaryMargin: EdgeInsets.all(10),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.memory(_generatedImage!, fit: BoxFit.scaleDown),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0), // Added horizontal padding
                child: ElevatedButton(
                  onPressed: _saveImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary, // Use theme color
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: Size(double.infinity, 48), // Make button wider
                  ),
                  child: Text('Save Image'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width > 450
          ? 300 // Max width for larger screens
          : MediaQuery.of(context).size.width * 0.70, // Percentage for smaller
      child: Drawer(
        child: Padding( // Changed Container to Padding for semantics
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: SingleChildScrollView( // <<<<----- SOLUTION FOR OVERFLOW
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch horizontally
              children: [
                Text(
                  "AI Image Generator",
                  style: Theme.of(context).textTheme.headlineSmall, // Use themed text style
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20), // Increased spacing
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Model",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedModel,
                  isExpanded: true, // Allows the dropdown text to use available width
                  items: _availableModels.map((String model) {
                    return DropdownMenuItem<String>(
                      value: model,
                      child: Text(
                        model.split('/').last, // Show only the model name
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue.isNotEmpty) { // Check for null and empty
                      setState(() {
                        _selectedModel = newValue;
                      });
                    }
                  },
                ),
                SizedBox(height: 16), // Standardized spacing
                TextField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    labelText: "Prompt *",
                    hintText: "Describe what you want to generate",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _negativePromptController,
                  decoration: InputDecoration(
                    labelText: "Negative Prompt (optional)",
                    hintText: "What to avoid in the image",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _stepsController,
                  decoration: InputDecoration(
                    labelText: "Steps (optional, e.g., 25)",
                    hintText: "Number of inference steps (1-100)",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 24), // Increased spacing before button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateImage,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white, // Ensure spinner is visible
                          ),
                        )
                      : Icon(Icons.image_outlined), // Changed icon
                  label: Text(_isLoading ? "Generating..." : "Generate Image"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
                // Spacer(), // Spacer might not be ideal with SingleChildScrollView unless you want image at very bottom
                SizedBox(height: 20), // Space before potential preview
                if (_generatedImage != null)
                  Column( // Wrap preview in a Column for better structure
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Preview:", style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 8),
                      Container(
                        height: 200, // Give a fixed height or make it adaptive
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: _showImageDialog,
                          child: ClipRRect( // Clip the image to rounded corners
                            borderRadius: BorderRadius.circular(7), // slightly less than container
                            child: Image.memory(_generatedImage!, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// You might need to add device_info_plus to your pubspec.yaml for more specific permission handling on Android 13+
// dependencies:
//   flutter:
//     sdk: flutter
//   http: ^1.2.0 # or latest
//   path_provider: ^2.0.5 # or latest (still useful for other file ops)
//   permission_handler: ^11.0.0 # or latest
//   image_gallery_saver: ^2.0.3 # or latest
//   device_info_plus: ^9.0.0 # or latest (for checking Android SDK version)


// IMPORTANT: Permissions
// 1. For iOS (ios/Runner/Info.plist):
//    <key>NSPhotoLibraryAddUsageDescription</key>
//    <string>This app needs access to your photo library to save generated images.</string>
//
// 2. For Android (android/app/src/main/AndroidManifest.xml):
//    - For Android API 28 (Android 9) and below, image_gallery_saver requires:
//      <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
//    - For Android API 29 (Android 10) and above, usually no permission is needed if the plugin uses MediaStore.
//    - For Android API 33 (Android 13) and above, if you need to READ media, you'd need:
//      <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
//    The `permission_handler` package helps manage these requests at runtime.
//    Ensure your compileSdkVersion and targetSdkVersion in android/app/build.gradle are up-to-date (e.g., 33 or 34).