import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/ssmdc.v1/groupconfig.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:p3pch4t/widgets/userqr.dart';

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
  late Color? backgroundColor = widget.u.backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (backgroundColor == null) {
      setState(() {
        backgroundColor = Theme.of(context).cardColor;
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.u.name),
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
                    widget.u.connstring,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontSize: 24),
                  ),
                ),
              ),
              UserQrWidget(u: widget.u),
              const Divider(),
              SizedBox(
                width: double.maxFinite,
                child: MarkdownBody(
                  selectable: true,
                  data: widget.u.bio,
                  extensionSet: md.ExtensionSet(
                    md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                    [
                      md.EmojiSyntax(),
                      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes
                    ],
                  ),
                ),
              ),
              const Divider(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  widget.u.publicKey.toString(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontFamily: "monospace"),
                ),
              ),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    final msgs = messageBox
                        .query(Message_.userId.equals(widget.u.id))
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
                    userBox.remove(widget.u.id);
                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Delete chat"),
                ),
              ),
              ListTile(
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
                    showColorPickerDialog(context, backgroundColor!)
                        .then((value) {
                      setState(() {
                        backgroundColor = value;
                      });
                    });
                  },
                ),
              ),
              if (widget.group != null)
                _groupUserManage(group: widget.group!, u: widget.u),
              const SizedBox(height: 160),
            ],
          ),
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
          child: group.isUserBanned(widget.u)
              ? OutlinedButton.icon(
                  onPressed: () {
                    group.unbanUser(widget.u);
                    refresh();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Unban"),
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    group.banUser(widget.u);
                    refresh();
                  },
                  icon: const Icon(Icons.block),
                  label: const Text("ban"),
                ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.maxFinite,
          child: group.isUserAdmin(widget.u)
              ? OutlinedButton.icon(
                  onPressed: () {
                    group.unadminUser(widget.u);
                    refresh();
                  },
                  icon: const Icon(Icons.block),
                  label: const Text("Unadmin"),
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    group.adminUser(widget.u);
                    refresh();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Admin"),
                ),
        ),
      ],
    );
  }
}
