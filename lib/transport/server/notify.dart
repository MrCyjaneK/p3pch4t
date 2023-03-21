import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
Future<void> notify(int id, String channelId, String channelName, String title,
    String body) async {
  print("notify($id, $title, $body) called");
  if (flutterLocalNotificationsPlugin == null) {
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    print("initializing...");
    var init = await flutterLocalNotificationsPlugin!
        .initialize(initializationSettings,
            onDidReceiveNotificationResponse: (NotificationResponse n) {
      print(n.payload);
    });
    print("Notifs init: $init");
  }

  String groupKey =
      'x.x.p3pch4t.${channelId.toUpperCase().replaceAll(".", "_")}';

  if (Platform.isAndroid) {
    print("creating group");
    await (flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!
        .createNotificationChannelGroup(
            AndroidNotificationChannelGroup(groupKey, channelName)));
  } else {
    print("not creating group");
  }
  AndroidNotificationChannelGroup(channelId, channelName);

  AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId,
    channelName,
    groupId: groupKey,
    description: 'App message notifications',
    importance: Importance.low,
  );
  print("Creating channel...");

  await flutterLocalNotificationsPlugin!
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  NotificationDetails notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      icon: 'ic_bg_service_small',
      ongoing: false,
      importance: Importance.high,
      priority: Priority.high,
      groupKey: groupKey,
    ),
    linux: const LinuxNotificationDetails(),
  );
  print("Sending notification");
  await flutterLocalNotificationsPlugin!.show(
    id + 888,
    title,
    body,
    notificationDetails,
  );
  print("ok");
}
