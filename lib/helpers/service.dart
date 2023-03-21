import 'dart:async';

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/helpers/eventTasks.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/transport/server/chat_server.dart';
import 'package:p3pch4t/transport/server/notify.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

const notificationChannelId = 'my_foreground';
const notificationId = 888;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'Notifications',
    description: 'This channel is used for status notifications.',
    importance: Importance.low,
  );

  flutterLocalNotificationsPlugin ??= FlutterLocalNotificationsPlugin();
  print("creating channel...");
  await flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  print("Configuring...");

  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,
      // auto start service
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Starting',
      initialNotificationContent: 'P3Pch4t is starting.. please hold tight.',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(),
  );
  print("Starting");

  print("Started: ${await service.startService()}");
}

Future<void> realOnStart(ServiceInstance service) async {
  print("onStart(): WidgetsFlutterBinding.ensureInitialized();");
  WidgetsFlutterBinding.ensureInitialized();
  print("onStart(): doTheObvious();");
  await doTheObvious();
  print("onStart(): runWebserver();");
  await runWebserver();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Timer.periodic(const Duration(seconds: 15), (timer) async {
    // flutterLocalNotificationsPlugin.show(5331531, "Test", "Test2", null);
    if (service is AndroidServiceInstance) {
      //print("onStart(): Timer: isForegroundService()");
      if (await (service).isForegroundService()) {
        final dt = DateTime.now();
        //print("onStart(): Timer: doEventTasks");
        List<int> stats = await doEventTasks(); // [statTotal, statProcessed, statRemoved];
        introduceNewUsers();
        //print("onStart(): Timer: doEventTasks: ok");
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'p3pch4t is running',
          'q/p/r: ${stats[0]}/${stats[1]}/${stats[2]}; ${formatDate(dt, [HH, ':', nn, '.', ss])}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'Notifications',
              channelDescription: 'This channel is used for status notifications.',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );
      }
    }
  });
}
