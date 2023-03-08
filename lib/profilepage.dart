import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/ssmdc.v1/groupconfig.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/helpers/themes.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:p3pch4t/server/p3pmd.dart';
import 'package:p3pch4t/usercalendarpage.dart';
import 'package:p3pch4t/widgets/qr.dart';
import 'package:select_dialog/select_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    Key? key,
    required this.u,
    this.group,
  }) : super(key: key);

  final User u;
  final SSMDCv1GroupConfig? group;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User u = widget.u;
  late Color? backgroundColor = u.backgroundColor;

  late final notifyTagsCtrl = TextEditingController(text: u.notifyCustomTags);

  @override
  Widget build(BuildContext context) {
    if (backgroundColor == null) {
      setState(() {
        backgroundColor = Theme.of(context).cardColor;
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(u.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: SelectableText(
                    "${u.connmethod}://${u.connstring}",
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontSize: 24),
                  ),
                ),
              ),
              UserQrWidget(u: u),
              const Divider(),
              SizedBox(
                width: double.maxFinite,
                child: p3pMd(
                  msgTxt: u.bio,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(),
              ),
              Text(
                "Notifications",
                style: Theme.of(context)
                    .textTheme
                    .displayLarge!
                    .copyWith(fontSize: 32),
              ),
              CheckboxListTile(
                value: u.notifyOnAll,
                onChanged: (bool? val) {
                  setState(() {
                    u.notifyOnAll = val == true;
                  });
                  userBox.put(u);
                },
                title: const Text("Notify on all messages"),
              ),
              CheckboxListTile(
                value: u.notifyOnTag,
                onChanged: (bool? val) {
                  setState(() {
                    u.notifyOnTag = val == true;
                  });
                  userBox.put(u);
                },
                title: Text("Notify on tag (${prefs.getString("username")})"),
              ),
              CheckboxListTile(
                value: u.notifyOnCalendarEventsAdded,
                onChanged: (bool? val) {
                  setState(() {
                    u.notifyOnCalendarEventsAdded = val == true;
                  });
                  userBox.put(u);
                },
                title: const Text("Notify on @everybody"),
              ),
              CheckboxListTile(
                value: u.notifyOnEveryone,
                onChanged: (bool? val) {
                  setState(() {
                    u.notifyOnEveryone = val == true;
                  });
                  userBox.put(u);
                },
                title: const Text("Notify on new calendar events"),
                subtitle: const Text("This doesn't affect reminders"),
              ),
              TextField(
                controller: notifyTagsCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Notify on match (comma separated)',
                ),
                onChanged: (value) {
                  setState(() {
                    u.notifyCustomTags = value;
                  });
                  userBox.put(u);
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(),
              ),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    final msgs = messageBox
                        .query(Message_.userId.equals(u.id))
                        .build()
                        .find();
                    for (var msg in msgs) {
                      messageBox.remove(msg.id);
                    }
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Purge history"),
                ),
              ),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    final msgs = messageBox
                        .query(Message_.userId.equals(u.id))
                        .build()
                        .find();
                    for (var msg in msgs) {
                      messageBox.remove(msg.id);
                    }
                    userBox.remove(u.id);
                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Delete chat"),
                ),
              ),
              _changeBackgroundColor(),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return changeThemeAlert(
                          u: u,
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.backpack),
                  label: Text(u.chatBackgroundAsset == null
                      ? "Set theme"
                      : "Change theme"),
                ),
              ),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton.icon(
                  style:
                      OutlinedButton.styleFrom(foregroundColor: Colors.green),
                  onPressed: () {
                    // userBox.remove(u.id);
                    setState(() {
                      u.rawBackgroundColor = backgroundColor?.value;
                    });
                    userBox.put(u);
                    Navigator.of(context).pop();
                    u.introduce();
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Save theme"),
                ),
              ),
              if (widget.group != null)
                _groupUserManage(group: widget.group!, u: u),
              const Divider(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  u.publicKey.toString(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontFamily: "monospace"),
                ),
              ),
              const SizedBox(height: 160),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return UserCalendarPage(u: u);
              },
            ),
          );
        },
        icon: const Icon(Icons.calendar_today),
        label: const Text("Calendar"),
      ),
    );
  }

  ListTile _changeBackgroundColor() {
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
    required this.u,
  });

  final User u;
  @override
  State<changeThemeAlert> createState() => _changeThemeAlertState();
}

class _changeThemeAlertState extends State<changeThemeAlert> {
  late String? selection = u.chatBackgroundAsset;
  late User u = widget.u;
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
                    u.chatBackgroundAsset = selection;
                  });
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

class _groupUserManage extends StatefulWidget {
  const _groupUserManage({Key? key, required this.group, required this.u})
      : super(key: key);
  final SSMDCv1GroupConfig group;
  final User u;

  @override
  State<_groupUserManage> createState() => _groupUserManageState();
}

class _groupUserManageState extends State<_groupUserManage> {
  late SSMDCv1GroupConfig group = widget.group;

  late User u = widget.u;

  void refresh() {
    setState(() {
      group = ssmdcv1GroupConfigBox.get(group.id)!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        Text("${group.name}'s config"),
        SizedBox(
          width: double.maxFinite,
          child: group.isUserBanned(u)
              ? OutlinedButton.icon(
                  onPressed: () {
                    group.unbanUser(u);
                    refresh();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Unban"),
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    group.banUser(u);
                    refresh();
                  },
                  icon: const Icon(Icons.block),
                  label: const Text("ban"),
                ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.maxFinite,
          child: group.isUserAdmin(u)
              ? OutlinedButton.icon(
                  onPressed: () {
                    group.unadminUser(u);
                    refresh();
                  },
                  icon: const Icon(Icons.block),
                  label: const Text("Unadmin"),
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    group.adminUser(u);
                    refresh();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Admin"),
                ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.maxFinite,
          child: group.isUserCalendarMod(u)
              ? OutlinedButton.icon(
                  onPressed: () {
                    group.unCalendarModUser(u);
                    refresh();
                  },
                  icon: const Icon(Icons.block),
                  label: const Text("Revoke Calendar permission"),
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    group.calendarModUser(u);
                    refresh();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Give calendar permission"),
                ),
        ),
      ],
    );
  }
}
