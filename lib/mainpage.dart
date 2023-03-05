import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/add_contact.dart';
import 'package:p3pch4t/chatscreen.dart';
import 'package:p3pch4t/classes/message.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/eventqueuepage.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/pgpgenpage.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:p3pch4t/settings.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'p3pch4t',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      darkTheme: ThemeData.dark(),
      home: (prefs.getString("privkey") != null)
          ? const MyHomePage()
          : const GenPGPPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<User> uList = [];

  @override
  void initState() {
    loadUserList();
    Timer.periodic(const Duration(seconds: 3), (timer) {
      loadUserList();
    });
    super.initState();
  }

  Future<void> loadUserList() async {
    setState(() {
      uList = userBox
          .query()
          .order(User_.lastSeen, flags: Order.descending)
          .build()
          .find();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("C0n7acts"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const SettingsPage();
                  },
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                itemCount: uList.length,
                itemBuilder: (context, index) {
                  Message? msg = messageBox
                      .query(Message_.userId.equals(uList[index].id))
                      .order(Message_.id, flags: Order.descending)
                      .build()
                      .findFirst();
                  return Card(
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return ChatScreenPage(u: uList[index]);
                            },
                          ),
                        );
                      },
                      title: Text(uList[index].name),
                      subtitle: msg == null
                          ? null
                          : Text(
                              utf8.decode(msg.data),
                              maxLines: 2,
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 64),
              if (kDebugMode) const Text("/* DEBUG */"),
              if (kDebugMode)
                SizedBox(
                  width: double.maxFinite,
                  child: OutlinedButton(
                    child: const Text("eventQueue"),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) {
                          return const EventQueuePage();
                        }),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return const AddContact();
              },
            ),
          );
          loadUserList();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
