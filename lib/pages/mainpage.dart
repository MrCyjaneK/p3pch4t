import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:i2p_flutter/i2p_flutter.dart';
import 'package:p3pch4t/pages/add_contact.dart';
import 'package:p3pch4t/browser/mainpage.dart';
import 'package:p3pch4t/pages/chat/chatscreen.dart';
import 'package:p3pch4t/classes/message.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/pages/group/creategrouppage.dart';
import 'package:p3pch4t/pages/debug/errorpage.dart';
import 'package:p3pch4t/pages/debug/eventqueuepage.dart';
import 'package:p3pch4t/pages/group/listpage.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/pages/welcome.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:p3pch4t/pages/settings.dart';

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
    _initRefresh();
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

  double? progress = 0.5;
  String? progressLabel = "Loading...";
  final p3pTxt = _getp3p();

  final i2pUptimeRequested = 15 * 60;

  Future<void> _refreshProgress() async {
    // check1, i2pd uptime
    int i2pUptime = await i2pFlutterPlugin.getUptimeSeconds();
    if (i2pUptime < i2pUptimeRequested) {
      if (mounted) {
        setState(() {
          progress = i2pUptime / i2pUptimeRequested;
          progressLabel =
              "(i2p): Discovering peers ETA: ${prettyDuration(Duration(seconds: i2pUptimeRequested - i2pUptime))}";
        });
      }
      return;
    }
    final eq = eventBox.getAll();
    if (eq.isNotEmpty) {
      if (mounted) {
        setState(() {
          progress = 1 - (eq.length / (eq.last.id));
          eq.last.id / (eq.last.id - eq.length);
          progressLabel = /* 2,9,7 */
              "Sending pending events (${eq.length} left..)";
        });
      }
      return;
    }
    setState(() {
      progress = progressLabel = null;
    });
  }

  void _initRefresh() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _refreshProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    prefs.reload();
    return Scaffold(
      appBar: AppBar(
        title: Text("${p3pTxt}ch4t"),
        actions: [
          if (prefs.getString("lastLog").toString() != "null")
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return const ErrorPage();
                    },
                  ),
                );
              },
              icon: const Icon(Icons.bug_report),
            ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) {
                  return const BrowserWidget();
                },
              ));
            },
            icon: const Icon(Icons.language),
          )
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: ListView.builder(
          shrinkWrap: false,
          itemCount: uList.length + 1,
          itemBuilder: (context, notIndex) {
            if (notIndex == 0) {
              if (progress != null && progress! < 1) {
                return Stack(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 22,
                    ),
                    if (progressLabel != null)
                      SizedBox(
                        height: 22,
                        width: double.maxFinite,
                        child: Center(
                          child: Text(
                            progressLabel!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                );
              } else {
                return const Text("");
              }
            }
            final index = notIndex - 1;
            Message? msg = messageBox
                .query(Message_.userId.equals(uList[index].id))
                .order(Message_.id, flags: Order.descending)
                .build()
                .findFirst();
            return Card(
              child: ListTile(
                onTap: () {
                  uList[index] = userBox.get(uList[index].id)!;
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
            if (prefs.getBool("devmode") == true) const Divider(),
            if (prefs.getBool("devmode") == true)
              _drawerButton(context, Icons.developer_board, "Event queue",
                  const EventQueuePage()),
            //TODO: would be nice to have it
            // if (prefs.getBool("devmode") == true)
            //   _drawerButton(context, Icons.developer_board, "FileEvt list",
            //       const EventQueuePage()),
          ],
        ),
      ),
    );
  }
}

String _getp3p() {
  final s =
      'p3p p3P p3q p39 pep peP peq pe9 P3p P3P P3q P39 Pep PeP Peq Pe9 q3p q3P q3q q39 qep qeP qeq qe9 93p 93P 93q 939 9ep 9eP 9eq 9e9'
          .split(" ");
  s.shuffle();
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
