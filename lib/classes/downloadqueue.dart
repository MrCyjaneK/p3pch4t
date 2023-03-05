import 'dart:io';
import 'dart:math';

import 'package:objectbox/objectbox.dart';
import 'package:i2p_flutter/i2p_flutter.dart';
import 'package:dio/dio.dart';
import 'package:p3pch4t/classes/fileevt.dart';
import 'package:p3pch4t/prefs.dart';

@Entity()
class DownloadItem {
  DownloadItem({
    required this.filePath,
    required this.fileEvtId,
  });
  @Id()
  int id = 0;

  int fileEvtId;
  String filePath;

  int downloadTries = 0;

  @Transient()
  double get progress {
    FileEvt? fileEvt = fileevtBox.get(fileEvtId);
    if (fileEvt == null) {
      return 0;
    }
    File file = File(filePath);
    if (file.existsSync() != true) {
      file.createSync();
    }
    int currentSize = file.lengthSync();
    if (currentSize == 0 || fileEvt.filesize == 0) {
      return 0;
    }
    return (currentSize / fileEvt.filesize);
  }

  @Transient()
  bool get isDownloaded => progress == 1;

  Future<void> downloadPart(int size) async {
    FileEvt? fileEvt = fileevtBox.get(fileEvtId);
    if (fileEvt == null) {
      return;
    }

    // 1. open the file
    File file = File(filePath);
    if (file.existsSync() != true) {
      file.createSync();
    }
    // 2. check how many bytes got already downloaded (filesize)
    int currentSize = file.lengthSync();
    // 3. check if downloaded
    if (fileEvt.filesize <= currentSize) {
      print("${fileEvt.filesize} <= $currentSize");
      print("File is already downloaded");
      // The file is already downloaded.
      return;
    }
    // 4. download up to $size bytes from target

    late Response resp;
    try {
      resp = await i2pFlutterPlugin.dio().get(
            fileEvt.endpoint!.replaceAll(r"$start", "$currentSize").replaceAll(
                r"$end", "${min(currentSize + size, fileEvt.filesize)}"),
            options: Options(responseType: ResponseType.bytes),
          );
    } catch (e) {
      print(e);
      return;
    }
    await file.writeAsBytes(resp.data, mode: FileMode.append, flush: true);
    return;
  }
}

// !warn,!error,!Service already