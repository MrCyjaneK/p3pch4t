import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:p3pch4t/helpers/eventTasks.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:p3pch4t/helpers/service.dart';
import 'package:p3pch4t/main.dart';
import 'package:p3pch4t/transport/server/chat_server.dart';

Future<void> platformBoot() async {
  if ((prefs.getString("privkey") != null)) {
    if (Platform.isAndroid) {
      await initializeService();
      // await Future.delayed(const Duration(seconds: 1));
      // runWebserver();
    } else {
      if (!wsrunning) {
        wsrunning = true;
        runWebserver();
        () async {
          while (true) {
            await doEventTasks();
            await Future.delayed(const Duration(seconds: 5));
          }
        }();
      }
    }
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    if (Platform.isAndroid) {
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestPermission();
    }
  }
}
