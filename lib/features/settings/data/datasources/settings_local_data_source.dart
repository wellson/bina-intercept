import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsLocalDataSource {
  Future<String?> getApiUrl();
  Future<void> saveApiUrl(String url);
  Future<int?> getSyncInterval();
  Future<void> saveSyncInterval(int interval);
  Future<String?> getBinaId();
  Future<void> saveBinaId(String id);
  Future<bool> getSyncEnabled();
  Future<void> saveSyncEnabled(bool isEnabled);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences sharedPreferences;

  SettingsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<String?> getApiUrl() async {
    return sharedPreferences.getString('api_url');
  }

  @override
  Future<void> saveApiUrl(String url) async {
    await sharedPreferences.setString('api_url', url);
  }

  @override
  Future<int?> getSyncInterval() async {
    return sharedPreferences.getInt('sync_interval');
  }

  @override
  Future<void> saveSyncInterval(int interval) async {
    await sharedPreferences.setInt('sync_interval', interval);
  }

  @override
  Future<String?> getBinaId() async {
    return sharedPreferences.getString('bina_id');
  }

  @override
  Future<void> saveBinaId(String id) async {
    await sharedPreferences.setString('bina_id', id);
  }

  @override
  Future<bool> getSyncEnabled() async {
    return sharedPreferences.getBool('sync_enabled') ?? true;
  }

  @override
  Future<void> saveSyncEnabled(bool isEnabled) async {
    await sharedPreferences.setBool('sync_enabled', isEnabled);
  }
}
