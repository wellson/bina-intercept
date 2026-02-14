import '../entities/call_log.dart';

abstract class CallRepository {
  Future<List<CallLog>> getCalls();
  Stream<List<CallLog>> watchCalls();
  Future<void> addCall(CallLog call);
  Future<void> deleteCall(int id);
  Future<void> updateSyncStatus(int id, bool isSynced);
  Future<void> deleteAllCalls();
}
