import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../domain/entities/call_log.dart';
import '../../domain/repositories/call_repository.dart';

part 'call_state.dart';

class CallCubit extends Cubit<CallState> {
  final CallRepository _repository;
  StreamSubscription? _callSubscription;
  Timer? _pollingTimer;

  CallCubit(this._repository) : super(CallInitial()) {
    _monitorCalls();
    
    // Listen for background sync events to refresh UI
    FlutterBackgroundService().on('sync_completed').listen((_) {
      print('CallCubit: Received sync_completed event from background');
      // Re-fetch calls to update UI (e.g. isSynced status)
      _monitorCalls();
    });
    
    // Fallback: Poll every 5 seconds if there are unsynced calls
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final currentState = state;
      if (currentState is CallLoaded) {
        // Only refresh if we have unsynced calls
        if (currentState.calls.any((c) => !c.isSynced)) {
             print('CallCubit: Polling for updates (fallback)...');
            _monitorCalls();
        }
      }
    });
  }

  void _monitorCalls() {
    print('CallCubit: Monitoring calls (refreshing stream)');
    // We don't want to show loading every time we refresh in background
    // emit(CallLoading()); 
    // Actually, if we re-listen to stream, it might not emit immediately?
    // Let's keep existing logic but removing explicit CallLoading emission 
    // on updates to avoid flickering if we want smooth updates. 
    // BUT for now, let's keep it simple.
    
    _callSubscription?.cancel();
    _callSubscription = _repository.watchCalls().listen(
      (calls) => emit(CallLoaded(calls)),
      onError: (error) => emit(CallError(error.toString())),
    );
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    _callSubscription?.cancel();
    return super.close();
  }

  Future<void> loadCalls() async {
     // No-op or manual refresh if needed, but stream handles it.
     // Kept for compatibility.
  }

  Future<void> addCall(CallLog call) async {
    try {
      await _repository.addCall(call);
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> deleteCall(int id) async {
    try {
      await _repository.deleteCall(id);
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> toggleSyncStatus(int id, bool currentStatus) async {
    try {
      // If current status is true (synced), we set to false (unsynced) to retry.
      // If current status is false (unsynced), we could set to true (manual sync mark),
      // but usually user wants to retry, so toggling is fine.
      await _repository.updateSyncStatus(id, !currentStatus);
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> clearHistory() async {
    try {
      await _repository.deleteAllCalls();
      // The watcher stream should automatically update the UI, 
      // but if we want to be sure we can emit loading.
      // Since it's a stream, standard practice implies we just wait for the db update.
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }
}
