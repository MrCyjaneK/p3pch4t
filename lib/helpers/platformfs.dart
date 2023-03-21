import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

Future<bool> doPlatformFStask() async {
  if (Platform.isAndroid) {
    var filesStatus = await Permission.manageExternalStorage.status;
    if (filesStatus.isGranted) {
      return false;
    }
    filesStatus = await Permission.manageExternalStorage.request();
    if (filesStatus.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return false;
  }
  return true;
}
