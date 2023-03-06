import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/prefs.dart';

class EventPage extends StatefulWidget {
  EventPage({Key? key, required this.e}) : super(key: key);

  Event e;

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  Map<String, dynamic> eJsonBody = {"in_progress": "..."};

  @override
  void initState() {
    widget.e.toJson().then((value) {
      if (!mounted) return;
      setState(() {
        eJsonBody = value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    return Scaffold(
      appBar: AppBar(
        title: Text("Event: ${widget.e.id}"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              SelectableText(
                """
id: ${widget.e.id}
isRelayed: ${widget.e.isRelayed}
jsonBody: ${encoder.convert(widget.e.json)}
creationDate: ${widget.e.creationDate}
lastRelayed: ${widget.e.lastRelayed}
relayTries: ${widget.e.relayTries}
destinations: ${encoder.convert(widget.e.destinations).replaceAll(r"\n", "\n")}
toJson(): ${encoder.convert(eJsonBody).replaceAll(r"\n", "\n")}
""",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontFamily: "monospace"),
              ),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.e.trySend([]);
                  },
                  icon: const Icon(Icons.send),
                  label: const Text("Send event"),
                ),
              ),
              SizedBox(
                width: double.maxFinite,
                child: OutlinedButton.icon(
                  onPressed: () {
                    eventBox.remove(widget.e.id);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete event"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
