import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'Bina Intercept Service', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Bina Intercept',
      initialNotificationContent: 'Monitorando chamadas em segundo plano...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
  
  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to 3.0.0
  // We have to register the plugin manually

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
    
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // bring to foreground
  Timer.periodic(const Duration(seconds: 2), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        /// OPTIONAL for use custom notification
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? number = prefs.getString('background_incoming_call');
      final int? timestamp = prefs.getInt('background_incoming_call_timestamp');

      if (number != null && timestamp != null) {
        final diff = DateTime.now().millisecondsSinceEpoch - timestamp;
        // If call was within last 10 seconds
        if (diff < 10000) {
           debugPrint('Background Service: New Call Detected: $number');
           
           // Clear the pref so we don't process it again
           await prefs.remove('background_incoming_call');
           
           try {
             final db = AppDatabase();
             await db.insertCall(CallsCompanion(
               phoneNumber: Value(number),
               source: const Value('cellular'),
               timestamp: Value(DateTime.fromMillisecondsSinceEpoch(timestamp)),
             ));
             await db.close();
             debugPrint('Background Service: Call saved to database');
           } catch (dbError) {
             debugPrint('Background Service: Error saving to database: $dbError');
           }
        }
      }
    } catch (e) {
      debugPrint('Error accessing shared prefs: $e');
    }
    
    debugPrint('Bina Intercept Service is running: ${DateTime.now()}');
  });
}
