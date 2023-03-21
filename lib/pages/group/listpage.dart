import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/ssmdc.v1/groupconfig.dart';
import 'package:p3pch4t/pages/group/managegrouppage.dart';
import 'package:p3pch4t/helpers/prefs.dart';

class GroupListPage extends StatelessWidget {
  GroupListPage({Key? key}) : super(key: key);
  final List<SSMDCv1GroupConfig> groups = ssmdcv1GroupConfigBox.getAll();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group list"),
      ),
      body: ListView.builder(
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
      ),
    );
  }
}
