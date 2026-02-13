import 'package:flutter/services.dart';
import '../../domain/entities/call_log.dart';
import '../../domain/repositories/call_repository.dart';

class CallInterceptorService {
  static const MethodChannel _channel = MethodChannel('com.bina_intercept/call');
  final CallRepository _repository;

  CallInterceptorService(this._repository);

  void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onIncomingCall') {
      final String? number = call.arguments['number'];
      final String? sourceString = call.arguments['source'];
      
      if (number != null && sourceString != null) {
        // Ignore unknown sources
        if (sourceString != 'whatsapp' && sourceString != 'cellular') return;

        final source = sourceString == 'whatsapp' ? CallSource.whatsapp : CallSource.cellular;
        final log = CallLog(
          phoneNumber: number,
          source: source,
          timestamp: DateTime.now(),
        );
        await _repository.addCall(log);
      }
    }
  }
}
