import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Message {
  Message({
    required this.eventUid,
    required this.userId,
    required this.type,
    required this.isTrusted,
    required this.isSelf,
    required this.nonce,
    required this.data,
    this.originName,
    this.originConnstring,
    this.originConnmethod,
  });
  @Id()
  int id = 0;

  @Index()
  String? eventUid;

  @Index()
  int userId;

  @Property(type: PropertyType.date)
  DateTime time = DateTime.now();

  String type;

  // for ssmdc.v1
  String? originName;
  String? originConnstring;
  String? originConnmethod;
  // end

  bool isTrusted;
  bool isSelf;

  @Index()
  String nonce;

  @Property(type: PropertyType.byteVector)
  Uint8List data;

  Map<String, dynamic> dataJson() {
    return jsonDecode(utf8.decode(data));
  }

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "isTrusted": isTrusted,
      "data": data,
    };
  }
}
