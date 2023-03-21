import 'dart:math';

import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/ssmdc.v1/groupconfig.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:random_string/random_string.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final groupNameCtrl = TextEditingController();
  final groupEmailCtrl = TextEditingController(
      text:
          "${randomAlpha(8)}@${randomAlpha(8)}.${randomAlpha(2 + Random().nextInt(1))}");
  final groupIdCtrl = TextEditingController(text: randomAlphaNumeric(16));

  bool isCreating = false;

  String log =
      'NOTE: all future members of your group will get added to the contact list of your device - and will have you in their\'s contact list.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create SSMDC.v1"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              children: [
                TextField(
                  controller: groupNameCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Group Name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: groupEmailCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Group Email (used for pgp, can be anything)',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: groupIdCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Unique group ID',
                  ),
                ),
                const SizedBox(height: 16),
                if (!isCreating)
                  SizedBox(
                    width: double.maxFinite,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        setState(() {
                          log = "";
                          isCreating = true;
                        });
                        await createGroup();
                        setState(() {
                          isCreating = false;
                        });
                      },
                      icon: const Icon(Icons.create),
                      label: const Text("Create the group"),
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
      ),
    );
  }

  void _log(String s) {
    setState(() {
      log += "$s\n";
    });
  }

  Future<void> createGroup() async {
    _log("Creating group entry");
    var ssmdcg = SSMDCv1GroupConfig(
      name: groupNameCtrl.text,
      uid: groupIdCtrl.text,
    );
    _log(
        "Generating group's pgp key NOTE: This is a resource intensive task (this may take up to 5 minutes on slower devices). Please keep the app in foreground and do not close it.");
    await ssmdcg.generateGroupPgp(groupEmailCtrl.text, groupNameCtrl.text);
    _log("OK!");
    _log("Saving changes into the box");
    ssmdcv1GroupConfigBox.put(ssmdcg);
    _log("You can now close the window.");
  }
}
