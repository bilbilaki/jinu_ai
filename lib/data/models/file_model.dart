import 'dart:io';

class FileModel {
  final File file;
  final String? mimeType;
  final String? name;
  final DateTime? creationDate;
  final int? size;
  final String? path;
  final bool isImage;
  final bool isAudio;
  final bool isVideo;

  FileModel({
    required this.file,
    this.mimeType,
    this.name,
    this.creationDate,
    this.size,
    this.path,
    this.isImage = false,
    this.isAudio = false,
    this.isVideo = false,
  });

  factory FileModel.fromFile(File file, {String? mimeType}) {
    final path = file.path;
    final fileName = path.split('/').last;
    final fileStat = file.statSync();

    // Determine file type based on mimeType or extension
    final isImage = mimeType?.startsWith('image/') ?? false;
    final isAudio = mimeType?.startsWith('audio/') ?? false;
    final isVideo = mimeType?.startsWith('video/') ?? false;

    return FileModel(
      file: file,
      mimeType: mimeType,
      name: fileName,
      creationDate: fileStat.modified,
      size: fileStat.size,
      path: path,
      isImage: isImage,
      isAudio: isAudio,
      isVideo: isVideo,
    );
  }

  // Helper method to check if file is supported
  bool get isSupported => isImage || isAudio || isVideo;

  // Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'mimeType': mimeType,
      'size': size,
      'creationDate': creationDate?.toIso8601String(),
      'isImage': isImage,
      'isAudio': isAudio,
      'isVideo': isVideo,
    };
  }

  // Create from map for deserialization
  factory FileModel.fromMap(Map<String, dynamic> map) {
    return FileModel(
      file: File(map['path']),
      mimeType: map['mimeType'],
      name: map['name'],
      size: map['size'],
      creationDate: DateTime.parse(map['creationDate']),
      path: map['path'],
      isImage: map['isImage'],
      isAudio: map['isAudio'],
      isVideo: map['isVideo'],
    );
  }

  @override
  String toString() {
    return 'FileModel(name: $name, mimeType: $mimeType, size: $size, isImage: $isImage, isAudio: $isAudio, isVideo: $isVideo)';
  }
}