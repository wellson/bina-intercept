import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<String?> getApiUrl() async {
    return localDataSource.getApiUrl();
  }

  @override
  Future<void> saveApiUrl(String url) async {
    await localDataSource.saveApiUrl(url);
  }

  @override
  Future<int?> getSyncInterval() async {
    return localDataSource.getSyncInterval();
  }

  @override
  Future<void> saveSyncInterval(int interval) async {
    await localDataSource.saveSyncInterval(interval);
  }

  @override
  Future<String?> getBinaId() async {
    return localDataSource.getBinaId();
  }

  @override
  Future<void> saveBinaId(String id) async {
    await localDataSource.saveBinaId(id);
  }

  @override
  Future<bool> getSyncEnabled() async {
    return localDataSource.getSyncEnabled();
  }

  @override
  Future<void> saveSyncEnabled(bool isEnabled) async {
    await localDataSource.saveSyncEnabled(isEnabled);
  }
}
