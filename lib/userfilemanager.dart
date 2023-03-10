import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class UserFileManager extends StatelessWidget {
  const UserFileManager({Key? key, required this.u}) : super(key: key);

  final User u;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Files"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: const [],
          ),
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        distance: 65,
        expandedFabSize: ExpandableFabSize.regular,
        type: ExpandableFabType.up,
        children: [
          FloatingActionButton(
            child: const Icon(Icons.create_new_folder),
            onPressed: () {},
          ),
          FloatingActionButton(
            child: const Icon(Icons.file_open),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Create new file"),
                    content: Column(
                      children: const [Text('a')],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
