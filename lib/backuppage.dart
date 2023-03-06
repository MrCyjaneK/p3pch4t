import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:i2p_flutter/i2p_flutter.dart';
import 'package:openpgp/openpgp.dart';
import 'package:p3pch4t/classes/privkey.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:share_plus/share_plus.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({Key? key}) : super(key: key);

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  String log = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Backup"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const MarkdownBody(data: r"""# Backup & Restore

Your backup will consist of two parts

1. Your private PGP key.
2. Encrypted backup blob.

You need to keep both of the files available (if you have choosen to encrypt
your PGP key then it will get backed up in encrypted form so you also need to
know the passpharse).

Encrypted backup blob will contain the following:
 - Entire objectbox store (messages, users, groups, pending events etc...)
 - I2Pd .dat file (so your `i2p://<address>.b32.i2p` won't change).

Please note that running one address on multiple devices is entirely **NOT**
supported, if you try to restore backup while this session is still active
your clients may not get any messages or they may be delivered randomly,
other network participanta may be unable to message you because of lacking
events. Just don't do it until official multi-device support will be available.

Once you click the backup button you will be asked to share .bin file, this is
your entire encrypted database, in addition to that you also need private key -
which is not inside of that .bin file - it is displayed below and should be 
backed up with extreme safety in mind - it makes sure that nobody is able to
read messages sent to you - and proves your account authenticity.

NOTE: Depending on your platform filenames may get lost in the process (sorry)
When requested to restore backup keep in mind that:

 - Blob file is the bigger one
 - Privkey file is the smaller one
"""),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton(
                  onPressed: _doBackup,
                  child: const Text("Start backup"),
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
      "connstring": prefs.getString("connstring"),
      "username": prefs.getString("username"),
      "bio": prefs.getString("bio"),
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
