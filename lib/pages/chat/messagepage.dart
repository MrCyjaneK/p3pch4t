import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/transport/server/p3pmd.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({
    Key? key,
    required this.u,
    required this.msgTxt,
  }) : super(key: key);

  final User u;
  final String msgTxt;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("x")),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(8),
            child: p3pMd(
              msgTxt: msgTxt,
            )),
      ),
    );
  }
}
