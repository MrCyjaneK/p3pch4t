import 'package:objectbox/objectbox.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:random_string/random_string.dart';

@Entity()
class P3pCalendarEvent {
  P3pCalendarEvent({
    required this.userId,
    required this.title,
    required this.about,
  });
  @Id()
  int id = 0;

  Future<void> syncCalendar() async {
    User? u = userBox.get(userId);
    if (u == null) return;
    final evt = await Event.newCalendarSync(u);
    evt.id = u.queueSendEvent(evt);
  }

  String nonce = randomAlphaNumeric(16);
  int userId;

  String title;

  bool deleted = false;

  @Property(type: PropertyType.date)
  DateTime eventStart = DateTime.now();

  @Transient()
  DateTime get eventEnd {
    return eventStart.add(Duration(seconds: eventDurationSeconds));
  }

  @Transient()
  set eventEnd(DateTime newEventEnd) {
    eventDurationSeconds = eventStart.difference(newEventEnd).inSeconds.abs();
  }

  int eventDurationSeconds = 60 * 60;

  // @Property(type: PropertyType.date)
  // DateTime eventEnd = DateTime.now();

  // String rawReminders = "";
  //
  // @Transient()
  // List<DateTime> get reminders

  String about;

  Map<String, dynamic> toJson() {
    return {
      "nonce": nonce,
      "title": title,
      "eventStart": eventStart.toIso8601String(),
      "eventEnd": eventEnd.toIso8601String(),
      "about": about,
      "deleted": deleted,
    };
  }
}
