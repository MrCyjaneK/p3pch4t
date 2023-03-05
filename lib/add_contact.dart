import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class AddContact extends StatefulWidget {
  const AddContact({Key? key}) : super(key: key);

  @override
  State<AddContact> createState() => _AddContactState();
}

class _AddContactState extends State<AddContact> {
  final idCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  bool isScanning = false;
  Uri? addData;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add c0n7act"),
      ),
      body: isScanning
          ? SizedBox(
              width: double.maxFinite,
              child: MobileScanner(
                fit: BoxFit.contain,
                onDetect: (barcodes) {
                  setState(() {
                    idCtrl.text = barcodes.barcodes.first.rawValue.toString();
                    isScanning = !isScanning;
                  });
                },
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: idCtrl,
                      onChanged: (_) {
                        setState(() {
                          addData = Uri.tryParse(idCtrl.text);
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Contact URL',
                      ),
                    ),
                    if (kDebugMode && addData != null) ..._debugInfo(addData),
                    const Text(
                        "If you want others to add you you can give them your connstring, or scan the code below."),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: SelectableText(
                          prefs.getString("connstring").toString(),
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(fontSize: 24),
                        ),
                      ),
                    ),
                    PrettyQr(
                      size: 256,
                      data: "${prefs.getString('connstring')}",
                      errorCorrectLevel: QrErrorCorrectLevel.Q,
                      roundEdges: true,
                    ),
                    if (Platform.isAndroid && !isScanning)
                      SizedBox(
                        width: double.maxFinite,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              isScanning = !isScanning;
                            });
                          },
                          icon: const Icon(Icons.qr_code),
                          label: const Text("Scan QR"),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton:
          (addData != null && addData?.host != "" && addData?.scheme == "i2p")
              ? FloatingActionButton.extended(
                  onPressed: () {
                    var u = userBox
                        .query(
                          User_.connmethod.equals(addData!.scheme).and(
                                User_.connstring
                                    .equals('${addData!.host}${addData!.path}'),
                              ),
                        )
                        .build()
                        .findFirst();
                    if (u != null) {
                      return;
                    }
                    var c = User(
                        connstring: '${addData!.host}${addData!.path}',
                        connmethod: addData!.scheme);

                    userBox.put(c);
                    Navigator.of(context).pop();
                  },
                  label: const Text("Add contact"),
                  icon: const Icon(Icons.add),
                )
              : null,
    );
  }

  List<Text> _debugInfo(Uri? addData) {
    return [
      Text("""scheme: ${addData!.scheme}
host: ${addData.host}${addData.path}"""),
    ];
  }
}
