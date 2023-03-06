import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:p3pch4t/add_contact.dart';
import 'package:p3pch4t/chatscreen.dart';
import 'package:p3pch4t/classes/message.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/creategrouppage.dart';
import 'package:p3pch4t/groupslistpage.dart';
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
        title: const Text("P3P ch4t"),
      ),
      drawer: const AppDrawer(),
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

class AppDrawer extends StatefulWidget {
  const AppDrawer({
    super.key,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late String p3pTxt = _getp3p();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SafeArea(child: Container()),
            Container(
              width: double.maxFinite,
              height: 180,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Center(
                child: SizedBox(
                  width: double.maxFinite,
                  child: TextButton(
                    child: Text(
                      p3pTxt,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    onPressed: () {
                      setState(() {
                        p3pTxt = _getp3p();
                      });
                    },
                    onLongPress: () {
                      if (p3pTxt.isEmpty && prefs.getBool("devmode") != true) {
                        prefs.setBool("devmode", true);
                        Future.delayed(const Duration(seconds: 1))
                            .then((value) {
                          exit(0);
                        });
                      }
                      if (p3pTxt.isNotEmpty) {
                        setState(() {
                          p3pTxt = p3pTxt.substring(1);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            _drawerButton(context, Icons.create, "Create group server",
                const CreateGroupPage()),
            if (ssmdcv1GroupConfigBox.getAll().isNotEmpty)
              _drawerButton(
                  context, Icons.group, "Manage groups", GroupListPage()),
            _drawerButton(
                context, Icons.settings, "Settings", const SettingsPage()),
          ],
        ),
      ),
    );
  }

  String _getp3p() {
    final s =
        'p3p p3P p3q p39 pep peP peq pe9 P3p P3P P3q P39 Pep PeP Peq Pe9 q3p q3P q3q q39 qep qeP qeq qe9 93p 93P 93q 939 9ep 9eP 9eq 9e9'
            .split(" ");
    s.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
    return s[0];
  }

  ListTile _drawerButton(
      BuildContext context, IconData icond, String title, Widget newPage) {
    return ListTile(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return newPage;
          },
        ));
      },
      leading: Icon(icond),
      title: Text(title),
    );
  }
}
