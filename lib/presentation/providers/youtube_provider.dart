// lib/presentation/providers/youtube_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/youtube_service2.dart'; // Adjust path if needed

// Provider for the YouTubeService instance
final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  final service = YouTubeService(
      // You can override API keys here if needed, or they'll use defaults
      // apiKey: 'YOUR_RUNTIME_API_KEY_IF_DIFFERENT',
      // clientId: 'YOUR_RUNTIME_CLIENT_ID_IF_DIFFERENT',
      // clientSecret: 'YOUR_RUNTIME_CLIENT_SECRET_IF_DIFFERENT',
  );

  // If you want to close the OAuth client when the provider is disposed
  // (e.g., if app closes, or if this provider is scoped and its scope ends)
  ref.onDispose(() {
    service.closeOAuthClient();
  });

  return service;
});

// Example of a FutureProvider that calls a specific service method
// This is useful if you want to fetch data and provide it reactively.

// Provider to search videos. It takes a query string.
// This uses family to pass the query.
final searchYouTubeVideosProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, query) async {
  if (query.isEmpty) {
    return {'status': 'Error', 'message': 'Query cannot be empty.', 'data': {'videos': []}};
  }
  final youtubeService = ref.watch(youtubeServiceProvider);
  return youtubeService.searchVideos(query: query, maxResults: 10); // Example maxResults
});

// Provider to get video info. Takes a videoId.
final youtubeVideoInfoProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, videoId) async {
  if (videoId.isEmpty) {
    return {'status': 'Error', 'message': 'Video ID cannot be empty.'};
  }
  final youtubeService = ref.watch(youtubeServiceProvider);
  return youtubeService.getVideoInfo(videoId: videoId);
});

// Add more FutureProvider.family for other methods as needed, e.g.:
 final youtubeVideoCommentsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, videoId) async {
  if (videoId.isEmpty) {
    return {'status': 'Error', 'message': 'Video ID cannot be empty.'};
  }
  final youtubeService = ref.watch(youtubeServiceProvider);
  return youtubeService.getVideoComments(videoId: videoId);
});
 final youtubePlaylistItemsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, playlistId) async {
  if (playlistId.isEmpty) {
    return {'status': 'Error', 'message': 'Playlist ID cannot be empty.'};
  }
  final youtubeService = ref.watch(youtubeServiceProvider);
  return youtubeService.listPlaylistItems(playlistId: playlistId);
});
final youtubeVideoCaptionsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, videoId) async {
  if (videoId.isEmpty) {
    return {'status': 'Error', 'message': 'Video ID cannot be empty.'};
  }
  final youtubeService = ref.watch(youtubeServiceProvider);
  return youtubeService.listVideoCaptions(videoId: videoId);
});
final youtubeVideoCaptionDownloadProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, captionId) async {
  if (captionId.isEmpty) {
    return {'status': 'Error', 'message': 'Video ID cannot be empty.'};
  }
  final youtubeService = ref.watch(youtubeServiceProvider);
  return youtubeService.downloadCaptionTrack(captionId: captionId);
});
