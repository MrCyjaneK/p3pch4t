import 'dart:math';

import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:p3pch4t/server/chat_server.dart';
import 'package:p3pch4t/server/notify.dart';
import 'package:shelf/shelf.dart';

Future<Response> handleIntroductionV1(Map<String, dynamic> req) async {
  var u = userBox
      .query(User_.publicKey.equals(req["body"]["senderpgp"]))
      .build()
      .findFirst();
  final uUri = Uri.parse(req["body"]["body"]["data"]["connstring"]);
  if (u == null) {
    u = User(
      connstring: uUri.host + uUri.path,
      connmethod: req["body"]["body"]["data"]["connmethod"],
    );
    notify(
      Random().nextInt(555),
      "newuserintroduction",
      "New contacts",
      req["body"]["body"]["data"]["username"],
      "New contact added!",
    );
  }
  u.lastSeen = DateTime.now();
  u.connstring = uUri.host + uUri.path;
  u.connmethod = req["body"]["body"]["data"]["connmethod"];
  u.name = req["body"]["body"]["data"]["username"];
  u.bio = req["body"]["body"]["data"]["bio"];
  u.publicKey = req["body"]["body"]["data"]["senderpgp"];
  u.rawBackgroundColor = req["body"]["body"]["data"]["backgroundColor"];
  u.chatBackgroundAsset = req["body"]["body"]["data"]["backgroundAsset"];
  userBox.put(u);

  return json({
    "ok": true,
  });
}
