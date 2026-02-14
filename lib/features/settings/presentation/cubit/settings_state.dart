part of 'settings_cubit.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final String apiUrl;
  final int syncInterval;
  final String binaId;
  final bool isSyncEnabled;

  const SettingsLoaded({
    required this.apiUrl,
    required this.syncInterval,
    required this.binaId,
    required this.isSyncEnabled,
  });

  @override
  List<Object> get props => [apiUrl, syncInterval, binaId, isSyncEnabled];
}

class SettingsSaved extends SettingsState {}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object> get props => [message];
}
