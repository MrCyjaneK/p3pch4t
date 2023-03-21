import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:p3pch4t/classes/downloadqueue.dart';
import 'package:p3pch4t/classes/fileevt.dart';
import 'package:p3pch4t/classes/message.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:random_string/random_string.dart';
import 'package:path/path.dart' as p;

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
      var newDi = downloadItemBox.query(DownloadItem_.fileEvtId.equals(widget.fileEvt.id)).build().findFirst();

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
      final mime = lookupMimeType(widget.fileEvt.filename, headerBytes: headerBytes).toString();
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
