import 'package:flutter/material.dart';
import 'package:p3pch4t/prefs.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    prefs.reload();
    return Scaffold(
      appBar: AppBar(title: const Text("Error")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              SelectableText(
                prefs.getString("lastLog").toString(),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontFamily: "monospace"),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.delete),
        onPressed: () {
          prefs.setString("lastLog", "null");
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
