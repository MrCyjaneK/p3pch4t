import 'dart:convert';

import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/classes/message.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/helpers/getTersity.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:p3pch4t/pages/chat/messagepage.dart';
import 'package:p3pch4t/transport/server/p3pmd.dart';

Widget TextV1tile(BuildContext context, Message msg, Event? evt, String append, User u, dynamic setState) {
  Color? tileColor;
  if (evt == null) {
    tileColor = null;
  } else if (evt.relayTries <= 1) {
    tileColor = null;
  } else if (evt.relayTries <= 5) {
    tileColor = Colors.orange;
  } else {
    tileColor = Colors.red;
  }
  var msgTxtFull = utf8.decode(msg.data);
  var msgTxt = utf8.decode(msg.data);
  int limit = 6;
  if (evt?.errorMessage != null) {
    msgTxt = "[:warning: ` Fatal delivery error!`](alert:?title=Unable%20to%20deliver%20event.&body=${Uri.encodeQueryComponent(evt!.errorMessage!)})\n\n+$msgTxt";
  }
  if (msg.originName != null) {
    limit += 2;
    msgTxt = "[`${msg.originName}`](${msg.originConnmethod}://${msg.originConnstring})\n\n$msgTxt";
  }
  bool isShownFull = (msgTxt.split("\n").length < limit);
  if (!isShownFull) {
    msgTxt = msgTxt.split("\n").take(limit - 1).join("\n");
  }
  return Padding(
    padding: EdgeInsets.only(
      left: msg.isSelf ? 32 : 0,
      right: msg.isSelf ? 0 : 32,
    ),
    child: Card(
      child: Column(
        children: [
          ListTile(
            onTap: msg.isSelf
                ? () {
                    editMessageDialog(context, msgTxt, msg, u, setState);
                  }
                : () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return const AlertDialog(
                          title: Text("TODO: reactions"),
                        );
                      },
                    );
                  },
            tileColor: tileColor,
            title: Stack(
              children: [
                if (evt?.isRelayed == false)
                  LinearProgressIndicator(
                    color: tileColor ?? u.backgroundColor,
                  ),
                p3pMd(msgTxt: msgTxt),
              ],
            ),
            subtitle: Row(
              children: [
                SelectableText(
                  prettyDuration(
                    DateTime.now().difference(msg.time),
                    tersity: getTeristy(
                      DateTime.now().difference(msg.time),
                    ),
                  ),
                ),
                if (!isShownFull)
                  TextButton(
                    onPressed: isShownFull
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return MessagePage(
                                    u: u,
                                    msgTxt: msgTxtFull,
                                  );
                                },
                              ),
                            );
                          },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(),
                    ),
                    child: const Text("show full"),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<dynamic> editMessageDialog(BuildContext context, String msgTxt, Message msg, User u, dynamic setState) {
  return showDialog(
    context: context,
    builder: (context) {
      final editCtrl = TextEditingController(text: msgTxt);
      return AlertDialog(
        title: const Text("Edit message"),
        content: TextField(
          controller: editCtrl,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'New message content',
          ),
        ),
        actions: [
          SizedBox(
            width: double.maxFinite,
            child: OutlinedButton.icon(
              onPressed: () {
                final newJson = Event.newTextMessage(editCtrl.text).json;
                newJson["nonce"] = msg.nonce;
                final newEvt = Event(
                  jsonBody: jsonEncode(newJson),
                  privKey: prefs.getString("privkey")!,
                );
                newEvt.id = u.queueSendEvent(newEvt);
                msg.data = base64Decode(newEvt.json["data"]);
                messageBox.put(msg);
                setState(() {});
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.send),
              label: const Text("Update"),
            ),
          ),
        ],
      );
    },
  );
}
