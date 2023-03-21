import 'dart:io';

import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:p3pch4t/transport/server/chat_server.dart';
import 'package:shelf/shelf.dart';

Future<Response> serveFile(
  Request req,
  String userId,
  String fileId,
  String start,
  String end,
) async {
  int iStart = int.parse(start);
  int iEnd = int.parse(end);
  if (iStart >= iEnd) {
    return json({"ok": false, "message": "Invalid seek ($iStart >= $iEnd)"});
  }
  final file =
      fileevtBox.query(FileEvt_.uid.equals(fileId)).build().findFirst();
  if (file == null || file.localPath == null) {
    return json({"ok": false, "message": "File not found."});
  }
  final fsFile = File(file.localPath!);
  final raf = await fsFile.open(mode: FileMode.read);
  raf.setPositionSync(iStart);
  return Response(
    200,
    body: raf.readSync(iEnd - iStart),
  );
}

Future<Response> serveFileV2(
  Request req,
  String userId,
  String fileId,
  String start,
  String end,
) async {
  int iStart = int.parse(start);
  int iEnd = int.parse(end);
  if (iStart >= iEnd) {
    return json({"ok": false, "message": "Invalid seek ($iStart >= $iEnd)"});
  }
  var file =
      fileV2Box.query(FileV2_.fileUid.equals(fileId)).build().findFirst();
  if (file == null) {
    return json({"ok": false, "message": "File not found."});
  }

  if (file.contentBytes == null) {
    return json({
      "ok": false,
      "message":
          "File was found but it's contentBytes were null - tried to fetch a directory?"
    });
  }

  if (file.contentBytes?.length != file.knownSize) {
    return json({
      "ok": false,
      "message":
          "File was found but it's contentBytes (${file.contentBytes?.length}) is different than knownSize (${file.knownSize}). I'll not serve it as this is enough to prove that this file is corrupted. I hate corruption."
    });
  }

  return Response(
    200,
    body: file.contentBytes!
        .skip(iStart)
        .take(iEnd), //  raf.readSync(iEnd - iStart),
  );
}
