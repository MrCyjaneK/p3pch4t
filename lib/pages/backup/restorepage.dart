import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:i2p_flutter/i2p_flutter.dart';
import 'package:openpgp/openpgp.dart';
import 'package:p3pch4t/classes/privkey.dart';
import 'package:p3pch4t/helpers/pgp.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:share_plus/share_plus.dart';
import 'package:p3pch4t/helpers/consts.dart' as c;

class RestorePage extends StatefulWidget {
  const RestorePage({Key? key}) : super(key: key);

  @override
  State<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends State<RestorePage> {
  String log = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restore"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const MarkdownBody(data: r"""# Backup & Restore

Valid backup consists of 2 files

1. (Smaller) your private key to decrypt the backup
2. (Bigger) binary blob with your data

Please pick them here in valid order (private key -> blob) or (smaller -> larger).

NOTE: The app will close after restoring the backup (it will feel like a crash 
but simply reopen the app to continue using your restored session)
"""),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton(
                  onPressed: () async {
                    final pKey =
                        await FilePicker.platform.pickFiles(withData: true);
                    if (pKey == null) return;
                    final blob =
                        await FilePicker.platform.pickFiles(withData: true);
                    if (blob == null) return;
                    prefs.setString(
                        "privkey", utf8.decode(pKey.files.single.bytes!));

                    final decoded = await OpenPGP.decrypt(
                      utf8.decode(blob.files.single.bytes!),
                      prefs.getString("privkey")!,
                      passpharse,
                    );
                    final json = jsonDecode(decoded);
                    // var backupObject = jsonEncode({
                    //  "compat": "backup.v1",
                    //  "i2pd": i2pdAddressContent,
                    //  "objectbox": objectboxDataMdbContent,
                    //  "connstring": prefs.getString("connstring"),
                    //  "username": prefs.getString("username"),
                    //  "bio": prefs.getString("bio"),
                    //});
                    final i2pdAddressDat =
                        "${await i2pFlutterPlugin.getConfigDirectory()}/p3pch4t.dat";
                    final objectboxDataMdb = "${store.directoryPath}/data.mdb";
                    await File(i2pdAddressDat)
                        .writeAsBytes(base64Decode(json["i2pd"]));
                    store.close();
                    await File(objectboxDataMdb)
                        .writeAsBytes(base64Decode(json["objectbox"]));
                    prefs.setString(
                        "connstring", json["connstring"].toString());
                    prefs.setString("username", json["username"].toString());
                    prefs.setString("bio", json["bio"].toString());
                    await i2pFlutterPlugin.writeCertificateBundle();
                    await i2pFlutterPlugin.writeI2pdConf(c.i2pdconf);
                    await i2pFlutterPlugin.writeTunnelsConf(c.tunnelsconf);
                    await Future.delayed(const Duration(seconds: 1));
                    exit(0);
                  },
                  child: const Text("Restore"),
                ),
              ),
              SelectableText(
                log,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontFamily: "monospace"),
              ),
              const SizedBox(height: 180),
            ],
          ),
        ),
      ),
    );
  }

  void _log(String s) {
    setState(() {
      log += "$s\n";
    });
  }

  void _doBackup() async {
    setState(() {
      log = "";
    });

    _log("= Files");
    final i2pdAddressDat =
        "${await i2pFlutterPlugin.getConfigDirectory()}/p3pch4t.dat";
    final i2pdAddressContent =
        base64Encode(await File(i2pdAddressDat).readAsBytes());
    _log("= objectbox");
    store.awaitAsyncCompletion();
    store.awaitAsyncSubmitted();
    final objectboxDataMdb = "${store.directoryPath}/data.mdb";
    final objectboxDataMdbContent =
        base64Encode(await File(objectboxDataMdb).readAsBytes());
    var backupObject = jsonEncode({
      "compat": "backup.v1",
      "i2pd": i2pdAddressContent,
      "objectbox": objectboxDataMdbContent,
    });

    _log("Size: ${filesize(backupObject.length)}");
    _log("= Encrypting");
    final encS =
        await OpenPGP.encrypt(backupObject, (await getSelfPubKey()).publicKey);
    _log("= encS: OK");
    final blobEnc = XFile.fromData(
      utf8.encode(encS) as Uint8List,
      name: "p3p-backup-${DateTime.now().toIso8601String()}.bin",
    );
    _log("= blobEnc: OK");
    final filePrivkey = XFile.fromData(
      utf8.encode(
        prefs.getString("privkey")!,
      ) as Uint8List,
      name: "privkey.asc",
    );
    _log("= privatekey: ok");

    Share.shareXFiles([blobEnc, filePrivkey]);
    _log("OK");
  }
}
