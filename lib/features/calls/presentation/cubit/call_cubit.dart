import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/call_log.dart';
import '../../domain/repositories/call_repository.dart';

part 'call_state.dart';

class CallCubit extends Cubit<CallState> {
  final CallRepository _repository;
  StreamSubscription? _callSubscription;

  CallCubit(this._repository) : super(CallInitial()) {
    _monitorCalls();
  }

  void _monitorCalls() {
    emit(CallLoading());
    _callSubscription?.cancel();
    _callSubscription = _repository.watchCalls().listen(
      (calls) => emit(CallLoaded(calls)),
      onError: (error) => emit(CallError(error.toString())),
    );
  }

  @override
  Future<void> close() {
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
}
