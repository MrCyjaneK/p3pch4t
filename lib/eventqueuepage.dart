import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/eventpage.dart';
import 'package:p3pch4t/prefs.dart';

class EventQueuePage extends StatefulWidget {
  const EventQueuePage({Key? key}) : super(key: key);

  @override
  State<EventQueuePage> createState() => _EventQueuePageState();
}

class _EventQueuePageState extends State<EventQueuePage> {
  List<Event> events = eventBox.getAll();

  void loadData() {
    setState(() {
      events = eventBox.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Event Queue")),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final e = events[index];
          JsonEncoder encoder = const JsonEncoder.withIndent('  ');
          return Card(
            child: ListTile(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return EventPage(e: e);
                    },
                  ),
                );
                loadData();
              },
              title: Text(
                "#${e.id}. ${e.creationDate}",
              ),
              subtitle: Text(
                """id: ${e.id}
isRelayed: ${e.isRelayed}
jsonBody: ${encoder.convert(e.json)}
creationDate: ${e.creationDate}
lastRelayed: ${e.lastRelayed}
relayTries: ${e.relayTries}
publicKey: [tap to reveal] 
toJson(): [tap to reveal]""",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontFamily: "monospace"),
              ),
            ),
          );
        },
      ),
    );
  }
}
