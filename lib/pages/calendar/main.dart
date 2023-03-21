import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/pages/calendar/eventedit.dart';
import 'package:p3pch4t/pages/calendar/eventview.dart';
import 'package:p3pch4t/classes/calendar.v1/calendarevent.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:p3pch4t/transport/server/p3pmd.dart';
import 'package:table_calendar/table_calendar.dart';

class UserCalendarPage extends StatefulWidget {
  const UserCalendarPage({Key? key, required this.u}) : super(key: key);

  final User u;

  @override
  State<UserCalendarPage> createState() => _UserCalendarPageState();
}

class _UserCalendarPageState extends State<UserCalendarPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.u.name}'s events"),
        backgroundColor: widget.u.backgroundColor,
        foregroundColor: widget.u.backgroundColor == null
            ? null
            : widget.u.backgroundColor!.computeLuminance() > 0.379
                ? Colors.black
                : Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _tableCalendar(),
              const Divider(),
              ...genEventWidgets(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final cEvt = P3pCalendarEvent(
              userId: widget.u.id, title: "New event", about: "");
          cEvt.eventStart = focusedDay;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return CalendarEventEdit(cEvt: cEvt);
              },
            ),
          );
          setState(() {
            focusedDay = focusedDay;
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> genEventWidgets() {
    List<Widget> toret = [];
    for (var elm in getEventsForDay(focusedDay)) {
      final startStr = formatDate(elm.eventStart, [HH, ':', nn]);
      final endStr =
          formatDate(elm.eventEnd, [yyyy, '/', mm, '/', dd, ' ', HH, ':', nn]);
      toret.add(
        Card(
          child: ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) {
                  return CalendarEventView(cEvt: elm);
                }),
              );
            },
            onLongPress: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) {
                  return CalendarEventEdit(cEvt: elm);
                }),
              );
              setState(() {
                focusedDay = focusedDay;
              });
            },
            subtitle: p3pMd(
              msgTxt: """# ${elm.title}
| Start | End |
| ----- | --- |
| $startStr | $endStr |
""",
            ),
          ),
        ),
      );
    }
    return toret;
  }

  DateTime focusedDay = DateTime.now();

  TableCalendar<dynamic> _tableCalendar() {
    return TableCalendar(
      focusedDay: focusedDay,
      selectedDayPredicate: (day) {
        return isSameDay(focusedDay, day);
      },
      firstDay: widget.u.lastSeen,
      lastDay: DateTime.now().add(
        const Duration(days: 365 * 10),
      ),
      pageJumpingEnabled: true,
      startingDayOfWeek: StartingDayOfWeek.monday,
      eventLoader: getEventsForDay,
      onDaySelected: (newSelectedDay, newFocusedDay) {
        setState(() {
          focusedDay = newSelectedDay;
        });
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return null;
          return Text(events.length.toString());
        },
      ),
    );
  }

  List<dynamic> getEventsForDay(day) {
    List<P3pCalendarEvent> cevts = p3pCalendarEventBox
        .query(P3pCalendarEvent_.userId.equals(widget.u.id))
        .build()
        .find();
    cevts.removeWhere((element) => !isSameDay(element.eventStart, day));
    return cevts;
  }
}
