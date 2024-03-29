import 'dart:convert';

import 'package:p3pch4t/classes/message.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:p3pch4t/transport/server/chat_server.dart';
import 'package:p3pch4t/transport/server/notify.dart';
import 'package:shelf/shelf.dart';

// Request must contain:
// {
//   "type": "text.v1"
//   "nonce": "<random string>",
//   "data": "base64 encoded utf8 encoded plaintext string (formatted in markdown)",
// }

// TODO: incomming -> incomming $(u.id?);

Future<Response> handleTextV1(Map<String, dynamic> req) async {
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
        {"ok": false, "message": "User not found in db, please intruduce.v1"});
  }

  u.lastSeen = DateTime.now();
  userBox.put(u);

  msg ??= Message(
    eventUid: null,
    userId: u.id,
    type: req["body"]["body"]["type"],
    isTrusted: req["isValid"],
    isSelf: false,
    nonce: "incomming:${req["body"]["body"]["nonce"]}",
    data: base64Decode(req["body"]["body"]["data"]),
  );
  msg.type = req["body"]["body"]["type"];
  msg.isTrusted = req["isValid"];
  msg.nonce = "incomming:${req["body"]["body"]["nonce"]}";
  msg.data = base64Decode(req["body"]["body"]["data"]);
  try {
    msg.originName = req["body"]["body"]["origin"]["name"];
    msg.originConnmethod = req["body"]["body"]["origin"]["connmethod"];
    msg.originConnstring = req["body"]["body"]["origin"]["connstring"];
  } catch (e) {}
  msg.id = messageBox.put(msg);
  bool customTagShouldNotify = false;
  u.notifyCustomTags.split(",").forEach((element) {
    if (u.notifyCustomTags != "" &&
        utf8.decode(msg!.data).toLowerCase().contains(element.toLowerCase())) {
      customTagShouldNotify = true;
    }
  });
  if ((u.notifyOnEveryone &&
      utf8.decode(msg.data).toLowerCase().contains("@everyone"))) {
    notify(msg.id, "${u.id}.messages.everyone",
        "${u.name} messages (@everyone)", u.name, utf8.decode(msg.data));
  } else if (u.notifyOnTag &&
      utf8
          .decode(msg.data)
          .toLowerCase()
          .contains(prefs.getString("username").toString().toLowerCase())) {
    notify(msg.id, "${u.id}.messages.username", "${u.name} messages (Mention)",
        u.name, utf8.decode(msg.data));
  } else if (customTagShouldNotify) {
    notify(msg.id, "${u.id}.messages.customtag",
        "${u.name} messages (custom tags)", u.name, utf8.decode(msg.data));
  } else if (u.notifyOnAll) {
    notify(msg.id, "${u.id}.messages.all", "${u.name} messages", u.name,
        utf8.decode(msg.data));
  }
  return json({"ok": true});
}
