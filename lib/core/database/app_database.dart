import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class Calls extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get phoneNumber => text()();
  TextColumn get source => text()(); // 'cellular' or 'whatsapp'
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get lastError => text().nullable()();
}

@DriftDatabase(tables: [Calls])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(calls, calls.isSynced);
        }
        if (from < 3) {
          await m.addColumn(calls, calls.lastError);
        }
      },
    );
  }

  Future<int> insertCall(CallsCompanion entry) {
    return into(calls).insert(entry);
  }

  Future<List<Call>> getAllCalls() {
    return (select(calls)
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .get();
  }

  Stream<List<Call>> watchAllCalls() {
    return (select(calls)
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<int> deleteCall(int id) {
    return (delete(calls)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateCallSyncStatus(int id, bool isSynced, {String? lastError}) {
    return (update(calls)..where((t) => t.id.equals(id))).write(
      CallsCompanion(
        isSynced: Value(isSynced),
        lastError: Value(lastError),
      ),
    );
  }

  Future<int> deleteAllCalls() {
    return delete(calls).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
