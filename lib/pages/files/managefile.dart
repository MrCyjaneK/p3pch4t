import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/helpers/platformfs.dart';
import 'package:p3pch4t/classes/filev2.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:p3pch4t/transport/server/p3pmd.dart';

class ManageFile extends StatefulWidget {
  const ManageFile({Key? key, required this.file}) : super(key: key);

  final FileV2 file;

  @override
  _ManageFileState createState() => _ManageFileState();
}

class _ManageFileState extends State<ManageFile> {
  late final FileV2 file = widget.file;

  var editMode = false;
  late final contentController = TextEditingController(
    text: utf8.decode(file.contentBytes!, allowMalformed: true),
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.name),
      ),
      body: (file.isFile)
          ? Column(
              children: [
                if (file.name.endsWith(".md") && !editMode)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: p3pMd(
                      msgTxt: utf8.decode(file.contentBytes!, allowMalformed: true),
                    ),
                  ),
                if (file.name.endsWith(".md") && editMode)
                  Expanded(
                    child: TextField(
                      controller: contentController,
                      minLines: 60,
                      maxLines: 60,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontFamily: "monospace"),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text("New content"),
                      ),
                    ),
                  ),
                if (file.getMimeType().startsWith("image")) Image.memory(file.contentBytes!),
              ],
            )
          : const Center(
              child: Text("Directory"),
            ),
      bottomNavigationBar: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              child: const Text("Remove"),
              onPressed: () {
                fileV2Box.remove(file.id);
                Navigator.of(context).pop();
              },
            ),
          ),
          Expanded(
            child: OutlinedButton(
              child: const Text("Rename"),
              onPressed: () {
                final textController = TextEditingController(text: file.name);
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Rename"),
                      content: TextField(
                        controller: textController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text("New name"),
                        ),
                      ),
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              file.name = textController.text;
                            });
                            file.save();
                          },
                          icon: const Icon(Icons.save),
                          label: const Text("Save"),
                        )
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (file.isFile && file.name.endsWith(".md"))
            Expanded(
              child: OutlinedButton(
                child: Text(!editMode ? "Edit" : "Save"),
                onPressed: () {
                  if (editMode) {
                    file.contentBytes = utf8.encode(contentController.text) as Uint8List;
                    file.save();
                  }
                  setState(() {
                    editMode = !editMode;
                  });
                },
              ),
            ),
          if (file.isFile && !file.name.endsWith(".md"))
            Expanded(
              child: OutlinedButton(
                child: const Text("Replace"),
                onPressed: () async {
                  if (!(await doPlatformFStask())) {
                    return;
                  }
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    allowMultiple: false,
                    withData: true,
                  );
                  if (result == null) return;
                  file.contentBytes = result.files.single.bytes!;
                  file.name = result.files.single.name;
                  file.save();
                  setState(() {});
                },
              ),
            )
        ],
      ),
    );
  }
}
