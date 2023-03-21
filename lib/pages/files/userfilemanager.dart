import 'dart:typed_data';

import 'package:date_format/date_format.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/filev2.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:p3pch4t/pages/files/managefile.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/helpers/prefs.dart';

class UserFileManager extends StatefulWidget {
  const UserFileManager({Key? key, required this.u}) : super(key: key);

  final User u;

  @override
  State<UserFileManager> createState() => _UserFileManagerState();
}

class _UserFileManagerState extends State<UserFileManager> {
  late final User u = widget.u;

  String parentUid = "0";

  @override
  Widget build(BuildContext context) {
    var directoryList = fileV2Box
        .query(
          FileV2_.contentBytes
              .isNull()
              .and(
                FileV2_.parentFile.equals(parentUid),
              )
              .and(
                FileV2_.ownerId.equals(u.id),
              ),
        )
        .order(FileV2_.name)
        .build()
        .find();
    if (parentUid != "0") {
      final f = fileV2Box
          .query(FileV2_.fileUid
              .equals(parentUid)
              .and(FileV2_.ownerId.equals(u.id)))
          .order(FileV2_.name)
          .build()
          .findFirst();
      final dotdotP =
          FileV2(ownerId: u.id, name: "..", parentFile: f?.parentFile ?? "0");
      dotdotP.fileUid = f?.parentFile ?? "0";
      directoryList = [dotdotP, ...directoryList];
    }
    var fileList = fileV2Box
        .query(
          FileV2_.contentBytes
              .notNull()
              .and(
                FileV2_.parentFile.equals(parentUid),
              )
              .and(
                FileV2_.ownerId.equals(u.id),
              ),
        )
        .order(FileV2_.name)
        .build()
        .find();
    var fList = [...directoryList, ...fileList];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Files"),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 8.0, top: 8.0),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: fList.length,
          itemBuilder: (context, index) {
            final file = fList[index];
            return SizedBox(
              width: double.maxFinite,
              child: ListTile(
                onTap: () async {
                  if (file.isDirectory) {
                    setState(() {
                      parentUid = file.fileUid;
                    });
                  } else {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return ManageFile(file: file);
                        },
                      ),
                    );
                    setState(() {});
                  }
                },
                onLongPress: () async {
                  if (file.isDirectory) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return ManageFile(file: file);
                        },
                      ),
                    );
                    setState(() {});
                  }
                },
                leading: Icon(file.isFile ? Icons.file_present : Icons.folder),
                title: Text(
                  file.name,
                  maxLines: 1,
                ),
                subtitle: file.isFile
                    ? SelectableText(
                        "${filesize(file.contentBytes?.length)} / ${filesize(file.knownSize)}")
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {},
                ),
                // subtitle: kDebugMode ? SelectableText(file.fileUid) : null,
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        distance: 65,
        expandedFabSize: ExpandableFabSize.regular,
        type: ExpandableFabType.up,
        children: [
          FloatingActionButton(
            child: const Icon(Icons.create_new_folder),
            onPressed: () {
              final date = formatDate(
                  DateTime.now(), [yyyy, "/", mm, "/", dd, ' ', HH, ':', nn]);
              final fv2 = FileV2(
                  ownerId: u.id,
                  name: "New Folder ($date)",
                  parentFile: parentUid);
              fv2.save();
              setState(() {
                parentUid = parentUid;
              });
            },
          ),
          FloatingActionButton(
            child: const Icon(Icons.file_open),
            onPressed: () {
              final date = formatDate(
                  DateTime.now(), [yyyy, "/", mm, "/", dd, ' ', HH, ':', nn]);
              final fv2 = FileV2(
                  ownerId: u.id,
                  name: "New File ($date)",
                  parentFile: parentUid);
              fv2.contentBytes = Uint8List(0);
              fv2.save();
              setState(() {
                parentUid = parentUid;
              });
            },
          ),
        ],
      ),
    );
  }
}
