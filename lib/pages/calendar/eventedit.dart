import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:p3pch4t/classes/calendar.v1/calendarevent.dart';
import 'package:p3pch4t/helpers/prefs.dart';

class CalendarEventEdit extends StatefulWidget {
  const CalendarEventEdit({Key? key, required this.cEvt}) : super(key: key);

  final P3pCalendarEvent cEvt;

  @override
  State<CalendarEventEdit> createState() => _CalendarEventEditState();
}

class _CalendarEventEditState extends State<CalendarEventEdit> {
  late final titleCtrl = TextEditingController(text: cEvt.title);
  late final aboutCtrl = TextEditingController(text: cEvt.about);
  late P3pCalendarEvent cEvt = widget.cEvt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar Event Edit"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Title',
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              SelectableText(cEvt.nonce),
              const SizedBox(
                height: 16,
              ),
              TextField(
                controller: aboutCtrl,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'About',
                ),
              ),
              const Text("Start"),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final newDate = await showDatePicker(
                            context: context,
                            initialDate: cEvt.eventStart,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 100)));
                        if (newDate == null) return;
                        setState(() {
                          cEvt.eventStart = newDate;
                        });
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        formatDate(cEvt.eventStart, [yyyy, '/', mm, '/', dd]),
                      ),
                    ),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final newTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(cEvt.eventStart),
                        );
                        var newDate = cEvt.eventStart;
                        if (newTime == null) return;
                        newDate = newDate.copyWith(
                            hour: newTime.hour, minute: newTime.minute);
                        setState(() {
                          cEvt.eventStart = newDate;
                        });
                      },
                      icon: const Icon(Icons.alarm),
                      label: Text(formatDate(cEvt.eventStart, [HH, ':', nn])),
                    ),
                  ),
                ],
              ),
              const Text("End"),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final newDate = await showDatePicker(
                            context: context,
                            initialDate: cEvt.eventStart,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 100)));
                        if (newDate == null) return;
                        setState(() {
                          cEvt.eventEnd = newDate;
                        });
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        formatDate(cEvt.eventEnd, [yyyy, '/', mm, '/', dd]),
                      ),
                    ),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final newTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(cEvt.eventEnd));
                        var newDate = cEvt.eventEnd;
                        if (newTime == null) return;
                        newDate = newDate.copyWith(
                            hour: newTime.hour, minute: newTime.minute);
                        setState(() {
                          cEvt.eventEnd = newDate;
                        });
                      },
                      icon: const Icon(Icons.alarm),
                      label: Text(formatDate(cEvt.eventEnd, [HH, ':', nn])),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  if (cEvt.id == 0) Navigator.of(context).pop();
                  setState(() {
                    cEvt.eventStart = DateTime.fromMicrosecondsSinceEpoch(0);
                    cEvt.eventEnd = DateTime.fromMicrosecondsSinceEpoch(0);
                    cEvt.about = "";
                    cEvt.deleted = true;
                    cEvt.title = "===deleted===";
                  });
                  p3pCalendarEventBox.put(cEvt);
                  cEvt.syncCalendar();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete),
                label: const Text("Delete"),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          cEvt.title = titleCtrl.text;
          cEvt.about = aboutCtrl.text;
          p3pCalendarEventBox.put(cEvt);
          cEvt.syncCalendar();
          Navigator.of(context).pop();
        },
        label: const Text("Save & sync"),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
