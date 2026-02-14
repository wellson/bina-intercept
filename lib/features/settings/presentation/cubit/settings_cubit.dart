import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/settings_repository.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository repository;

  SettingsCubit(this.repository) : super(SettingsInitial());

  Future<void> loadSettings() async {
    emit(SettingsLoading());
    try {
      final apiUrl = await repository.getApiUrl();
      final syncInterval = await repository.getSyncInterval();
      final binaId = await repository.getBinaId();
      final isSyncEnabled = await repository.getSyncEnabled();
      emit(SettingsLoaded(
        apiUrl: apiUrl ?? '',
        syncInterval: syncInterval ?? 15,
        binaId: binaId ?? '',
        isSyncEnabled: isSyncEnabled,
      ));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> saveSettings(String apiUrl, int syncInterval, String binaId, bool isSyncEnabled) async {
    emit(SettingsLoading());
    try {
      await repository.saveApiUrl(apiUrl);
      await repository.saveSyncInterval(syncInterval);
      await repository.saveBinaId(binaId);
      await repository.saveSyncEnabled(isSyncEnabled);
      emit(SettingsSaved());
      // Reload to show updated values
      loadSettings();
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
