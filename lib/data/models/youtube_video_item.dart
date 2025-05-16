// lib/data/models/youtube_video_item.dart
// import 'package:googleapis/youtube/v3.dart' as youtube;
// class YouTubeVideoItem {
//   final String? videoId;
//   final String? title;
//   final String? description;
//   final String? channelTitle;
//   final String? thumbnailUrl;
//   final DateTime? publishedAt;

//   YouTubeVideoItem({
//     this.videoId,
//     this.title,
//     this.description,
//     this.channelTitle,
//     this.thumbnailUrl,
//     this.publishedAt,
//   });

//   factory YouTubeVideoItem.fromGoogleApiSearchResult(youtube.SearchResult searchResult) {
//     return YouTubeVideoItem(
//       videoId: searchResult.id?.videoId,
//       title: searchResult.snippet?.title,
//       description: searchResult.snippet?.description,
//       channelTitle: searchResult.snippet?.channelTitle,
//       thumbnailUrl: searchResult.snippet?.thumbnails?.default_?.url,
//       publishedAt: searchResult.snippet?.publishedAt,
//     );
//   }

//   // toJson and fromJson if you need to serialize/deserialize these simple models
//   Map<String, dynamic> toJson() => {
//         'videoId': videoId,
//         'title': title,
//         'description': description,
//         'channelTitle': channelTitle,
//         'thumbnailUrl': thumbnailUrl,
//         'publishedAt': publishedAt?.toIso8601String(),
//       };
  
//   factory YouTubeVideoItem.fromJson(Map<String, dynamic> json) {
//     return YouTubeVideoItem(
//       videoId: json['videoId'],
//       title: json['title'],
//       description: json['description'],
//       channelTitle: json['channelTitle'],
//       thumbnailUrl: json['thumbnailUrl'],
//       publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt']) : null,
//     );
//   }
// }