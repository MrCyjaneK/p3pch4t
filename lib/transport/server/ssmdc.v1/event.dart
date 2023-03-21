import 'dart:convert';

import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/classes/ssmdc.v1/groupconfig.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:p3pch4t/transport/server/chat_server.dart';
import 'package:p3pch4t/transport/server/ssmdc.v1/calendarv1.syncv1.dart';
import 'package:p3pch4t/transport/server/ssmdc.v1/textv1service.dart';
import 'package:shelf/shelf.dart';

ssmdcv1coreEvent(Request request, String groupUid) async {
  SSMDCv1GroupConfig? group = ssmdcv1GroupConfigBox
      .query(SSMDCv1GroupConfig_.uid.equals(groupUid))
      .build()
      .findFirst();
  if (group == null) {
    return Response.notFound("not found");
  }
  var req = await decodeObj(
    await request.readAsString(),
    group.groupPrivatePgp,
  );
  print(
    "ssmdcv1(${group.name}): Got new event: ${req["body"]["body"]["type"]}",
  );
  switch (req["body"]["body"]["type"]) {
    case 'introduce.v1':
      // NOTE: Since both normal user store and SSMDCv1GroupConfig share the
      // same userBox as underlying contact database (name a good reason to
      // change this and I'll do so.). We can easily handle introduction like
      // this. I think.
      // NOTE: v2. no.
      return await ssmdcv1HandleIntroductionV1(req, group);
    case 'text.v1':
      return await ssmdcv1HandleTextV1(req, group);
    case 'calendar.v1.sync.v1':
      return await ssmdcv1HandleCalendarV1SyncV1(req, group);
    default:
      return await ssmdcv1HandleEvent(req, group);
  }

  return json({"ok": true});
}

Future<Response> ssmdcv1HandleIntroductionV1(
  Map<String, dynamic> req,
  SSMDCv1GroupConfig group,
) async {
  var u = userBox
      .query(User_.publicKey.equals(req["body"]["senderpgp"]))
      .build()
      .findFirst();
  final uUri = Uri.parse(req["body"]["body"]["data"]["connstring"]);
  u ??= User(
    connstring: uUri.host + uUri.path,
    connmethod: req["body"]["body"]["data"]["connmethod"],
  );
  u.lastSeen = DateTime.now();
  u.connstring = uUri.host + uUri.path;
  u.connmethod = req["body"]["body"]["data"]["connmethod"];
  u.name = req["body"]["body"]["data"]["username"];
  u.bio = req["body"]["body"]["data"]["bio"];
  u.publicKey = req["body"]["body"]["data"]["senderpgp"];
  u.rawBackgroundColor = req["body"]["body"]["data"]["backgroundColor"];
  u.chatBackgroundAsset = req["body"]["body"]["data"]["backgroundAsset"];
  u.id = userBox.put(u);

  if (group.isUserBanned(u)) {
    ssmdcv1ServiceRespond(
        group,
        req,
        "You are banned and cannot participate in this chat. \n\n```plain\nmsg trigger reason: introduce.v1\n```",
        u);
    return json({"ok": true});
  }
  ssmdcv1AddUser(group, u, req);
  final evt = await Event.newSsmdcv1Introduction(u, group);
  evt.id = u.queueSendEvent(evt);
  return json({
    "ok": true,
  });
}

void ssmdcv1AddUser(
    SSMDCv1GroupConfig group, User u, Map<String, dynamic> req) async {
  bool contains = false;
  for (var element in group.userList) {
    if (element.id == u.id) {
      contains = true;
    }
  }
  if (contains) {
    return;
  }
  group.userList.add(u);
  ssmdcv1GroupConfigBox.put(group);
  await ssmdcv1ServiceRespond(
    group,
    req,
    await ssmdcv1StringParse(group.welcomeMessage, group, u),
    u,
  );
  await ssmdcv1ServiceRespondAll(
    group,
    req,
    await ssmdcv1StringParse(group.joinMessage, group, u),
    null,
  );
  print("added user");
}

Future<Response> ssmdcv1HandleTextV1(
  Map<String, dynamic> req,
  SSMDCv1GroupConfig group,
) async {
  group.messageCount++;
  ssmdcv1GroupConfigBox.put(group);

  final u = userBox
      .query(User_.publicKey.equals(req["body"]["senderpgp"]))
      .build()
      .findFirst();
  if (u == null) {
    print("User not found!!!! !1!! !!!");
    return json(
      {"ok": false, "message": "User not found in db, please text.v1"},
    );
  }

  u.lastSeen = DateTime.now();
  userBox.put(u);
  String plainBody = utf8.decode(base64Decode(req["body"]["body"]["data"]));

  if (group.isUserBanned(u)) {
    ssmdcv1ServiceRespond(
        group,
        req,
        "You are banned and cannot participate in this chat. \n\n```plain\nmsg trigger reason: event (text.v1)\n```",
        u);
    return json({"ok": true});
  }
  ssmdcv1AddUser(group, u, req);

  if ((await ssmdcv1HandleServiceCommands(plainBody, u, group, req))) {
    return json({"ok": true});
  }
  req["body"]["body"]["origin"] = {
    "name": u.name,
    "connstring": u.connstring,
    "connmethod": u.connmethod,
  };
  req["body"]["body"]["nonce"] = "${req["body"]["body"]["nonce"]};${u.id}";
  final Event evt = Event(
    jsonBody: jsonEncode(req["body"]["body"]),
    privKey: group.groupPrivatePgp,
  );
  group.broadcastToAll(evt, u);

  // We do not need to notify on this I think.. as this could cause duplicates.
  // notify(msg.id, u.name, utf8.decode(msg.data));
  return json({"ok": true});
}

Future<Response> ssmdcv1HandleEvent(
  Map<String, dynamic> req,
  SSMDCv1GroupConfig group,
) async {
  group.messageCount++;
  ssmdcv1GroupConfigBox.put(group);

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

  if (group.isUserBanned(u)) {
    ssmdcv1ServiceRespond(
        group,
        req,
        "You are banned and cannot participate in this chat. \n\n```plain\nmsg trigger reason: events\n```",
        u);
    return json({"ok": true});
  }
  ssmdcv1AddUser(group, u, req);

  req["body"]["body"]["origin"] = {
    "name": u.name,
    "connstring": u.connstring,
    "connmethod": u.connmethod,
  };
  req["body"]["body"]["nonce"] = "${req["body"]["body"]["nonce"]};${u.id}";
  final Event evt = Event(
    jsonBody: jsonEncode(req["body"]["body"]),
    privKey: group.groupPrivatePgp,
  );
  group.broadcastToAll(evt, u);

  // We do not need to notify on this I think.. as this could cause duplicates.
  // notify(msg.id, u.name, utf8.decode(msg.data));
  return json({"ok": true});
}
