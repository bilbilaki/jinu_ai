import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/app_settings.dart';
import '../../repositories/settings_repository.dart';

class UpdateSettings {
  final SettingsRepository repository;

  UpdateSettings(this.repository);

  Future<Either<Failure, void>> call(AppSettings settings) async {
    return await repository.updateSettings(settings);
  }
}