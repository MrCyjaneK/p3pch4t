import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class UserQrWidget extends StatelessWidget {
  const UserQrWidget({Key? key, required this.u}) : super(key: key);

  final User u;

  @override
  Widget build(BuildContext context) {
    return PrettyQr(
      size: 256,
      data: "${u.connmethod}://${u.connstring}",
      errorCorrectLevel: QrErrorCorrectLevel.Q,
      roundEdges: true,
    );
  }
}
