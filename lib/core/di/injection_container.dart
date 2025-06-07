import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Domain
import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/media_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/chat/send_message.dart';
import '../../domain/usecases/chat/get_chat_history.dart';
import '../../domain/usecases/media/generate_image.dart';
import '../../domain/usecases/media/generate_audio.dart';
import '../../domain/usecases/settings/get_settings.dart';
import '../../domain/usecases/settings/update_settings.dart';

// Data
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/repositories/media_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/datasources/ai_remote_datasource.dart';
import '../../data/datasources/ai_local_datasource.dart';
import '../../data/datasources/media_remote_datasource.dart';
import '../../data/datasources/settings_local_datasource.dart';

// Presentation
import '../../presentation/blocs/theme/theme_cubit.dart';
import '../../presentation/blocs/navigation/navigation_cubit.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../../presentation/blocs/media/media_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());

  // Data sources
  sl.registerLazySingleton<AIRemoteDataSource>(
    () => AIRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AILocalDataSource>(
    () => AILocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<MediaRemoteDataSource>(
    () => MediaRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AIRepository>(
    () => AIRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<MediaRepository>(
    () => MediaRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(localDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => GetChatHistory(sl()));
  sl.registerLazySingleton(() => GenerateImage(sl()));
  sl.registerLazySingleton(() => GenerateAudio(sl()));
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerLazySingleton(() => UpdateSettings(sl()));

  // BLoCs
  sl.registerFactory(() => ThemeCubit(
    getSettings: sl(),
    updateSettings: sl(),
  ));
  sl.registerFactory(() => NavigationCubit());
  sl.registerFactory(() => ChatBloc(
    sendMessage: sl(),
    getChatHistory: sl(),
  ));
  sl.registerFactory(() => MediaBloc(
    generateImage: sl(),
    generateAudio: sl(),
  ));
}