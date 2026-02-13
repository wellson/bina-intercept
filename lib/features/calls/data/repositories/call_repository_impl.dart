import 'package:drift/drift.dart';

import '../../domain/entities/call_log.dart';
import '../../domain/repositories/call_repository.dart';
import '../../../../core/database/app_database.dart';

class CallRepositoryImpl implements CallRepository {
  final AppDatabase _database;

  CallRepositoryImpl(this._database);

  @override
  Future<List<CallLog>> getCalls() async {
    final calls = await _database.getAllCalls();
    return calls.map((c) => CallLog(
      id: c.id,
      phoneNumber: c.phoneNumber,
      source: c.source == 'whatsapp' ? CallSource.whatsapp : CallSource.cellular,
      timestamp: c.timestamp,
    )).toList();
  }

  @override
  Stream<List<CallLog>> watchCalls() {
    return _database.watchAllCalls().map((calls) => calls.map((c) => CallLog(
          id: c.id,
          phoneNumber: c.phoneNumber,
          source: c.source == 'whatsapp' ? CallSource.whatsapp : CallSource.cellular,
          timestamp: c.timestamp,
        )).toList());
  }

  @override
  Future<void> addCall(CallLog call) async {
    await _database.insertCall(
      CallsCompanion(
        phoneNumber: Value(call.phoneNumber),
        source: Value(call.source == CallSource.whatsapp ? 'whatsapp' : 'cellular'),
        timestamp: Value(call.timestamp),
      ),
    );
  }

  @override
  Future<void> deleteCall(int id) async {
    await _database.deleteCall(id);
  }
}
