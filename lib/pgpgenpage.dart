import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:i2p_flutter/i2p_flutter.dart';
import 'package:p3pch4t/helpers/pgp.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:p3pch4t/helpers/consts.dart' as c;

class GenPGPPage extends StatefulWidget {
  const GenPGPPage({Key? key}) : super(key: key);

  @override
  State<GenPGPPage> createState() => _GenPGPPageState();
}

class _GenPGPPageState extends State<GenPGPPage> {
  final nameCtrl = TextEditingController(
      text: "anon#${Random().nextInt(pow(2, 32).toInt())}");
  final emailCtrl = TextEditingController(text: "no-reply@example.com");
  final bioCtrl = TextEditingController(text: "// to be done later //");
  final i2pdestCtrl = TextEditingController(text: "");
  var logTxt = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate PGP"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                  "You are not required to give a valid email (in terms of what your actual email actually is, just provide something that looks like an email.)"),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Bio',
                ),
              ),
              const SizedBox(height: 16),
              // TextField(
              //   controller: i2pdestCtrl,
              //   decoration: const InputDecoration(
              //     border: OutlineInputBorder(),
              //     labelText: 'I2P destination',
              //   ),
              // ),
              // const SizedBox(height: 16),
              // SizedBox(
              //   width: double.maxFinite,
              //   child: OutlinedButton.icon(
              //     onPressed: () {
              //       Navigator.of(context).push(
              //         MaterialPageRoute(
              //           builder: (context) {
              //             return const I2pSetupHelp();
              //           },
              //         ),
              //       );
              //     },
              //     icon: const Icon(Icons.help),
              //     label: const Text("Configure manually (for experts)"),
              //   ),
              // ),
              SizedBox(
                width: double.maxFinite,
                child: Text(logTxt),
              ),
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          setState(() {
            logTxt = "";
          });

          _log(
              "[i2pd(embedded)]: i2pd config dir: ${await i2pFlutterPlugin.getConfigDirectory()}");
          _log("[i2pd(embedded)]: writing embedded certificates");
          await i2pFlutterPlugin.writeCertificateBundle();
          _log("[i2pd(embedded)]: writing i2pdconf ");
          await i2pFlutterPlugin.writeI2pdConf(c.i2pdconf);
          _log("[i2pd(embedded)]: writing tunnelsconf");
          await i2pFlutterPlugin.writeTunnelsConf(c.tunnelsconf);
          _log("[i2pd(embedded)]: running i2pd");
          _log("[i2pd(embedded)]: ${await i2pFlutterPlugin.getBinaryPath()}");

          _log(
              "[i2pd(embedded)]: NOTE: i2pd needs at least 2 minutes to connect to local destination and around 15 minutes for a reasonable peer discovery (so consider 15 minutes after first run a moment when others can message you and when you can message others.)");
          if (!await i2pFlutterPlugin.isRunning()) {
            _log("[i2pd(embedded)]: i2p is not started - starting.");
            i2pFlutterPlugin.runI2pd();
          } else {
            _log("[i2pd(embedded)]: i2p is already running, not starting it");
          }
          _log(
              "[i2pd(embedded)]: Waiting 15 seconds to make sure that the daemon starts (check logcat for i2pd logs.)");
          await Future.delayed(const Duration(seconds: 15));
          final tunnels = await i2pFlutterPlugin.getTunnelsList();
          _log("[i2pd(embedded)]: tunnels list:");
          tunnels.forEach((key, value) {
            _log("$key: $value");
          });
          final i2purl = tunnels["p3pch4t"].toString().split(":")[0];
          // final i2purl = i2pdestCtrl.text;
          // var resp = await http.read(Uri.parse("http://$i2purl/"));
          // if (resp != "p3p") {
          //   _log(
          //       "[i2p] Invalid response: $resp\nIs something else running on :16424?");
          //   return;
          // } else {
          //   _log("[i2p] OK.");
          // }
          if (i2purl == 'null') {
            _log("""Failed to start [i2pd(embedded)]: 
====== README ======
It may happen when i2pd is running on a very slow connection.
Or a very slow device, please kindly wait couple more seconds
and try to configure the engine one more time, if the problem
persists wait up to 5 minutes, try again and if the process
still fails report an issue.
""");
            return;
          }
          _log(
              "[pgp] generating (NOTE: this is a resourece intense task, and may take up to 5 minutes to complete.)");
          await GenPGP(nameCtrl.text, emailCtrl.text);
          _log("[prefs] configuring");
          prefs.setString("connstring", "i2p://$i2purl");
          prefs.setString("username", nameCtrl.text);
          prefs.setString("bio", bioCtrl.text);
          _log("[app] closing app after one second...");
          await Future.delayed(const Duration(seconds: 1));
          exit(0);
        },
        label: const Text("Configure engine"),
        icon: const Icon(
          Icons.generating_tokens,
        ),
      ),
    );
  }

  void _log(String text) {
    print(text);
    setState(() {
      logTxt += "\n$text";
    });
  }
}
