import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:i2p_flutter/i2p_flutter.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/mainpage.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:p3pch4t/server/chat_server.dart';
import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:p3pch4t/server/notify.dart';

bool wsrunning = false;

Future<void> doTheObvious() async {
  await initStorage();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await doTheObvious();
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
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    if (Platform.isAndroid) {
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestPermission();
    }
  }
  runApp(const MyApp());
}

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
  await flutterLocalNotificationsPlugin!
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
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

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  print("onStart(): WidgetsFlutterBinding.ensureInitialized();");
  WidgetsFlutterBinding.ensureInitialized();
  print("onStart(): doTheObvious();");
  await doTheObvious();
  print("onStart(): runWebserver();");
  await runWebserver();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer.periodic(const Duration(seconds: kDebugMode ? 5 : 15), (timer) async {
    // flutterLocalNotificationsPlugin.show(5331531, "Test", "Test2", null);
    if (service is AndroidServiceInstance) {
      //print("onStart(): Timer: isForegroundService()");
      if (await (service).isForegroundService()) {
        final dt = DateTime.now();
        //print("onStart(): Timer: doEventTasks");
        List<int> stats =
            await doEventTasks(); // [statTotal, statProcessed, statRemoved];
        introduceNewUsers();
        //print("onStart(): Timer: doEventTasks: ok");
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'p3pch4t is running',
          'q/p/r: ${stats[0]}/${stats[1]}/${stats[2]}; ${dt.hour}:${dt.minute}:${dt.second}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'Notifications',
              channelDescription:
                  'This channel is used for status notifications.',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );
      }
    }
  });
}

Future<void> introduceNewUsers() async {
  List<User> ul =
      userBox.query(User_.isIntroduced.equals(false)).build().find();
  for (var u in ul) {
    u.isIntroduced = true;
    u.introduce();
    userBox.put(u);
  }
}

bool isDownloadInProgress = false;

Future<void> downloadParts() async {
  try {
    if (isDownloadInProgress) return;
    isDownloadInProgress = true;
    final items = downloadItemBox.getAll();
    for (var di in items) {
      if (di.isDownloaded) continue;
      await di.downloadPart(1024 * 1024 * 5);
    }
    isDownloadInProgress = false;
  } catch (e) {
    isDownloadInProgress = false;
    return;
  }
  return;
}

Future<List<int>> doEventTasks() async {
  if (!await i2pFlutterPlugin.isRunning()) {
    // print("restarting i2pd..");
    i2pFlutterPlugin.runI2pd();
    // notify(333, "i2pd started!", "I2pd wasn't running! We had to restart it.");
  }
  List<Event> events = eventBox.getAll();

  int statTotal = events.length;
  int statRemoved = 0;
  int statProcessed = 0;
  await downloadParts();
  List<String> connstringSkipList = [];
  for (var event in events) {
    if (event.destinations.isEmpty) {
      eventBox.remove(event.id);
      statRemoved++;
    }
    if (event.relayTries == 0) {
      // It looks like theevent just got queued, retry sending just in case.
      await event.trySend(connstringSkipList);
    } else {
      //    We were unable to send the event for a long amount of time (3 tries)
      // So we will try to send it:
      // For first hour - every 1 minute
      // For 1-6 hours - every 2 minutes
      // For 7-12 hours - every 5 minutes
      // For 13-48 hours - every 10 minutes
      // For 49-168 hours - every 20 minutes
      // For 169< - every hour.
      // As far as I am concerned it shouldn't cause any significant resource
      // and is done more to not cause significant delays when sending newer
      // events.
      // Events will never get canceled. And all should get delivered once
      // destination becomes online.
      //
      int createHourDiff =
          event.lastRelayed.difference(event.creationDate).inHours;
      int minuteDiff = DateTime.now().difference(event.lastRelayed).inMinutes;
      // print("createHourDiff: $createHourDiff; minuteDiff: $minuteDiff");
      if ((createHourDiff <= 1 && minuteDiff >= 1) ||
          (createHourDiff >= 7 && minuteDiff >= 2) ||
          (createHourDiff >= 13 && minuteDiff >= 5) ||
          (createHourDiff >= 49 && minuteDiff >= 10) ||
          (createHourDiff >= 169 && minuteDiff >= 20)) {
        statProcessed++;
        event.trySend(connstringSkipList);
      }
    }
    for (var elm in event.destinations) {
      connstringSkipList.add(elm.connstring);
    }
  }
  return [statTotal, statProcessed, statRemoved];
}
