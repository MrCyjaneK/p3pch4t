import 'dart:convert';

import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/classes/fileevt.dart';
import 'package:p3pch4t/classes/message.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/widgets/chat/filedownload.dart';

class FileV1Tile extends StatelessWidget {
  const FileV1Tile({
    super.key,
    required this.msg,
    required this.evt,
    required this.append,
  });

  final Message msg;
  final Event? evt;
  final String append;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = {"a": "b"};
    try {
      data = jsonDecode(utf8.decode(msg.data));
    } catch (e) {
      return Padding(
        padding: EdgeInsets.only(
          left: msg.isSelf ? 32 : 0,
          right: msg.isSelf ? 0 : 32,
        ),
        child: Card(
          child: ListTile(
            tileColor: Colors.red,
            title: const SelectableText("Error occured!"),
            subtitle: SelectableText("$e"),
          ),
        ),
      );
    }
    if (data["data"] == null) {
      return Padding(
        padding: EdgeInsets.only(
          left: msg.isSelf ? 32 : 0,
          right: msg.isSelf ? 0 : 32,
        ),
        child: const Card(
          child: ListTile(
            tileColor: Colors.red,
            title: SelectableText("Error occured!"),
            subtitle: SelectableText("data[\"data\"] == null"),
          ),
        ),
      );
    }
    FileEvt? fileEvt = fileevtBox.query(FileEvt_.msgId.equals(msg.id)).build().findFirst();
    if (fileEvt == null) {
      return const Text("fileEvt == null. File is missing");
    }
    return Padding(
      padding: EdgeInsets.only(
        left: msg.isSelf ? 32 : 0,
        right: msg.isSelf ? 0 : 32,
      ),
      child: Card(
        child: ListTile(
          tileColor: (Event? evt) {
            if (evt == null) return null;
            if (evt.relayTries <= 1) return null;
            if (evt.relayTries <= 5) return Colors.orange;
            return Colors.red;
          }(evt),
          title: SelectableText(data["data"]["filename"]),
          subtitle: Column(
            children: [
              // if (kDebugMode) SelectableText(jsonEncode(data["data"])),
              SelectableText("size: ${filesize(data["data"]["filesize"])}"),

              FileDownloadButton(
                fileEvt: fileEvt,
                msg: msg,
              ),
              SelectableText("${msg.time.toIso8601String()}$append"),
            ],
          ),
        ),
      ),
    );
  }
}
