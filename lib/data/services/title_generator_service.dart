// lib/data/services/title_generator_service.dart
import 'dart:convert';
import 'package:flutter/material.dart'; // For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:jinu/presentation/providers/settings_provider.dart';
// Potentially import settings_provider if API key/model comes from there
// import '../../presentation/providers/settings_provider.dart';

class TitleGeneratorService {
    final container = ProviderContainer();
    late final settingsService = container.read(settingsServiceProvider);
    late final _endpoint = settingsService.customapiurl;
    late final _apiKey = settingsService.apitokenmain;
    late final _model = settingsService.autotitlemodel;

    // Either remove the constructor since you're using settingsService
    // Or properly implement it and use the parameters
    // TitleGeneratorService() {
    //     // Empty constructor since we're using settingsService
    // }

    // OR if you want to use the parameters:
    TitleGeneratorService({required String firstUserMessage, required String title_model}) {
        firstUserMessage = firstUserMessage;
        title_model = title_model;
    //     // You'll need to handle _endpoint as well
    // }
    }

    // ignore: empty_constructor_bodies
    Future<String> generateTitle(String firstUserMessage) async {
        if (_apiKey.isEmpty || _apiKey == "YOUR_OPENAI_API_KEY") {
            debugPrint("WARN: OpenAI API Key not set for title generation.");
            return "New Chat"; // Sensible fallback
        } else if (_model.isEmpty) {
            debugPrint("WARN: Title generation model not set.");
            return "New Chat"; // Sensible fallback
        }

        // Sanitize input slightly
        final cleanMessage = firstUserMessage.trim().replaceAll('\n', ' ');
        if (cleanMessage.isEmpty) {
            return "New Chat";
        }

        final payload = {
            "model": _model, // Use the configured model
            "messages": [
                {"role": "system", "content": "Generate a concise, relevant chat title (max 5-7 words) based on the user's message. Output only the title text, nothing else."},
                {"role": "user", "content": cleanMessage} // Use cleaned message
            ],
            "temperature": 0.3, // Lower temp for more predictable titles
            "max_tokens": 20, // Generous buffer for title
            "n": 1,
            "stop": ["\n"] // Stop at newline if model adds one
        };

        try {
            debugPrint("Generating title with model: $_model");
            final response = await http.post(
                Uri.parse(_endpoint),
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": "Bearer $_apiKey",
                },
                body: json.encode(payload),
            ).timeout(const Duration(seconds: 15)); // Add timeout

            if (response.statusCode == 200) {
                final data = json.decode(utf8.decode(response.bodyBytes)); // Handle UTF8
                String title = data['choices'][0]['message']['content']?.trim() ?? "Chat";

                // Aggressive cleanup of unwanted model additions
                title = title.replaceAll(RegExp(r'^"|"$'), ''); // Remove surrounding quotes
                title = title.replaceAll(RegExp(r'^\*+|\*+$'), ''); // Remove surrounding asterisks
                title = title.replaceAll(RegExp(r'^Title:\s*', caseSensitive: false), ''); // Remove "Title:" prefix
                title = title.replaceAll(RegExp(r'\.$'), ''); // Remove trailing period

                if (title.isEmpty || title.toLowerCase() == 'chat') {
                    // Fallback if empty or generic after cleanup
                    return firstUserMsgTitleFallback(cleanMessage); // Use a better fallback
                }

                return title;
            } else {
                debugPrint("Error generating title: ${response.statusCode} - ${response.body}");
                return firstUserMsgTitleFallback(cleanMessage); // Fallback on API error
            }
        } catch (e) {
            debugPrint("Failed to call OpenAI API for title: $e");
            return firstUserMsgTitleFallback(cleanMessage); // Fallback on exception
        }
    }

    // Simple fallback title based on first few words
    String firstUserMsgTitleFallback(String message) {
        var words = message.split(' ');
        if (words.length <= 5) {
            return message.isEmpty ? "New Chat" : message;
        } else {
            return '${words.sublist(0, 5).join(' ')}...';
        }
    }
}