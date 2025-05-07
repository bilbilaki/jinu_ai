
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/file_service.dart';

/// Provides an instance of [FileService].
///
/// This provider manages the lifecycle of the [FileService], including
/// calling its `dispose` method when the provider is no longer in use.
final fileServiceProvider = Provider<FileService>((ref) {
  final fileService = FileService();


  

ref.listen(fileService.cancelRecording as ProviderListenable<Object>, (_, next) {
  if (next == false) {
    fileService.cancelRecording();
  }
});

ref.listen(fileService.saveFileToAppDirectory as ProviderListenable<Object>, (_, next) {
  if (next == false) {
    fileService.saveFileToAppDirectory;
  }
});


// ref.listen(fileService.saveImageToGallery as ProviderListenable<Object>, (_, next) {
//   if (next == false) {
//     fileService.saveImageToGallery;
//   }
// });


ref.listen(fileService.getMimeType as ProviderListenable<Object>, (_, next) {
  if (next == false) {
    fileService.getMimeType;
  }
});


  ref.listen(fileService.stopRecording as ProviderListenable<Object>, (_, next) {
    if (next == false) {
      fileService.stopRecording();
    }
  });

  
  ref.listen(fileService.startRecording as ProviderListenable<Object>, (_, next) {
    fileService.requestMicrophonePermission();
    if (next == false) {
      fileService.startRecording();
    }
  });

  ref.listen(fileService.pickFile as ProviderListenable<Object>, (_, next) {
    fileService.requestStoragePermission();
    if (next == false) {
      fileService.pickFile();
    }
  });

  ref.listen(fileService.pickImageFromGallery as ProviderListenable<Object>, (_, next) {
    fileService.requestCameraPermission();
    if (next == false) {
      fileService.pickImageFromGallery();
    }
  });

  ref.listen(fileService.takePhotoWithCamera as ProviderListenable<Object>, (_, next) {
    fileService.requestCameraPermission();
    if (next == false) {
      fileService.takePhotoWithCamera();
    }
  });

  ref.listen(fileService.requestStoragePermission as ProviderListenable<Object>, (_, next) {
    if (next == false) {
      fileService.requestStoragePermission();
    }
  });

  ref.listen(fileService.requestCameraPermission as ProviderListenable<Object>, (_, next) {
    if (next == false) {
      fileService.requestCameraPermission();
    }
  });
   ref.listen(fileService.requestMicrophonePermission as ProviderListenable<Object>, (_, next) {
    if (next == false) {
      fileService.requestMicrophonePermission();
    }
  });


  // Riverpod automatically calls dispose on objects with a dispose method
  // when the provider is disposed.
   ref.onDispose(() => fileService.dispose()); // This line is not strictly needed if FileService has a dispose() method.

  return fileService;
});