import 'package:equatable/equatable.dart';

enum CallSource { cellular, whatsapp }

class CallLog extends Equatable {
  final int? id;
  final String phoneNumber;
  final CallSource source;
  final DateTime timestamp;

  const CallLog({
    this.id,
    required this.phoneNumber,
    required this.source,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, phoneNumber, source, timestamp];
}
