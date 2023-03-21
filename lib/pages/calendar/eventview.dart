import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/calendar.v1/calendarevent.dart';
import 'package:p3pch4t/transport/server/p3pmd.dart';

class CalendarEventView extends StatelessWidget {
  const CalendarEventView({Key? key, required this.cEvt}) : super(key: key);

  final P3pCalendarEvent cEvt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cEvt.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: p3pMd(
            msgTxt: """ - :alarm_clock: starts ${cEvt.eventStart.toLocal()}
 - :alarm_clock: duration ${prettyDuration(Duration(seconds: cEvt.eventDurationSeconds))}
 - :alarm_clock: ends ${cEvt.eventEnd.toLocal()}
 
 ------

 ${cEvt.about}""",
          ),
        ),
      ),
    );
  }
}
