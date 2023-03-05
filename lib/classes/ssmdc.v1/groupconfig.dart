// NOTE: This is only used on group servers, clients should treat groups
// just like they treat normal chats. Backwards compatibility is a nice
// thing to have. Please don't break the idea of a working chat app with
// breaking changes. Unless required.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:openpgp/openpgp.dart' as pgp;
import 'package:p3pch4t/helpers/pgp.dart';
import 'package:p3pch4t/objectbox.g.dart';
// ignore: unnecessary_import
import 'package:objectbox/objectbox.dart';
import 'package:p3pch4t/prefs.dart';

@Entity()
class SSMDCv1GroupConfig {
  SSMDCv1GroupConfig({
    required this.name,
    required this.uid,
  });
  @Id()
  int id = 0;

  String name;
  String uid;

  String about = "This is group about stuff";

  String welcomeMessage =
      r"Welcome to **$groupname** `$username`! You are our `$usersCount` member!";
  String joinMessage = r"`$username` have joined us!";

  String byeMessage =
      r"Goodbye $username! Make sure to remove the group from your chat list to avoid re-joining on introduce.v1";
  String leaveMessage = r"`$username` left the chat";

  bool showWelcomeMessage = true;
  bool showJoinMessage = true;
  bool showByeMessage = true;
  bool showLeaveMessage = true;

  int messageCount = 0;

  ToMany<User> userList = ToMany<User>();

  int? rawBackgroundColor;

  @Transient()
  Color? get backgroundColor {
    if (rawBackgroundColor == null) return null;
    return Color(rawBackgroundColor!);
  }

  @Transient()
  set backgroundColor(Color? color) {
    if (color == null) rawBackgroundColor = null;
    rawBackgroundColor = color!.value;
  }

  String rawBanList = "";

  @Transient()
  List<int> get banList {
    List<int> ret = [];
    rawBanList.split(",").forEach((elm) {
      int? i = int.tryParse(elm);
      if (i != null) ret.add(i);
    });
    return ret;
  }

  @Transient()
  set banList(List<int> newBanList) {
    rawBanList = newBanList.join(",");
  }

  void banUser(User u) async {
    if (!banList.contains(u.id)) {
      final newBanList = banList;
      newBanList.add(u.id);
      banList = newBanList;
      final req = Event.newTextMessage("${u.name} got banned!").json;

      req["origin"] = {
        "name": "$name (service)",
      };
      final Event evt = Event(
        jsonBody: jsonEncode(req),
        privKey: groupPrivatePgp,
      );
      broadcastToAll(evt, null);

      userList.removeWhere((element) => element.id == u.id);
    }
    ssmdcv1GroupConfigBox.put(this);
  }

  void unbanUser(User u) {
    if (banList.contains(u.id)) {
      final newBanList = banList;
      newBanList.removeWhere((element) => element == u.id);
      banList = newBanList;
    }
    ssmdcv1GroupConfigBox.put(this);
  }

  bool isUserBanned(User u) {
    return banList.contains(u.id);
  }

  String rawAdminList = "";

  @Transient()
  List<int> get adminList {
    List<int> ret = [];
    rawAdminList.split(",").forEach((elm) {
      int? i = int.tryParse(elm);
      if (i != null) ret.add(i);
    });
    return ret;
  }

  @Transient()
  set adminList(List<int> newAdminList) {
    rawAdminList = newAdminList.join(",");
  }

  void adminUser(User u) async {
    if (!adminList.contains(u.id)) {
      final newAdminList = adminList;
      newAdminList.add(u.id);
      adminList = newAdminList;
      final req = Event.newTextMessage("${u.name} got promoted to admin!").json;

      req["origin"] = {
        "name": "$name (service)",
      };
      final Event evt = Event(
        jsonBody: jsonEncode(req),
        privKey: groupPrivatePgp,
      );
      broadcastToAll(evt, null);
    }
    ssmdcv1GroupConfigBox.put(this);
  }

  void unadminUser(User u) {
    if (banList.contains(u.id)) {
      final newAdminList = adminList;
      newAdminList.removeWhere((element) => element == u.id);
      adminList = newAdminList;
    }
    ssmdcv1GroupConfigBox.put(this);
  }

  bool isUserAdmin(User u) {
    return adminList.contains(u.id);
  }

  late String groupPrivatePgp;

  int getPendingEvents() {
    List<Event> groupEvents =
        eventBox.query(Event_.privKey.equals(groupPrivatePgp)).build().find();
    return groupEvents.length;
  }

  Future<String> groupPublicKey() async {
    return await pgp.OpenPGP.convertPrivateKeyToPublicKey(groupPrivatePgp);
  }

  Future<void> generateGroupPgp(String groupEmail, String groupName) async {
    var keyOptions = pgp.KeyOptions()
      ..rsaBits = 4096
      ..algorithm = pgp.Algorithm.RSA;
    var keyPair = await pgp.OpenPGP.generate(
      options: pgp.Options()
        ..name = name
        ..email = groupEmail
        ..passphrase = passpharse
        ..keyOptions = keyOptions,
    );
    groupPrivatePgp = keyPair.privateKey;
  }

  Future<void> broadcastToAll(Event evt, User? except) async {
    evt.privKey = groupPrivatePgp;
    for (var u in userList) {
      if (u.id == except?.id) {
        continue;
      }
      u.queueSendEvent(evt);
    }
  }

  String getGroupConnstring() {
    return "${prefs.getString("connstring")!}/ssmdc.v1/$uid";
  }
}
