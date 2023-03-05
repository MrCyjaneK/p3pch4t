import 'dart:io';

import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:p3pch4t/server/chat_server.dart';
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
