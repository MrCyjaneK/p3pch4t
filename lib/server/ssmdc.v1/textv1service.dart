import 'dart:convert';

import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/classes/ssmdc.v1/groupconfig.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:random_string/random_string.dart';

const helpText = r"""# SSMDC.v1 help menu.

### Command list

| Command | Description |
| ------- | ----------- |
| /help   | Shows this help menu |
| /stats  | Shows group stats |
| /meow   | Meows back |
| /users  | Shows user list |
| /config | Shows group configuration |
| /me     | Shows your profile | 
| /leave  | Leave the group |
| /ban [id] | Ban user with given ID |
| /unban [id] | Unban user with given ID |
""";

const statsText = r"""
# $groupname stats

| Key      | Value |
| -------- | ----- |
| Messages | `$messageCount` |
| Users    | `$usersCount` |
| Pending Events | `$pendingEventsCount` |
| Current missed relays | `$pendingEventTries` |
""";

const userText = r"""# $groupname members

| Name | Connstring | Last seen |
| ---- | ---------- | --------- |
""";

const configText = r"""# $groupname config

| Key | Value |
| --- | ----- |
| id | $id |
| name | $groupname |
| about | $about |
| welcomeMessage | $welcomeMessage |
| showWelcomeMessage | $showWelcomeMessage |
| joinMessage | $joinMessage |
| showJoinMessage | $showJoinMessage |
| byeMessage | $byeMessage |
| showByeMessage | $showByeMessage |
| leaveMessage | $leaveMessage |
| showLeaveMessage | $showLeaveMessage |

---------

```plain
$groupPublicKey
```""";

const meText = r"""# $username's profile

| Key | Value |
| --- | ----- |
| id  | $uId |
| name | $username |
| uid | $uUid |
| lastSeen | $uLastSeen |
| connstring | $uConnstring |
| isIntroduced | $uIsIntroduced |

----

```plain
$uPublicKey
```

----

$uBio

""";

Future<String> ssmdcv1StringParse(
  String s,
  SSMDCv1GroupConfig group,
  User u,
) async {
  if (s.contains(r'$about')) s = s.replaceAll(r'$about', group.about);
  if (s.contains(r'$groupname')) s = s.replaceAll(r'$groupname', group.name);
  if (s.contains(r'$groupPublicKey')) {
    s = s.replaceAll(r'$groupPublicKey', await group.groupPublicKey());
  }
  if (s.contains(r'$id')) s = s.replaceAll(r'$id', group.id.toString());
  if (s.contains(r'$messageCount')) {
    s = s.replaceAll(r'$messageCount', group.messageCount.toString());
  }
  if (s.contains(r'$name')) s = s.replaceAll(r'$name', group.name);
  if (s.contains(r'$pendingEventsCount')) {
    s = s.replaceAll(
        r'$pendingEventsCount', group.getPendingEvents().toString());
  }
  if (s.contains(r'$pendingEventTries')) {
    s = s.replaceAll(
        r'$pendingEventTries', group.getPendingEventsTries().toString());
  }
  if (s.contains(r'$uBio')) s = s.replaceAll(r'$uBio', u.bio);
  if (s.contains(r'$uConnstring')) {
    s = s.replaceAll(r'$uConnstring', '${u.connmethod}://${u.connstring}');
  }
  if (s.contains(r'$uId')) s = s.replaceAll(r'$uId', u.id.toString());
  if (s.contains(r'$uIsIntroduced')) {
    s = s.replaceAll(r'$uIsIntroduced', u.isIntroduced.toString());
  }
  if (s.contains(r'$uLastSeen')) {
    s = s.replaceAll(r'$uLastSeen', u.lastSeen.toIso8601String());
  }
  if (s.contains(r'$uPublicKey')) {
    s = s.replaceAll(r'$uPublicKey', u.publicKey.toString());
  }
  if (s.contains(r'$uUid')) s = s.replaceAll(r'$uUid', u.uid);

  if (s.contains(r'$username')) s = s.replaceAll(r'$username', u.name);
  if (s.contains(r'$usersCount')) {
    s = s.replaceAll(r'$usersCount', group.userList.length.toString());
  }
  if (s.contains(r'$showByeMessage')) {
    s = s.replaceAll(r'$showByeMessage', group.showByeMessage.toString());
  }
  if (s.contains(r'$showJoinMessage')) {
    s = s.replaceAll(r'$showJoinMessage', group.showJoinMessage.toString());
  }
  if (s.contains(r'$showLeaveMessage')) {
    s = s.replaceAll(r'$showLeaveMessage', group.showLeaveMessage.toString());
  }
  if (s.contains(r'$showWelcomeMessage')) {
    s = s.replaceAll(
        r'$showWelcomeMessage', group.showWelcomeMessage.toString());
  }
  if (s.contains(r'$byeMessage')) {
    s = s.replaceAll(r'$byeMessage', group.byeMessage);
  }
  if (s.contains(r'$joinMessage ')) {
    s = s.replaceAll(r'$joinMessage ', group.joinMessage);
  }
  if (s.contains(r'$leaveMessage')) {
    s = s.replaceAll(r'$leaveMessage', group.leaveMessage);
  }
  if (s.contains(r'$welcomeMessage')) {
    s = s.replaceAll(r'$welcomeMessage', group.welcomeMessage);
  }
  return s;
}

