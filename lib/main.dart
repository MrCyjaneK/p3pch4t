import 'package:flutter/material.dart';
import 'package:p3pch4t/helpers/boot.dart';
import 'package:p3pch4t/helpers/service.dart';
import 'package:p3pch4t/pages/mainpage.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';

bool wsrunning = false;

Future<void> doTheObvious() async {
  await initStorage();
}

// In your main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await doTheObvious();
  await platformBoot();
  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  await realOnStart(service);
}
