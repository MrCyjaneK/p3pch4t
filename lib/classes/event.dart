import 'dart:convert';

import 'package:openpgp/openpgp.dart' as pgp;
import 'package:p3pch4t/classes/fileevt.dart';
import 'package:p3pch4t/classes/ssmdc.v1/groupconfig.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/helpers/consts.dart';
import 'package:p3pch4t/helpers/pgp.dart';
import 'package:p3pch4t/objectbox.g.dart';
// ignore: unnecessary_import
import 'package:objectbox/objectbox.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:random_string/random_string.dart';

@Entity()
class Event {
  Event({
    required this.jsonBody,
    required this.privKey,
  });
  @Id()
  int id = 0;

  @Index()
  String uid = randomAlphaNumeric(16);

  bool isRelayed = false;

  String jsonBody;

  @Index()
  String privKey;

  @Property(type: PropertyType.date)
  DateTime creationDate = DateTime.now();
  @Property(type: PropertyType.date)
  DateTime lastRelayed = DateTime.now();

  String? errorMessage;

  int relayTries = 0;

  @Transient()
  Map<String, dynamic> get json {
    return jsonDecode(jsonBody);
  }

  ToMany<User> destinations = ToMany<User>();

  Future<Map<String, dynamic>> toJson() async {
    final String selfPublicKey = await pgp.OpenPGP.convertPrivateKeyToPublicKey(
      privKey,
    );
    return {
      "senderpgp": selfPublicKey,
      "signature": await pgp.OpenPGP.sign(
        jsonBody,
        selfPublicKey,
        privKey,
        passpharse,
      ),
      "body": jsonBody,
    };
  }

  Future<bool> trySend(List<String> connstringSkipList) async {
    lastRelayed = DateTime.now();
    eventBox.put(this);
    List<int> toDel = [];
    await send(connstringSkipList).forEach((element) {
      if (element.startsWith("ok,")) {
        toDel.add(int.parse(element.replaceAll("ok,", "")));
      }
    });
    print("removing elms: ${jsonEncode(toDel)}");
    for (var elm in toDel) {
      destinations.removeWhere((element) => element.id == elm);
      eventBox.put(this);
    }
    if (destinations.isEmpty) {
      isRelayed = true;
      eventBox.put(this);
    }
    return isRelayed;
  }

  Stream<String> send(List<String> connstringSkipList) async* {
    for (var dest in destinations) {
      if (dest.publicKey == null) continue;
      if (connstringSkipList.contains(dest.connstring)) continue;
      if (dest.connmethod == "i2p") {
        yield await dest.sendEvent(this);
      } else {
        print("dest.connmethod != i2p? What should I do?");
      }
    }
    return;
  }

  static Event newTextMessage(
    String message,
  ) {
    final evt = Event(
      privKey: prefs.getString("privkey")!,
      jsonBody: jsonEncode({
        "type": "text.v1",
        "nonce": randomAlphaNumeric(64),
        "data": base64Encode(utf8.encode(message)),
      }),
    );
    return evt;
  }

  static Future<Event> newFileMessage(FileEvt fevt, User u) async {
    return Event(
      privKey: prefs.getString("privkey")!,
      jsonBody: jsonEncode({
        "type": "file.v1",
        "nonce": randomAlphaNumeric(64),
        "data": {
          "endpoint":
              '${prefs.getString("connstring")!.replaceAll("i2p://", "http://")}/file.v1/${u.uid}/${fevt.uid}/\$start/\$end',
          "filename": fevt.filename,
          "filesize": fevt.filesize,
          "caption": fevt.caption,
          "checksum": {
            "sha1": fevt.sha1sum,
            "sha256": fevt.sha256sum,
            "sha512": fevt.sha512sum,
            "md5": fevt.md5sum
          },
        },
      }),
    );
  }

  static Future<Event> newCalendarSync(User u) async {
    return Event(
      privKey: prefs.getString("privkey")!,
      jsonBody: jsonEncode({
        "type": "calendar.v1.sync.v1",
        "nonce": randomAlphaNumeric(64),
        "data": p3pCalendarEventBox
            .query(P3pCalendarEvent_.userId.equals(u.id))
            .build()
            .find(),
      }),
    );
  }

  static Future<Event> newCalendarGroupSync(User u, String privKey) async {
    return Event(
      privKey: privKey,
      jsonBody: jsonEncode({
        "type": "calendar.v1.sync.v1",
        "nonce": randomAlphaNumeric(64),
        "data": p3pCalendarEventBox
            .query(P3pCalendarEvent_.userId.equals(u.id))
            .build()
            .find(),
      }),
    );
  }

  static Future<Event> newSsmdcv1Introduction(
      User u, SSMDCv1GroupConfig group) async {
    final String selfPublicKey = await pgp.OpenPGP.convertPrivateKeyToPublicKey(
      prefs.getString("privkey")!,
    );
    final evt = Event(
      privKey: group.groupPrivatePgp,
      jsonBody: jsonEncode({
        "type": "introduce.v1",
        "nonce": randomAlphaNumeric(64),
        "data": {
          "senderpgp": await group.groupPublicKey(),
          "connstring": group.getGroupConnstring().replaceFirst("i2p://", ''),
          "connmethod": "i2p",
          "username": group.name,
          "bio": group.about,
          "backgroundColor": group.rawBackgroundColor,
          "backgroundAsset": group.chatBackgroundAsset,
          "supportedEvents": ssmdcv1SupportedEvents,
        },
      }),
    );
    return evt;
  }

  static Future<Event> newIntroduction(User u) async {
    await prefs.reload();
    final String selfPublicKey = await pgp.OpenPGP.convertPrivateKeyToPublicKey(
      prefs.getString("privkey")!,
    );
    final evt = Event(
      privKey: prefs.getString("privkey")!,
      jsonBody: jsonEncode({
        "type": "introduce.v1",
        "nonce": randomAlphaNumeric(64),
        "data": {
          "senderpgp": selfPublicKey,
          "connstring": prefs.getString("connstring"),
          "connmethod": "i2p",
          "username": prefs.getString("username"),
          "bio": prefs.getString("bio"),
          "backgroundColor": u.rawBackgroundColor,
          "backgroundAsset": u.chatBackgroundAsset,
          "supportedEvents": supportedEvents,
        },
      }),
    );
    return evt;
  }
}
