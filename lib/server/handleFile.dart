import 'dart:convert';
import 'dart:typed_data';

import 'package:p3pch4t/classes/message.dart';
import 'package:p3pch4t/classes/fileevt.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:p3pch4t/server/chat_server.dart';
import 'package:p3pch4t/server/notify.dart';
import 'package:shelf/shelf.dart';

// Request must contain:
// {
//   "type": "file.v1",
//   "nonce": "<random string>",
//   "data": {
//       "endpoint": "/endpoint/to/file/$start/$end",
//       "filename": "filename",
//       "filesize": 1024, // 1kB
//       "caption": "caption of the file.",
//"checksum": {
//          "sha1": "sha1sum of file",
//          "sha256": "sha256sum of file",
//          "sha512": "sha512sum of file",
//          "md5": "md5sum of file"
//        },
//    },
// }
//
// then - if client wishes to download file from the sender he needs to send
// a request to /endpoint/to/file/$start/$end with
//  - $start replaced to the start position - for example 0
//  - $end replaced with end position that client wishes to get.
// In response client will send bytes encrypted by pgp - bytes that are not
// signed - that is to allow relaying files by 3rd party services... in a far
// away future.
//

Future<Response> handleFileV1(Map<String, dynamic> req) async {
  Message? msg = messageBox
      .query(
        Message_.nonce.equals("incomming:${req["body"]["body"]["nonce"]}"),
      )
      .build()
      .findFirst();
  final u = userBox
      .query(User_.publicKey.equals(req["body"]["senderpgp"]))
      .build()
      .findFirst();
  if (u == null) {
    print("User not found!!!! !1!! !!!");
    return json(
      {"ok": false, "message": "User not found in db, please intruduce.v1"},
    );
  }

  u.lastSeen = DateTime.now();
  userBox.put(u);

  Map<String, dynamic> body = req["body"]["body"]["data"];

  msg ??= Message(
    eventUid: null,
    userId: u.id,
    type: req["body"]["body"]["type"],
    isTrusted: req["isValid"],
    isSelf: false,
    nonce: "incomming:${req["body"]["body"]["nonce"]}",
    data: utf8.encode(jsonEncode(req["body"]["body"])) as Uint8List,
  );
  msg.type = req["body"]["body"]["type"];
  msg.isTrusted = req["isValid"];
  msg.nonce = "incomming:${req["body"]["body"]["nonce"]}";
  msg.data = utf8.encode(jsonEncode(req["body"]["body"])) as Uint8List;
  msg.id = messageBox.put(msg);

  String endpoint = "${body["endpoint"]}";

  if (endpoint.startsWith("/")) {
    endpoint = "http://${u.connstring}$endpoint"; // prefix connstring
  }

  FileEvt? fileevt =
      fileevtBox.query(FileEvt_.msgId.equals(msg.id)).build().findFirst();
  fileevt ??= FileEvt(
    endpoint: endpoint, // TODO: security?
    filename: body["filename"],
    caption: body["caption"],
    filesize: body["filesize"],
    msgId: msg.id,
  );
  fileevt.endpoint = endpoint;
  fileevt.filename = body["filename"];
  fileevt.caption = body["caption"];
  fileevt.filesize = body["filesize"];
  fileevt.msgId = msg.id;
  fileevt.sha1sum = body["checksum"]["sha1"];
  fileevt.sha256sum = body["checksum"]["sha256"];
  fileevt.sha512sum = body["checksum"]["sha512"];
  fileevt.md5sum = body["checksum"]["md5"];

  fileevtBox.put(fileevt);

  notify(msg.id, u.name, fileevt.caption);
  return json({"ok": true});
}
