import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class I2pSetupHelp extends StatefulWidget {
  const I2pSetupHelp({Key? key}) : super(key: key);

  @override
  State<I2pSetupHelp> createState() => _I2pSetupHelpState();
}

class _I2pSetupHelpState extends State<I2pSetupHelp> {
  bool isHttpProxyWorking = false;
  final i2pUrlCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("I2P help"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              const SelectableText(
                  "Welcome to quick introduction to i2p! This tutorial will (hopefully) guide you on how to connect to i2p network and how to get your connstring."),
              SelectableText(
                "Installation",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SelectableText(
                  "I2P isn't embedded (yet?) in p3pch4t because i2p is a long-running process that can be used by many programs. So installation steps are left as an excercies for the end user. At least for now - in future it may change but no promises. Some platforms may support experimental automatic installer."),
              if (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
                const SelectableText(
                    "! There are 2 projects that are i2p routers 1) i2p and 2) i2pd, it is recommended to use the official implementation."),
              if (Platform.isLinux)
                const SelectableText(
                    "It looks like you are using Linux! Steps on how to install i2p are available here:\nhttps://geti2p.net/en/download\nThis steps are similar when installing any other software so a linux user should be familiar with them. p.s. do not use repository version - download the installer for latest version."),
              if (Platform.isAndroid)
                const SelectableText(
                    "Download I2P app from Google Play or geti2p.com website."),
              SelectableText(
                "Configuration",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SelectableText(
                  "p3pch4t expects user to perform a one time setup of i2p router.\n1) Enable http proxy on port :4444 (this is on by default)\n2) Create a hidden service that will forward requests to 127.0.0.1 on port 16424.\nAfter performing the tasks you can test the configuration below by putting your <domain>.b32.i2p below."),
              if (Platform.isLinux)
                Column(
                  children: [
                    const SelectableText(
                        "1) Navigate to http://127.0.0.1:7657/i2ptunnelmgr and check if tunnel is already created, it should look like this:"),
                    Image.asset(
                        "assets/images/help/linux-config-i2p-hiddenservice.png"),
                    const SelectableText("2) If no - press tunnel wizard"),
                    const SelectableText(
                        "3) Select \"Server Tunnel\" and click next"),
                    const SelectableText(
                        "4) Select \"tunnel type\" HTTP and click next"),
                    const SelectableText(
                        "5) Name your tunnel whatever you want, we recommend the name 'p3pch4t' and click next"),
                    const SelectableText(
                        "6) Type 127.0.0.1 into host and 16424 into port and click next"),
                    const SelectableText(
                        "7) Select 'Automatically start tunnel when router starts' and press finish"),
                    const SelectableText(
                        "After doing all the steps go to http://127.0.0.1:7657/i2ptunnelmgr again and copy 'Destination' from p3pch4t hidden service."),
                  ],
                ),
              const SizedBox(height: 16),
              if (Platform.isAndroid)
                Column(
                  children: [
                    const SelectableText(
                        "1) Navigate to 'Tunnels' and 'Server tunnels' page in i2p app and make sure that it looks like this (if p3pch4t field is missing you need to create it.). So if you already have it you can skip to last step."),
                    Image.asset("assets/images/help/android_01.png"),
                    const SelectableText(
                        "2) To create the tunnel press the (orange) plus button."),
                    Image.asset("assets/images/help/android_02.png"),
                    const SelectableText("3) Select HTTP server"),
                    Image.asset("assets/images/help/android_03.png"),
                    const SelectableText(
                        "3) Name your tunnel whatever you want - I named it 'p3pch4t' - and I recommend to name it exactly the same way."),
                    Image.asset("assets/images/help/android_04.png"),
                    const SelectableText(
                        "4) You can skip the description field and leave it empty"),
                    Image.asset("assets/images/help/android_05.png"),
                    const SelectableText(
                        "5) Target host sohuld be '127.0.0.1'"),
                    Image.asset("assets/images/help/android_06.png"),
                    const SelectableText("6) Target port should be '16424'"),
                    Image.asset("assets/images/help/android_07.png"),
                    const SelectableText(
                        "7) Make sure to enable auto start to be able to receive notifications about new messages."),
                    Image.asset("assets/images/help/android_08.png"),
                    const SelectableText(
                        "8) Click submit if the Review looks similar on your device (pay attention to 'target host', 'target port', 'tunnel type', 'client or server' and 'auto start')"),
                    Image.asset("assets/images/help/android_09.png"),
                    const SelectableText("9) Press create tunnel"),
                    Image.asset("assets/images/help/android_10.png"),
                    const SelectableText(
                        "10) Press the copy icon next to the long string: dib...b32.i2p to copy your destination. You can paste it below to make sure that it works!"),
                    Image.asset("assets/images/help/android_11.png"),
                  ],
                ),
              const SizedBox(height: 16),
              TextField(
                controller: i2pUrlCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Local i2p domain"),
                ),
              ),
              const SizedBox(height: 16),
              _connectionTestButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox _connectionTestButton() {
    return SizedBox(
      width: double.maxFinite,
      child: ElevatedButton.icon(
        onPressed: () async {
          setState(() {
            isHttpProxyWorking = false;
          });
          var resp = await http.read(Uri.parse("http://${i2pUrlCtrl.text}"));
          print(resp);
          setState(() {
            isHttpProxyWorking = resp == "p3p";
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isHttpProxyWorking ? Colors.green : Colors.red,
        ),
        icon: Icon(isHttpProxyWorking ? Icons.thumb_up : Icons.thumb_down),
        label: Text(isHttpProxyWorking
            ? "Connected successfully!"
            : "No connection (press to check)"),
      ),
    );
  }
}
