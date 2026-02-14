abstract class SettingsRepository {
  Future<String?> getApiUrl();
  Future<void> saveApiUrl(String url);
  Future<int?> getSyncInterval();
  Future<void> saveSyncInterval(int interval);
  Future<String?> getBinaId();
  Future<void> saveBinaId(String id);
  Future<bool> getSyncEnabled();
  Future<void> saveSyncEnabled(bool isEnabled);
}
