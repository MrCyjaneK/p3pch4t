import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/classes/fileevt.dart';
import 'package:p3pch4t/classes/message.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/helpers/platformfs.dart';
import 'package:p3pch4t/helpers/themes.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:p3pch4t/pages/profilepage.dart';
import 'package:p3pch4t/pages/calendar/main.dart';
import 'package:p3pch4t/pages/files/userfilemanager.dart';
import 'package:p3pch4t/widgets/chat/filev1tile.dart';
import 'package:p3pch4t/widgets/chat/textv1tile.dart';

class ChatScreenPage extends StatefulWidget {
  const ChatScreenPage({Key? key, required this.u}) : super(key: key);

  final User u;

  @override
  State<ChatScreenPage> createState() => _ChatScreenPageState();
}

class _ChatScreenPageState extends State<ChatScreenPage> {
  List<Message> msgs = [];
  final msgCtrl = TextEditingController();
  late User u = widget.u;
  final ScrollController scrollCtrl = ScrollController();

  void loadMessages() async {
    int len = msgs.length;
    setState(() {
      msgs = messageBox.query(Message_.userId.equals(u.id)).build().find().reversed.toList();
    });
    if (len != msgs.length) {
      Future.delayed(const Duration()).then((value) {
        scrollCtrl.jumpTo(
          scrollCtrl.position.minScrollExtent,
        );
      });
    }
  }

  void loadUser() {
    if (!mounted) return;
    setState(() {
      u = userBox.query(User_.id.equals(u.id)).build().findFirst()!;
    });
  }

  @override
  void initState() {
    loadUser();
    loadMessages();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
      } else {
        loadMessages();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: u.backgroundColor,
        foregroundColor: u.backgroundColor == null
            ? null
            : u.backgroundColor!.computeLuminance() > 0.379
                ? Colors.black
                : Colors.white,
        title: Text(u.name),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return UserFileManager(u: u);
                  },
                ),
              );
            },
            icon: const Icon(Icons.folder),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return UserCalendarPage(u: u);
                  },
                ),
              );
            },
            icon: const Icon(Icons.calendar_month),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return ProfilePage(u: u);
                  },
                ),
              );
            },
            icon: const Icon(Icons.info),
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            width: double.maxFinite,
            height: double.maxFinite,
            child: Image.asset(
              getChatBackgroundAsset(u.chatBackgroundAsset),
              scale: 2,
              repeat: ImageRepeat.repeat,
              color: u.backgroundColor,
              opacity: (u.backgroundColor == null)
                  ? null
                  : const AlwaysStoppedAnimation(
                      0.5,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    controller: scrollCtrl,
                    shrinkWrap: true,
                    itemCount: msgs.length,
                    itemBuilder: (context, index) {
                      Message msg = msgs[index];
                      Event? evt;
                      if (msg.eventUid != null) {
                        evt = eventBox.query(Event_.uid.equals(msg.eventUid!)).build().findFirst();
                      }
                      String append = "";
                      if (evt != null) {
                        if (evt.relayTries > 5) {
                          append = "\nWe have tried to deliver this message ${evt.relayTries} times and still were unable to do so. Probably the contact is offline, we will continue trying.";
                        } else {
                          append = "\nSending...";
                        }
                      }
                      switch (msg.type) {
                        case "file.v1":
                          return FileV1Tile(msg: msg, evt: evt, append: append);
                        case "text.v1":
                        default:
                          return TextV1tile(context, msg, evt, append, u, setState);
                      }
                    },
                  ),
                ),
                if (u.publicKey == null)
                  Container(
                    decoration: const BoxDecoration(color: Colors.red),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "No PGP found! The contact is not yet added. You can queue messages but it won't get delivered.",
                      ),
                    ),
                  ),
                Card(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: msgCtrl,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Message',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontFamily: "monospace"),
                        ),
                      ),
                      if (msgCtrl.text.isEmpty)
                        IconButton(
                          onPressed: () async {
                            if (!(await doPlatformFStask())) {
                              return;
                            }
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              allowMultiple: true,
                            );
                            if (result == null) return;
                            for (var file in result.files) {
                              var fevt = await FileEvt.createFromLocal(
                                file.path!,
                                "File upload",
                              );
                              final evt = await Event.newFileMessage(fevt, u);
                              u.queueSendEvent(evt);
                              evt.trySend([]);
                              fevt.msgId = messageBox.put(
                                Message(
                                  eventUid: evt.uid,
                                  userId: u.id,
                                  type: "file.v1",
                                  isTrusted: true,
                                  isSelf: true,
                                  nonce: evt.json["nonce"],
                                  data: utf8.encode(evt.jsonBody) as Uint8List,
                                ),
                              );
                              fileevtBox.put(fevt);
                            }
                          },
                          icon: const Icon(Icons.attach_file),
                        ),
                      if (msgCtrl.text.isNotEmpty)
                        IconButton(
                          onPressed: () async {
                            final evt = Event.newTextMessage(msgCtrl.text);
                            evt.id = u.queueSendEvent(evt);
                            evt.trySend([]);
                            messageBox.put(
                              Message(
                                eventUid: evt.uid,
                                userId: u.id,
                                type: "text.v1",
                                isTrusted: true,
                                isSelf: true,
                                nonce: evt.json["nonce"],
                                data: base64Decode(evt.json["data"]),
                              ),
                            );
                            msgCtrl.clear();
                            loadMessages();
                          },
                          icon: const Icon(Icons.send),
                        ),
                    ],
                  ),
                ),
                if (u.publicKey == null)
                  SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton(
                      onPressed: () async {
                        await u.selfPgp();
                        loadUser();
                      },
                      child: const Text("Request user's PGP key manually"),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
