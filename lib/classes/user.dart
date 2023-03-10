import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:i2p_flutter/i2p_flutter.dart';
import 'package:objectbox/objectbox.dart';
import 'package:openpgp/openpgp.dart' as pgp;
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/helpers/pgp.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:random_string/random_string.dart';

@Entity()
class User {
  User({
    required this.connstring,
    required this.connmethod,
  });

  @Id()
  int id = 0;

  String name = "[Unknown] ${DateTime.now().toIso8601String()}";
  String? publicKey;

  String uid = randomAlphaNumeric(16);

  // -     notification settings
  bool notifyOnAll = true;
  bool notifyOnTag = true;
  bool notifyOnEveryone = true;
  bool notifyOnCalendarEventsAdded = true;
  String notifyCustomTags = "";
  // - end notification settings

  @Property(type: PropertyType.date)
  DateTime firstSeen = DateTime.now();

  @Property(type: PropertyType.date)
  DateTime lastSeen = DateTime.now();
  String connstring;
  String connmethod; // "i2p", ???

  List<String>? supportedEvents;

  String bio = "";

  @Property(type: PropertyType.date)
  DateTime lastIntroduced = DateTime.fromMicrosecondsSinceEpoch(0);

  @Transient()
  bool get isIntroduced {
    return (DateTime.now().difference(lastIntroduced).inSeconds < 60 * 60 * 12);
  }

  @Transient()
  set isIntroduced(bool val) {
    if (val) {
      lastIntroduced = DateTime.now();
    } else {
      lastIntroduced = DateTime.fromMicrosecondsSinceEpoch(0);
    }
  }

  int? rawBackgroundColor;

  @Transient()
  Color? get backgroundColor {
    if (rawBackgroundColor == null) return null;
    return Color(rawBackgroundColor!);
  }

  Future<String> sendEvent(Event evt) async {
    print("Sending event to $connmethod, $connstring : ${evt.relayTries}");
    evt.lastRelayed = DateTime.now();
    evt.relayTries++;
    eventBox.put(evt);
    if (publicKey == null) {
      print("No public key LOL!...");
      await selfPgp();
      return "No public key!";
    }

    var bodyJson = await evt.toJson();
    var encBody = await pgp.OpenPGP.encrypt(jsonEncode(bodyJson), publicKey!);
    Response? resp;
    try {
      // resp = await http.post(
      //   Uri.parse("http://$connstring/core/event"),
      //   body: encBody,
      // );
      resp = await i2pFlutterPlugin.dio().post(
            "http://$connstring/core/event",
            data: encBody,
            options: Options(
                responseType: ResponseType.plain,
                receiveDataWhenStatusError: true),
          );
    } catch (e) {
      print(e);
      if (e is DioError) {
        resp = e.response;

        late String delayedMsg = "";
        if (!resp.toString().contains(r"<title>I2Pd HTTP proxy</title>") &&
            resp.toString() != "null") {
          evt.lastRelayed = evt.lastRelayed.add(const Duration(minutes: 30));
          delayedMsg = "30 minutes";
        } else {
          delayedMsg = "5 minutes";
          evt.lastRelayed = evt.lastRelayed.add(const Duration(minutes: 5));
        }
        evt.errorMessage =
            "Unable to deliver event. Reason:\n\n```html\n$resp\n```\n\n------\nDelayed event by $delayedMsg hours to avoid flooding contact.\n :alarm_clock: ${DateTime.now().toIso8601String()}";
        eventBox.put(evt);
      }
      if (resp == null) {
        print("null - returning");
      }
      // prefs.setString(
      //   "lastLog",
      //   "${prefs.getString("lastLog")}\nEvent: ${const JsonEncoder.withIndent('    ').convert(evt.json)}\nE: $e",
      // );
      return "Unable to deliver: $e";
    }
    dynamic respBody = {"ok": false, "message": resp.data};
    try {
      respBody = jsonDecode(resp.data);
    } catch (e) {
      prefs.setString(
        "lastLog",
        "${prefs.getString("lastLog")}\nEvent: ${const JsonEncoder.withIndent('    ').convert(evt.json)}\nE: $e",
      );
    }
    if (respBody["ok"] == true) {
      print("sent and delivered");
      return "ok,$id";
    }
    print("sent but not delivered, response:");
    prefs.setString(
      "lastLog",
      "${prefs.getString("lastLog")}\nEvent: ${const JsonEncoder.withIndent('    ').convert(evt.json)}",
    );
    print(respBody);
    return "ok,$id"; // note: malfunctioning clients.
    // return "Sent but not delivered";
  }

  String? chatBackgroundAsset;

  Future<void> introduce() async {
    final introduceEvent = await Event.newIntroduction(this);
    queueSendEvent(introduceEvent);
    await sendEvent(introduceEvent);
  }

  Future<void> selfPgp() async {
    //var resp = await  http.read(Uri.parse("http://$connstring/core/selfpgp"));
    var resp = await i2pFlutterPlugin.dio().get(
          "http://$connstring/core/selfpgp",
          options: Options(
            responseType: ResponseType.plain,
            sendTimeout: const Duration(seconds: 15),
          ),
        );
    String ok = await pgp.OpenPGP.sign(
      DateTime.now().toIso8601String(),
      resp.data,
      prefs.getString("privkey")!,
      passpharse,
    );
    if (ok.isNotEmpty) {
      publicKey = resp.data;
      id = userBox.put(this);
      queueSendEvent(await Event.newIntroduction(this));
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "publicKey": publicKey,
      "lastSeen": lastSeen.toIso8601String(),
      "connstring": connstring,
      "connmethod": connmethod,
    };
  }

  int queueSendEvent(Event evt) {
    evt.destinations.add(this);
    return eventBox.put(evt);
  }
}
