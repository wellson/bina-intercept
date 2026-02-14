import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';

class SyncService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    sendTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<void> performSync() async {
    final now = DateTime.now();
    debugPrint('[SyncService] Starting sync process at $now');
    
    // 1. Initialize Database
    final db = AppDatabase();

    try {
      // 2. Read Settings
      final prefs = await SharedPreferences.getInstance();
      final apiUrl = prefs.getString('api_url');
      final binaIdStr = prefs.getString('bina_id');
      final syncInterval = prefs.getInt('sync_interval') ?? 15;
      final isSyncEnabled = prefs.getBool('sync_enabled') ?? true;
      final lastSyncTimestamp = prefs.getInt('last_sync_timestamp') ?? 0;

      debugPrint('[SyncService] Settings loaded: '
          'Enabled=$isSyncEnabled, '
          'Interval=$syncInterval s, '
          'LastSync=$lastSyncTimestamp, '
          'API=$apiUrl, '
          'BinaID=$binaIdStr');

      // 3. Validation
      if (!isSyncEnabled) {
        debugPrint('[SyncService] Sync is disabled by user.');
        await db.close();
        return;
      }

      if (apiUrl == null || apiUrl.isEmpty) {
        debugPrint('[SyncService] API URL is missing.');
        await db.close();
        return;
      }

      final binaId = int.tryParse(binaIdStr ?? '') ?? 0;

      // 4. Check Interval
      final difference = now.millisecondsSinceEpoch - lastSyncTimestamp;
      final intervalMs = syncInterval * 1000;

      debugPrint('[SyncService] Interval Check: '
          'Diff=${difference}ms, '
          'Required=${intervalMs}ms');

      // Allow sync if enough time passed OR if we never synced (lastSyncTimestamp == 0)
      if (difference < intervalMs && lastSyncTimestamp != 0) {
         debugPrint('[SyncService] Interval not reached yet. Skipping.');
         await db.close();
         return;
      }

      debugPrint('[SyncService] Time to sync! Querying database...');

      // 5. Query Unsynced Calls
      final unsyncedCalls = await (db.select(db.calls)
        ..where((t) => t.isSynced.equals(false)))
        .get();

      if (unsyncedCalls.isEmpty) {
        debugPrint('[SyncService] No unsynced calls found in database.');
        // Update timestamp even if nothing to sync, to avoid hammering DB? 
        // No, let's keep checking until we find something or interval passes.
        // Actually, if we update timestamp here, we wait another interval.
        // Let's update timestamp so we don't query DB every 2 seconds if empty.
        await prefs.setInt('last_sync_timestamp', now.millisecondsSinceEpoch);
        await db.close();
        return;
      }

      debugPrint('[SyncService] Found ${unsyncedCalls.length} calls to sync.');

      // 6. Sync Loop
      int successCount = 0;

      for (final call in unsyncedCalls) {
        debugPrint('[SyncService] Processing call ID: ${call.id}, Phone: ${call.phoneNumber}');
        
        try {
          final cleanNumber = call.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
          
          if (cleanNumber.isEmpty) {
             debugPrint('[SyncService] Skipping call ${call.id} - Empty number after cleanup.');
             await (db.update(db.calls)
              ..where((t) => t.id.equals(call.id)))
              .write(CallsCompanion(
                isSynced: const Value(true),
              ));
             continue;
          }

          // Format date: 2026-02-13 21:40:10
          // Ensure timestamp is properly formatted
          final dateCall = call.timestamp.toString().substring(0, 19);
          
          final payload = {
            "binaid": binaId,
            "name": "",
            "phone_number": int.tryParse(cleanNumber) ?? cleanNumber,
            "date_call": dateCall
          };

          debugPrint('[SyncService] Sending payload to $apiUrl: $payload');

          final response = await _dio.post(
            apiUrl,
            data: payload,
            options: Options(
              headers: {
                'Content-Type': 'application/json',
              },
              // Force plain text to avoid "Failed to parse the media type" errors
              // from servers sending invalid Content-Type headers (e.g. just "json").
              responseType: ResponseType.plain, 
              validateStatus: (status) => true, 
            ),
          );

          debugPrint('[SyncService] HTTP Response: ${response.statusCode} - ${response.data}');

          if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
            // Mark as synced
            await (db.update(db.calls)
              ..where((t) => t.id.equals(call.id)))
              .write(CallsCompanion(
                isSynced: const Value(true),
                lastError: const Value(null),
              ));
             debugPrint('[SyncService] Call ${call.id} MARKED AS SYNCED.');
             successCount++;
          } else {
             final errorMsg = 'Erro ${response.statusCode}: ${response.statusMessage}';
             debugPrint('[SyncService] Failed to sync call ${call.id}. $errorMsg');
             await (db.update(db.calls)
              ..where((t) => t.id.equals(call.id)))
              .write(CallsCompanion(
                lastError: Value(errorMsg),
              ));
          }

        } on DioException catch (dioError) {
          String errorMsg = 'Erro na conexão';
          if (dioError.type == DioExceptionType.connectionTimeout || 
              dioError.type == DioExceptionType.sendTimeout ||
              dioError.type == DioExceptionType.receiveTimeout) {
            errorMsg = 'Tempo limite excedido (5s)';
          } else if (dioError.response != null) {
            errorMsg = 'Erro ${dioError.response?.statusCode}';
          } else {
            errorMsg = dioError.message ?? 'Erro desconhecido';
          }
          
          debugPrint('[SyncService] DioError syncing call ${call.id}: $errorMsg');
          
           await (db.update(db.calls)
              ..where((t) => t.id.equals(call.id)))
              .write(CallsCompanion(
                lastError: Value(errorMsg),
              ));

        } catch (e) {
          final errorMsg = 'Erro: $e';
          debugPrint('[SyncService] General Error syncing call ${call.id}: $e');
           await (db.update(db.calls)
              ..where((t) => t.id.equals(call.id)))
              .write(CallsCompanion(
                lastError: Value(errorMsg),
              ));
        }
      }

      // 7. Update Timestamp
      await prefs.setInt('last_sync_timestamp', DateTime.now().millisecondsSinceEpoch);
      debugPrint('[SyncService] Sync finished. Success count: $successCount');

      // 8. Notify UI
      if (successCount > 0) {
        debugPrint('[SyncService] Invoking sync_completed event');
        FlutterBackgroundService().invoke('sync_completed');
      }

    } catch (e, stackTrace) {
      debugPrint('[SyncService] Critical Service Error: $e');
      debugPrint('[SyncService] StackTrace: $stackTrace');
    } finally {
      await db.close();
      debugPrint('[SyncService] Database closed.');
    }
  }
}
