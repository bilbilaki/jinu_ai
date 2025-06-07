import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/app_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      final result = await localDataSource.getSettings();
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSettings(AppSettings settings) async {
    try {
      final settingsModel = AppSettingsModel.fromEntity(settings);
      await localDataSource.saveSettings(settingsModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetSettings() async {
    try {
      await localDataSource.clearSettings();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> exportSettings() async {
    try {
      final settings = await localDataSource.getSettings();
      return Right(settings.toJson());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> importSettings(Map<String, dynamic> settings) async {
    try {
      final settingsModel = AppSettingsModel.fromJson(settings);
      await localDataSource.saveSettings(settingsModel);
      return const Right(null);
    } catch (e) {
      return Left(ValidationFailure(message: e.toString()));
    }
  }
}