Future<bool> ssmdcv1HandleServiceCommands(
  String text,
  User u,
  SSMDCv1GroupConfig group,
  Map<String, dynamic> req,
) async {
  final spl = text.split(" ");
  switch (spl[0]) {
    case "/help":
      ssmdcv1ServiceRespond(group, req, helpText, u);
      return true;
    case "/stats":
      ssmdcv1ServiceRespond(
          group, req, await ssmdcv1StringParse(statsText, group, u), u);
      return true;
    case "/meow":
      ssmdcv1ServiceRespond(group, req, "Meow ^^", u);
      return true;
    case "/users":
      String response = userText;
      for (var extU in group.userList) {
        response +=
            "| ${extU.id}. ${extU.name} | ${extU.connmethod}://${extU.connstring} | ${extU.lastSeen} |\n";
      }
      ssmdcv1ServiceRespond(
          group, req, await ssmdcv1StringParse(response, group, u), u);
      return true;
    case "/config":
      ssmdcv1ServiceRespond(
          group, req, await ssmdcv1StringParse(configText, group, u), u);
      return true;
    case "/me":
      ssmdcv1ServiceRespond(
          group, req, await ssmdcv1StringParse(meText, group, u), u);
      return true;
    case "/leave":
      if (group.showByeMessage) {
        ssmdcv1ServiceRespond(group, req, group.byeMessage, u);
      }
      group.userList.removeWhere((element) => element.id == u.id);
      ssmdcv1GroupConfigBox.put(group);
      if (group.showLeaveMessage) {
        ssmdcv1ServiceRespondAll(group, req, group.leaveMessage, u);
      }
      return true;
    case "/ban":
      if (!group.isUserAdmin(u)) {
        ssmdcv1ServiceRespond(group, req, "You are not an admin!", u);
        return true;
      }

      if (spl.length <= 2) {
        ssmdcv1ServiceRespond(
            group,
            req,
            "Syntax: `/ban [user id]`\n\nYou can obtain user ID from `/users` command,",
            u);
        return true;
      }
      int? uToBanId = int.tryParse(spl[1]);
      if (uToBanId == null) {
        ssmdcv1ServiceRespond(
            group, req, "${spl[1]} doesn't look like a valid numeric ID.", u);
        return true;
      }
      final User? uToBan =
          userBox.query(User_.id.equals(uToBanId)).build().findFirst();
      if (uToBan == null) {
        ssmdcv1ServiceRespond(group, req, "User not found.", u);
        return true;
      }
      group.banUser(u);
      return true;
    case "/unban":
      if (!group.isUserAdmin(u)) {
        ssmdcv1ServiceRespond(group, req, "You are not an admin!", u);
        return true;
      }
      if (spl.length <= 2) {
        ssmdcv1ServiceRespond(
            group,
            req,
            "Syntax: `/unban [user id]`\n\nYou can obtain user ID from `/users` command,",
            u);
        return true;
      }
      int? uToBanId = int.tryParse(spl[1]);
      if (uToBanId == null) {
        ssmdcv1ServiceRespond(
            group, req, "${spl[1]} doesn't look like a valid numeric ID.", u);
        return true;
      }
      final User? uToBan =
          userBox.query(User_.id.equals(uToBanId)).build().findFirst();
      if (uToBan == null) {
        ssmdcv1ServiceRespond(group, req, "User not found.", u);
        return true;
      }
      group.unbanUser(u);
      return true;
    case "📌":
      ssmdcv1ServiceRespond(group, req, '🍬', u);
      return false;
  }
  return false;
}

Future<void> ssmdcv1ServiceRespond(
  SSMDCv1GroupConfig group,
  Map<String, dynamic> req,
  String text,
  User u,
) async {
  req["body"]["body"]["nonce"] =
      "${req["body"]["body"]["nonce"]};${u.id};${randomAlphaNumeric(16)}";
  req["body"]["body"]["type"] = "text.v1";
  req["body"]["body"]["data"] = base64Encode(utf8.encode(text));
  req["body"]["body"]["origin"] = {
    "name": "${group.name} (whisper)",
  };
  final Event evt = Event(
    jsonBody: jsonEncode(req["body"]["body"]),
    privKey: group.groupPrivatePgp,
  );
  evt.id = u.queueSendEvent(evt);
  u.sendEvent(evt);
}

Future<void> ssmdcv1ServiceRespondAll(
  SSMDCv1GroupConfig group,
  Map<String, dynamic> req,
  String text,
  User? except,
) async {
  req["body"]["body"]["nonce"] =
      "${req["body"]["body"]["nonce"]};-1;${randomAlphaNumeric(16)}";
  req["body"]["body"]["type"] = "text.v1";
  req["body"]["body"]["data"] = base64Encode(utf8.encode(text));
  req["body"]["body"]["origin"] = {
    "name": "${group.name} (whisper)",
  };
  final Event evt = Event(
    jsonBody: jsonEncode(req["body"]["body"]),
    privKey: group.groupPrivatePgp,
  );
  group.broadcastToAll(evt, except);
}
