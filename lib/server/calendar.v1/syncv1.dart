import 'dart:math';

import 'package:p3pch4t/classes/calendar.v1/calendarevent.dart';
import 'package:p3pch4t/classes/privkey.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:p3pch4t/server/chat_server.dart';
import 'package:p3pch4t/server/notify.dart';
import 'package:shelf/shelf.dart';

Future<Response> handleCalendarV1SyncV1(Map<String, dynamic> req) async {
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
  if (u.publicKey == (await getSelfPubKey()).publicKey) {
    return json({"ok": true}); // Simply ignore local event.
  }
  for (var elm in (req["body"]["body"]["data"] as List<dynamic>)) {
    //  "nonce": nonce,
    //  "title": title,
    //  "eventStart": eventStart,
    //  "eventEnd": eventEnd,
    //  "about": about,
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
      notify(3782532 + Random().nextInt(5555), "${u.id}.calendar.v1",
          "${u.name} calendar", "📅${u.name}", title);
      cEvt = P3pCalendarEvent(userId: u.id, title: title, about: about);
    }
    cEvt.title = title;
    cEvt.nonce = nonce;
    cEvt.eventStart = DateTime.parse(eventStart);
    cEvt.eventEnd = DateTime.parse(eventEnd);
    cEvt.about = about;
    cEvt.id = p3pCalendarEventBox.put(cEvt);
  }

  return json({"ok": true});
}
