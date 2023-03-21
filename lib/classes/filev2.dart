import 'dart:convert';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:random_string/random_string.dart';

@Entity()
class FileV2 {
  FileV2({
    required this.ownerId,
    required this.name,
    required this.parentFile,
  });

  @Id()
  int id = 0;

  @Index()
  int ownerId;

  String name;

  @Property(type: PropertyType.date)
  DateTime creationDate = DateTime.now();
  @Property(type: PropertyType.date)
  DateTime editDate = DateTime.now();
  @Property(type: PropertyType.date)
  DateTime remoteEditDate = DateTime.now();

  @Index()
  String fileUid = randomAlphaNumeric(16);
  @Index()
  String parentFile;

  @Property(type: PropertyType.byteVector)
  Uint8List? contentBytes;

  int knownSize = 0;
  String? fetchUrl;

  @Transient()
  bool get isFile {
    return contentBytes != null;
  }

  @Transient()
  bool get isDirectory {
    return contentBytes == null;
  }

  String getMimeType() {
    return lookupMimeType(name, headerBytes: contentBytes).toString();
  }

  int save() {
    id = fileV2Box.put(this);
    return id;
  }

  @Transient()
  bool get isDownloaded {
    return remoteEditDate.isBefore(editDate);
  }

  Map<String, dynamic> toJson() {
    return {
      "contentHeader": contentBytes == null
          ? List.filled(512, 0)
          : base64Encode(contentBytes!.take(512).toList()),
      "parentFile": parentFile,
      "fileUid": fileUid,
      // "fileUrl": fetchUrl,
    };
  }
}
