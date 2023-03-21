import 'package:i2p_flutter/i2p_flutter.dart';
import 'package:p3pch4t/classes/downloadqueue.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:p3pch4t/objectbox.g.dart';

Future<List<int>> doEventTasks() async {
  if (!await i2pFlutterPlugin.isRunning()) {
    // print("restarting i2pd..");
    i2pFlutterPlugin.runI2pd();
    // notify(333, "i2pd started!", "I2pd wasn't running! We had to restart it.");
  }
  List<Event> events = eventBox.query().order(Event_.id).build().find();

  int statTotal = events.length;
  int statRemoved = 0;
  int statProcessed = 0;
  downloadParts();
  List<String> connstringSkipList = [];
  for (var event in events) {
    if (event.destinations.isEmpty) {
      eventBox.remove(event.id);
      statRemoved++;
    }
    if (event.relayTries == 0) {
      // It looks like theevent just got queued, retry sending just in case.
      await event.trySend(connstringSkipList);
    } else {
      //    We were unable to send the event for a long amount of time (3 tries)
      // So we will try to send it:
      // For first hour - every 1 minute
      // For 1-6 hours - every 2 minutes
      // For 7-12 hours - every 5 minutes
      // For 13-48 hours - every 10 minutes
      // For 49-168 hours - every 20 minutes
      // For 169< - every hour.
      // As far as I am concerned it shouldn't cause any significant resource
      // and is done more to not cause significant delays when sending newer
      // events.
      // Events will never get canceled. And all should get delivered once
      // destination becomes online.
      //
      int createHourDiff = event.lastRelayed.difference(event.creationDate).inHours;
      int minuteDiff = DateTime.now().difference(event.lastRelayed).inMinutes;
      // print("createHourDiff: $createHourDiff; minuteDiff: $minuteDiff");
      if ((createHourDiff <= 1 && minuteDiff >= 1) ||
          (createHourDiff >= 7 && minuteDiff >= 2) ||
          (createHourDiff >= 13 && minuteDiff >= 5) ||
          (createHourDiff >= 49 && minuteDiff >= 10) ||
          (createHourDiff >= 169 && minuteDiff >= 20)) {
        statProcessed++;
        if (!(await event.trySend(connstringSkipList))) {
          for (var elm in event.destinations) {
            // connstringSkipList.add(elm.connstring);
          }
        }
      }
    }
  }
  return [statTotal, statProcessed, statRemoved];
}
