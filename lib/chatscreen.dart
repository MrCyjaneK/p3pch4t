import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:duration/duration.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:p3pch4t/classes/downloadqueue.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/classes/fileevt.dart';
import 'package:p3pch4t/classes/message.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/helpers/themes.dart';
import 'package:p3pch4t/messagepage.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:p3pch4t/profilepage.dart';
import 'package:p3pch4t/server/p3pmd.dart';
import 'package:p3pch4t/usercalendarpage.dart';
import 'package:p3pch4t/userfilemanager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:path/path.dart' as p;
import 'package:random_string/random_string.dart';

import 'package:mime/mime.dart';

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

  void loadMessages() async {
    int len = msgs.length;
    setState(() {
      msgs = messageBox
          .query(Message_.userId.equals(u.id))
          .build()
          .find()
          .reversed
          .toList();
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
    // Future.delayed(const Duration(seconds: 1)).then((value) {
    //   scrollCtrl.jumpTo(
    //     scrollCtrl.position.maxScrollExtent,
    //   );
    // });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
      } else {
        loadMessages();
      }
    });
    super.initState();
  }

  final ScrollController scrollCtrl = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: u.backgroundColor,
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
              scale: 2, // scale for nicer view
              repeat: ImageRepeat.repeat,
              color: u.backgroundColor,
              opacity: (u.backgroundColor == null)
                  ? null
                  : const AlwaysStoppedAnimation(
                      0.5,
                    ),
            ),
          ),
          //SvgPicture.asset("assets/backgrounds/jigsaw.svg"),
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
                        evt = eventBox
                            .query(Event_.uid.equals(msg.eventUid!))
                            .build()
                            .findFirst();
                      }
                      String append = "";
                      if (evt != null) {
                        if (evt.relayTries > 5) {
                          append =
                              "\nWe have tried to deliver this message ${evt.relayTries} times and still were unable to do so. Probably the contact is offline, we will continue trying.";
                        } else {
                          append = "\nSending...";
                        }
                      }
                      switch (msg.type) {
                        case "file.v1":
                          return _fileV1Tile(msg, evt, append);
                        case "text.v1":
                        default:
                          return _textV1Tile(msg, evt, append);
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
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontFamily: "monospace"),
                        ),
                      ),
                      if (msgCtrl.text.isEmpty)
                        IconButton(
                          onPressed: () async {
                            if (!(await doPlatformFStask())) {
                              return;
                            }
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
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

  Widget _fileV1Tile(Message msg, Event? evt, String append) {
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
    FileEvt? fileEvt =
        fileevtBox.query(FileEvt_.msgId.equals(msg.id)).build().findFirst();
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

  Widget _textV1Tile(Message msg, Event? evt, String append) {
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
      msgTxt =
          "[:warning: ` Fatal delivery error!`](alert:?title=Unable%20to%20deliver%20event.&body=${Uri.encodeQueryComponent(evt!.errorMessage!)})\n\n+$msgTxt";
    }
    if (msg.originName != null) {
      limit += 2;
      msgTxt =
          "[`${msg.originName}`](${msg.originConnmethod}://${msg.originConnstring})\n\n$msgTxt";
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
                      _editMessageDialog(msgTxt, msg);
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
                      tersity: _getTeristy(
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

  Future<dynamic> _editMessageDialog(String msgTxt, Message msg) {
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
}

DurationTersity _getTeristy(Duration difference) {
  if (difference.inMinutes < 1) {
    return DurationTersity.second;
  } else if (difference.inHours < 24) {
    return DurationTersity.minute;
  } else if (difference.inHours < 48) {
    return DurationTersity.hour;
  } else {
    return DurationTersity.day;
  }
}

class FileDownloadButton extends StatefulWidget {
  const FileDownloadButton({
    Key? key,
    required this.fileEvt,
    required this.msg,
  }) : super(key: key);

  final FileEvt fileEvt;
  final Message msg;
  @override
  _FileDownloadButtonState createState() => _FileDownloadButtonState();
}

class _FileDownloadButtonState extends State<FileDownloadButton> {
  late DownloadItem? di;

  void loadDi() async {
    if (widget.msg.isSelf) {
      setState(() {
        di = DownloadItem(
          fileEvtId: widget.fileEvt.id,
          filePath: widget.fileEvt.localPath.toString(),
        );
      });
    } else {
      var newDi = downloadItemBox
          .query(DownloadItem_.fileEvtId.equals(widget.fileEvt.id))
          .build()
          .findFirst();

      setState(() {
        di = newDi;
      });
    }
    if (di?.isDownloaded == true) {
      List<int> tmp = [];
      await File(di!.filePath).openRead(0, 512).forEach((element) {
        tmp.addAll(element);
      });
      if (!mounted) {
        return;
      }
      setState(() {
        headerBytes = tmp;
      });
    }
  }

  @override
  void initState() {
    loadDi();
    super.initState();
  }

  List<int> headerBytes = [];

  @override
  Widget build(BuildContext context) {
    if (di == null) {
      return SizedBox(
        width: double.maxFinite,
        child: OutlinedButton.icon(
          onPressed: () async {
            di ??= DownloadItem(
              fileEvtId: widget.fileEvt.id,
              filePath: p.join(
                (await getApplicationDocumentsDirectory()).path,
                randomAlphaNumeric(16),
              ),
            );
            di!.id = downloadItemBox.put(di!);
            loadDi();
          },
          icon: const Icon(Icons.download),
          label: const Text("Download file"),
        ),
      );
    } else if (!di!.isDownloaded) {
      return SizedBox(
        width: double.maxFinite,
        child: Column(
          children: [
            LinearProgressIndicator(
              value: di?.progress,
            ),
            SizedBox(
              width: double.maxFinite,
              child: OutlinedButton.icon(
                onPressed: () {
                  File(di!.filePath).deleteSync();
                  downloadItemBox.remove(di!.id);
                  loadDi();
                },
                icon: const Icon(Icons.cancel),
                label: const Text("Cancel download"),
              ),
            ),
          ],
        ),
      );
    } else {
      final mime =
          lookupMimeType(widget.fileEvt.filename, headerBytes: headerBytes)
              .toString();
      return SizedBox(
        width: double.maxFinite,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await OpenFilex.open(di?.filePath);
                    },
                    child: const Text("Open"),
                  ),
                ),
                if (!widget.msg.isSelf)
                  IconButton(
                    onPressed: () {
                      File(di!.filePath).deleteSync();
                      downloadItemBox.remove(di!.id);
                      loadDi();
                    },
                    icon: const Icon(Icons.delete),
                  ),
              ],
            ),
            if (kDebugMode) SelectableText(mime),
            if (kDebugMode) SelectableText(di!.filePath.toString()),
            if (mime.startsWith("image/")) Image.file(File(di!.filePath)),
          ],
        ),
      );
    }
  }
}

Future<bool> doPlatformFStask() async {
  if (Platform.isAndroid) {
    var filesStatus = await Permission.manageExternalStorage.status;
    if (filesStatus.isGranted) {
      return true;
    }
    filesStatus = await Permission.manageExternalStorage.request();
    if (filesStatus.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return false;
  }
  return true;
}
