import 'package:date_format/date_format.dart';
import 'package:p3pch4t/classes/calendar.v1/calendarevent.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/classes/ssmdc.v1/groupconfig.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:p3pch4t/server/chat_server.dart';
import 'package:p3pch4t/server/ssmdc.v1/textv1service.dart';
import 'package:shelf/shelf.dart';

Future<Response> ssmdcv1HandleCalendarV1SyncV1(
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
      {"ok": false, "message": "User not found in db, please introduce.v1"},
    );
  }

  u.lastSeen = DateTime.now();
  userBox.put(u);

  if (group.isUserBanned(u)) {
    ssmdcv1ServiceRespond(
        group,
        req,
        "You are banned and cannot participate in this chat. \n\n```plain\nmsg trigger reason: event (text.v1)\n```",
        u);
    return json({"ok": true});
  }
  User? groupU = userBox
      .query(User_.publicKey.equals(await group.groupPublicKey()))
      .build()
      .findFirst();
  if (groupU == null) {
    await ssmdcv1ServiceRespond(
      group,
      req,
      "Unable to add event. Reason: Group creator is not a participant. Please ask him to join this group on th server device to be able to create calendar.v1 events",
      u,
    );
    return json({"ok": true});
  }

  if (!group.isUserCalendarMod(u)) {
    String appendLog = "";
    for (var elm in (req["body"]["body"]["data"] as List<dynamic>)) {
      // lib/server/calendar.v1/syncv1.dart
      final nonce = elm["nonce"];
      final title = elm["title"];
      final eventStart = elm["eventStart"];
      final eventEnd = elm["eventEnd"];
      final about = elm["about"];
      var cEvt = p3pCalendarEventBox
          .query(P3pCalendarEvent_.nonce.equals(nonce))
          .build()
          .findFirst();
      if (cEvt == null) {
        appendLog += """
---------
# $title

| Start date | End date |
| ---------- | -------- |
| $eventStart | $eventEnd |

```md
${about.toString().replaceAll("```", r"\`\`\`")}
```
""";
        cEvt = P3pCalendarEvent(
            userId: groupU.id, title: "===deleted===", about: "");

        cEvt.eventStart = DateTime.fromMicrosecondsSinceEpoch(0);
        cEvt.eventEnd = DateTime.fromMicrosecondsSinceEpoch(0);
        cEvt.about = "";
        cEvt.deleted = true;
        cEvt.title = "===deleted===";
        p3pCalendarEventBox.put(cEvt);
        final syncEvt =
            await Event.newCalendarGroupSync(groupU, group.groupPrivatePgp);
        syncEvt.id = u.queueSendEvent(syncEvt);
        p3pCalendarEventBox.remove(cEvt.id);
      }
    }
    await ssmdcv1ServiceRespond(
      group,
      req,
      """Unable to add event. Reason: You are not a calendar moderator. \n\n\n\n\n\n\n> note: Forcing sync to make sure that your calendar won't be out of sync\n\n\n$appendLog""",
      u,
    );
    final syncEvt =
        await Event.newCalendarGroupSync(groupU, group.groupPrivatePgp);
    syncEvt.id = u.queueSendEvent(syncEvt);
    return json({"ok": true});
  }

  for (var elm in (req["body"]["body"]["data"] as List<dynamic>)) {
    // lib/server/calendar.v1/syncv1.dart
    final nonce = elm["nonce"];
    final title = elm["title"];
    final eventStart = elm["eventStart"];
    final eventEnd = elm["eventEnd"];
    final about = elm["about"];
    var cEvt = p3pCalendarEventBox
        .query(P3pCalendarEvent_.nonce.equals(nonce))
        .build()
        .findFirst();
    cEvt ??= P3pCalendarEvent(userId: groupU.id, title: title, about: about);
    cEvt.title = title;
    cEvt.nonce = nonce;
    cEvt.eventStart = DateTime.parse(eventStart);
    cEvt.eventEnd = DateTime.parse(eventEnd);
    cEvt.about = about +
        "\n - :pencil: " +
        formatDate(DateTime.now(), [
          yyyy,
          "/",
          mm,
          "/",
          dd,
          ' ',
          HH,
          ':',
          nn,
        ]) +
        " by [${u.name}](${u.connmethod}://${u.connstring})";
    cEvt.id = p3pCalendarEventBox.put(cEvt);
    final syncEvt =
        await Event.newCalendarGroupSync(groupU, group.groupPrivatePgp);
    syncEvt.id = u.queueSendEvent(syncEvt);
    group.broadcastToAll(syncEvt, null);
  }

  // We do not need to notify on this I think.. as this could cause duplicates.
  // notify(msg.id, u.name, utf8.decode(msg.data));
  return json({"ok": true});
}
