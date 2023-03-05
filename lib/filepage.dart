import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class FilePage extends StatelessWidget {
  const FilePage({Key? key, required this.u}) : super(key: key);

  final User u;

  @override
  Widget build(BuildContext context) {
    return PrettyQr(
      typeNumber: 3,
      size: 200,
      data: u.connstring,
      errorCorrectLevel: QrErrorCorrectLevel.M,
      roundEdges: true,
    );
  }
}
