import 'package:equatable/equatable.dart';

enum CallSource { cellular, whatsapp }

class CallLog extends Equatable {
  final int? id;
  final String phoneNumber;
  final CallSource source;
  final DateTime timestamp;
  final bool isSynced;
  final String? lastError;

  const CallLog({
    this.id,
    required this.phoneNumber,
    required this.source,
    required this.timestamp,
    this.isSynced = false,
    this.lastError,
  });

  @override
  List<Object?> get props => [id, phoneNumber, source, timestamp, isSynced, lastError];
}
