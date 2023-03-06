import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:i2p_flutter/i2p_manager_page.dart';
import 'package:i2p_flutter/widgets/serviceslist.dart';
import 'package:i2p_flutter/widgets/statuswidget.dart';
import 'package:p3pch4t/backuppage.dart';
import 'package:p3pch4t/classes/ssmdc.v1/groupconfig.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/creategrouppage.dart';
import 'package:p3pch4t/managegrouppage.dart';
import 'package:p3pch4t/prefs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final usernameCtrl = TextEditingController(text: prefs.getString("username"));

  final bioCtrl = TextEditingController(
    text: prefs.getString("bio"),
  );

  final List<SSMDCv1GroupConfig> groups = ssmdcv1GroupConfigBox.getAll();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sett1ng5"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              const Text("kDebugMode: $kDebugMode"),
              const SizedBox(height: 16),
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Username"),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(prefs.getString("connstring").toString()),
              const SizedBox(height: 16),
              TextField(
                controller: bioCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Bio"),
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontFamily: "monospace"),
                maxLines: 8,
              ),
              const SizedBox(height: 16),
              const I2pStatus(),
              const I2PServicesList(),
              const SizedBox(height: 16),
              ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  return OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return ManageGroupPage(group: groups[index]);
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.manage_accounts),
                    label: Text('${groups[index].name}(${groups[index].uid})'),
                  );
                },
                shrinkWrap: true,
              ),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const I2PManagerPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.tornado),
                  label: const Text("Open advanced I2P config"),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return const CreateGroupPage();
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.create),
                  label: const Text("Create group server (SSMDC.v1)"),
                ),
              ),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return const BackupPage();
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.backup),
                  label: const Text("Backup"),
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          List<User> ul = userBox.getAll();
          for (var u in ul) {
            u.isIntroduced = false;
          }
          userBox.putMany(ul);
          prefs.setString("bio", bioCtrl.text);
          prefs.setString("username", usernameCtrl.text);
          prefs.reload();
        },
        label: const Text("Save"),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
