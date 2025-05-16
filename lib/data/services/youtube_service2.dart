import 'dart:developer';

import 'package:youtube_results/youtube_results.dart';

class YouTubeService {
  final YoutubeResults _youtube;

  YouTubeService() : _youtube = YoutubeResults();

  /// Search videos by query with optional maxResults
  Future<Map<String, dynamic>> searchVideos({required String query, int maxResults = 10}) async {
    if (query.isEmpty) {
      return {'status': 'Error', 'message': 'Query cannot be empty.', 'data': {'videos': []}};
    }
    try {
      List<Video>? videos = await _youtube.fetchVideos(query);
      if (videos == null) {
        return {'status': 'Error', 'message': 'No videos found.', 'data': {'videos': []}};
      }
      // Limit results to maxResults
      final limitedVideos = videos.take(maxResults).toList();
      // Map videos to a simple serializable format
      final videoList = limitedVideos.map((video) => {
            'title': video.title,
            'videoId': video.videoId,
            'duration': video.duration,
            'viewCount': video.viewCount,
            'publishedTime': video.publishedTime,
            'channelName': video.channelName,
            'channelUrl': video.channelUrl,
            'description': video.description,
            'thumbnailUrl': video.thumbnails?.isNotEmpty == true ? video.thumbnails![0].url : null,
          }).toList();

      return {'status': 'Success', 'message': 'Videos fetched successfully.', 'data': {'videos': videoList}};
    } catch (e, st) {
      log('Error in searchVideos: $e\n$st');
      return {'status': 'Error', 'message': e.toString(), 'data': {'videos': []}};
    }
  }

  /// Get video info by videoId
  Future<Map<String, dynamic>> getVideoInfo({required String videoId}) async {
    if (videoId.isEmpty) {
      return {'status': 'Error', 'message': 'Video ID cannot be empty.'};
    }
    try {
      VideoInfo? videoInfo = await _youtube.fetchVideoInfo(videoId);
      if (videoInfo == null) {
        return {'status': 'Error', 'message': 'Video info not found.'};
      }
      return {
        'status': 'Success',
        'message': 'Video info fetched successfully.',
        'data': {
          'title': videoInfo.title,
          'publishedTime': videoInfo.publishedTime,
          'viewCount': videoInfo.viewCount,
          'likes': videoInfo.likes,
          'channelName': videoInfo.channelName,
          'channelId': videoInfo.channelId,
          'channelUrl': videoInfo.url,
          'subscriptionCount': videoInfo.subscriptionCount,
          'description': videoInfo.description,
          'channelThumbnailUrl': videoInfo.channelThumbnails?.isNotEmpty == true ? videoInfo.channelThumbnails![0].url : null,
          'itemsCount': videoInfo.items?.length ?? 0,
        }
      };
    } catch (e, st) {
      log('Error in getVideoInfo: $e\n$st');
      return {'status': 'Error', 'message': e.toString()};
    }
  }

  /// Get video comments by videoId
  /// Note: The youtube_results package may not support comments directly.
  /// This method returns a not implemented error for now.
  Future<Map<String, dynamic>> getVideoComments({required String videoId}) async {
    return {'status': 'Error', 'message': 'getVideoComments is not implemented in the current service.'};
  }

  /// List playlist items by playlistId
  Future<Map<String, dynamic>> listPlaylistItems({required String playlistId}) async {
    if (playlistId.isEmpty) {
      return {'status': 'Error', 'message': 'Playlist ID cannot be empty.'};
    }
    try {
      PlaylistInfo? playlistInfo = await _youtube.fetchPlaylistInfo(playlistId);
      if (playlistInfo == null) {
        return {'status': 'Error', 'message': 'Playlist info not found.'};
      }
      final items = playlistInfo.items?.map((item) => {
            'title': item.title,
            'videoId': item.videoId,
            'duration': item.duration,
            'thumbnailUrl': item.thumbnails?.isNotEmpty == true ? item.thumbnails![0].url : null,
          }).toList() ?? [];

      return {
        'status': 'Success',
        'message': 'Playlist items fetched successfully.',
        'data': {
          'title': playlistInfo.title,
          'videoCount': playlistInfo.videoCount,
          'items': items,
        }
      };
/// Add video to playlist by videoId and playlistId
  /// Note: The youtube_results package may not support this directly.
  /// This method returns a not implemented error for now.
  Future<Map<String, dynamic>> addVideoToPlaylist({required String videoId, required String playlistId}) async {
    return {'status': 'Error', 'message': 'addVideoToPlaylist is not implemented in the current service.'};
  }
    } catch (e, st) {
      log('Error in listPlaylistItems: $e\n$st');
      return {'status': 'Error', 'message': e.toString()};
    }
  }

  /// List video captions by videoId
  /// Note: The youtube_results package may not support captions directly.
  /// This method returns a not implemented error for now.
  Future<Map<String, dynamic>> listVideoCaptions({required String videoId}) async {
    return {'status': 'Error', 'message': 'listVideoCaptions is not implemented in the current service.'};
  }

  /// Download caption track by captionId
  /// Note: The youtube_results package may not support caption downloads directly.
  /// This method returns a not implemented error for now.
  Future<Map<String, dynamic>> downloadCaptionTrack({required String captionId}) async {
    return {'status': 'Error', 'message': 'downloadCaptionTrack is not implemented in the current service.'};
  }

  /// Close any resources if needed (placeholder)
  void closeOAuthClient() {
    // No OAuth client to close in this implementation
  }
}