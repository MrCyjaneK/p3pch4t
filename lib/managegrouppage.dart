import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:openpgp/openpgp.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/classes/ssmdc.v1/groupconfig.dart';
import 'package:p3pch4t/helpers/themes.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:p3pch4t/profilepage.dart';
import 'package:p3pch4t/widgets/qr.dart';
import 'package:select_dialog/select_dialog.dart';

class ManageGroupPage extends StatefulWidget {
  const ManageGroupPage({Key? key, required this.group}) : super(key: key);

  final SSMDCv1GroupConfig group;

  @override
  State<ManageGroupPage> createState() => _ManageGroupPageState();
}

class _ManageGroupPageState extends State<ManageGroupPage> {
  late final SSMDCv1GroupConfig group = widget.group;
  late final groupNameCtrl = TextEditingController(text: group.name);

  late final groupIdCtrl = TextEditingController(text: group.uid);

  late final aboutCtrl = TextEditingController(text: group.about);

  late final welcomeMessageCtrl =
      TextEditingController(text: group.welcomeMessage);
  late final joinMessageCtrl = TextEditingController(text: group.joinMessage);

  late final byeMessageCtrl = TextEditingController(text: group.byeMessage);
  late final leaveMessageCtrl = TextEditingController(text: group.leaveMessage);

  late bool showWelcomeMessage = group.showWelcomeMessage;
  late bool showJoinMessage = group.showJoinMessage;
  late bool showByeMessage = group.showByeMessage;
  late bool showLeaveMessage = group.showLeaveMessage;

  late Color? backgroundColor = group.backgroundColor;

  String publicKey = "loading...";
  @override
  void initState() {
    OpenPGP.convertPrivateKeyToPublicKey(widget.group.groupPrivatePgp)
        .then((value) {
      setState(() {
        publicKey = value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (backgroundColor == null) {
      setState(() {
        backgroundColor = Theme.of(context).cardColor;
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(
                controller: groupNameCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Group name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                enabled: false,
                controller: groupIdCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Group UID',
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: SelectableText(
                    widget.group.getGroupConnstring(),
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontSize: 24),
                  ),
                ),
              ),
              GenericQrWidget(text: widget.group.getGroupConnstring()),
              const Divider(),
              const Text("Users"),
              ListView.builder(
                itemCount: widget.group.userList.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: double.maxFinite,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(
                              u: widget.group.userList[index],
                              group: widget.group,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person),
                      label: Text(widget.group.userList[index].name),
                    ),
                  );
                },
              ),
              ListView.builder(
                itemCount: widget.group.banList.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final banU = userBox.get(widget.group.banList[index]);
                  if (banU == null) return const Text("banU == null");
                  return SizedBox(
                    width: double.maxFinite,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(
                              u: banU,
                              group: widget.group,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person),
                      label: Text(banU.name),
                    ),
                  );
                },
              ),
              const Divider(),
              TextField(
                controller: welcomeMessageCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Welcome message template',
                ),
              ),
              CheckboxListTile(
                value: showWelcomeMessage,
                onChanged: (bool? value) {
                  setState(() {
                    showWelcomeMessage = value == true;
                  });
                },
                title: const Text("Show welcome message"),
              ),
              TextField(
                controller: joinMessageCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Join message template',
                ),
              ),
              CheckboxListTile(
                value: showJoinMessage,
                onChanged: (bool? value) {
                  setState(() {
                    showJoinMessage = value == true;
                  });
                },
                title: const Text("Show join message"),
              ),
              TextField(
                controller: byeMessageCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Bye message template',
                ),
              ),
              CheckboxListTile(
                value: showByeMessage,
                onChanged: (bool? value) {
                  setState(() {
                    showByeMessage = value == true;
                  });
                },
                title: const Text("Show bye message"),
              ),
              TextField(
                controller: leaveMessageCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Leave message template',
                ),
              ),
              CheckboxListTile(
                value: showLeaveMessage,
                onChanged: (bool? value) {
                  setState(() {
                    showLeaveMessage = value == true;
                  });
                },
                title: const Text("Show leave message"),
              ),
              TextField(
                controller: aboutCtrl,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Group about',
                ),
              ),
              _backgroundColorChange(),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return changeThemeAlert(
                          group: group,
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.backpack),
                  label: Text(widget.group.chatBackgroundAsset == null
                      ? "Set theme"
                      : "Change theme"),
                ),
              ),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    group.name = groupNameCtrl.text;
                    group.about = aboutCtrl.text;
                    group.welcomeMessage = welcomeMessageCtrl.text;
                    group.joinMessage = joinMessageCtrl.text;
                    group.byeMessage = byeMessageCtrl.text;
                    group.leaveMessage = leaveMessageCtrl.text;
                    group.showWelcomeMessage = showWelcomeMessage;
                    group.showJoinMessage = showJoinMessage;
                    group.showByeMessage = showByeMessage;
                    group.showLeaveMessage = showLeaveMessage;
                    group.backgroundColor = backgroundColor;
                    ssmdcv1GroupConfigBox.put(group);
                    for (var intU in group.userList) {
                      final evt = await Event.newSsmdcv1Introduction(
                        intU,
                        group,
                      );
                      evt.id = intU.queueSendEvent(evt);
                      intU.sendEvent(evt);
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Save and & reintroduce"),
                ),
              ),
              const Divider(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  publicKey,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontFamily: "monospace"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListTile _backgroundColorChange() {
    return ListTile(
      title: const Text('Change background color'),
      subtitle: Text(
        '${ColorTools.materialName(backgroundColor!)} '
        'aka ${ColorTools.nameThatColor(backgroundColor!)}',
      ),
      trailing: ColorIndicator(
        width: 44,
        height: 44,
        borderRadius: 4,
        color: backgroundColor!,
        onSelectFocus: false,
        onSelect: () async {
          showColorPickerDialog(context, backgroundColor!).then((value) {
            setState(() {
              backgroundColor = value;
            });
          });
        },
      ),
    );
  }
}

class changeThemeAlert extends StatefulWidget {
  const changeThemeAlert({
    super.key,
    required this.group,
  });

  final SSMDCv1GroupConfig group;
  @override
  State<changeThemeAlert> createState() => _changeThemeAlertState();
}

class _changeThemeAlertState extends State<changeThemeAlert> {
  late String? selection = widget.group.chatBackgroundAsset;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Change title"),
      content: SizedBox(
        width: double.maxFinite,
        height: 355,
        child: Column(
          children: [
            SizedBox(
              width: double.maxFinite,
              height: 256,
              child: Image.asset(
                getChatBackgroundAsset(selection),
                scale: 2,
                repeat: ImageRepeat.repeat,
              ),
            ),
            SizedBox(
              width: double.maxFinite,
              child: OutlinedButton.icon(
                onPressed: () {
                  SelectDialog.showModal<String>(
                    context,
                    label: "Change theme",
                    selectedValue: selection,
                    items: chatBackgrounds,
                    onChange: (String selected) {
                      setState(() {
                        selection = selected;
                      });
                    },
                  );
                },
                icon: const Icon(Icons.change_circle),
                label: const Text("Change theme"),
              ),
            ),
            SizedBox(
              width: double.maxFinite,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    widget.group.chatBackgroundAsset = selection;
                  });
                  ssmdcv1GroupConfigBox.put(widget.group);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.save),
                label: const Text("Save theme"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
