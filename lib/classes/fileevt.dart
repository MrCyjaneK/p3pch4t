import 'dart:io';

import 'package:p3pch4t/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:random_string/random_string.dart';
import 'package:path/path.dart' as p;
import 'package:async/async.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

@Entity()
class FileEvt {
  FileEvt({
    required this.filename,
    required this.caption,
    required this.filesize,
    this.msgId,
    this.endpoint,
    this.sha1sum,
    this.sha256sum,
    this.sha512sum,
    this.md5sum,
    this.localPath,
  });

  @Id()
  int id = 0;

  String? endpoint;
  String filename;
  String caption;
  int filesize;

  String? sha1sum;
  String? sha256sum;
  String? sha512sum;
  String? md5sum;

  Future<void> calculateChecksums() async {
    if (localPath == null) return;
    final reader = ChunkedStreamReader(File(localPath!).openRead());
    const chunkSize = 4096;
    var outputsha1sum = AccumulatorSink<Digest>();
    var inputsha1sum = sha1.startChunkedConversion(outputsha1sum);
    var outputsha256sum = AccumulatorSink<Digest>();
    var inputsha256sum = sha256.startChunkedConversion(outputsha256sum);
    var outputsha512sum = AccumulatorSink<Digest>();
    var inputsha512sum = sha512.startChunkedConversion(outputsha512sum);
    var outputmd5sum = AccumulatorSink<Digest>();
    var inputmd5sum = md5.startChunkedConversion(outputmd5sum);

    try {
      while (true) {
        final chunk = await reader.readChunk(chunkSize);
        if (chunk.isEmpty) {
          // indicate end of file
          break;
        }
        inputsha1sum.add(chunk);
        inputsha256sum.add(chunk);
        inputsha512sum.add(chunk);
        inputmd5sum.add(chunk);
      }
    } finally {
      // We always cancel the ChunkedStreamReader,
      // this ensures the underlying stream is cancelled.
      reader.cancel();
    }
    inputsha1sum.close();
    inputsha256sum.close();
    inputsha512sum.close();
    inputmd5sum.close();
    sha1sum = outputsha1sum.events.single.toString();
    sha256sum = outputsha256sum.events.single.toString();
    sha512sum = outputsha512sum.events.single.toString();
    md5sum = outputmd5sum.events.single.toString();
    print("sha1sum: $sha1sum");
    print("sha256sum: $sha256sum");
    print("sha512sum: $sha512sum");
    print("md5sum: $md5sum");
  }

  // internal
  String? localPath;
  int? msgId;
  String uid = randomAlphaNumeric(16);
  bool canBeFetched = false;

  static Future<FileEvt> createFromLocal(String path, String caption) async {
    FileEvt fevt = FileEvt(
      filename: p.basename(path),
      caption: caption,
      filesize: -1,
      localPath: path,
    );
    print("== path: $path");
    // TODO: this workaround may be needed if cache will get cleaned too often.
    //as for now it is not required
    // if (Platform.isAndroid) {
    //   print("== We are on android, let's copy the file to our local storage.");
    //   final docsDir = await getApplicationDocumentsDirectory();
    //   final newPath = p.join(
    //     docsDir.path,
    //     "local_file_share",
    //     "f_${fevt.uid}",
    //   );
    //   TODO: mkdir
    //   print("== cp '$path' '$newPath'");
    //   await File(path).copy(newPath);
    //   fevt.localPath = newPath;
    // }
    print("== calculating size");
    fevt.filesize = await File(fevt.localPath!).length();
    print("== calculating hashes");
    await fevt.calculateChecksums();
    fevt.canBeFetched = true;
    fevt.id = fileevtBox.put(fevt);
    return fevt;
  }
}
