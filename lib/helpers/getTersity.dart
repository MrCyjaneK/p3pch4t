import 'package:duration/duration.dart';

DurationTersity getTeristy(Duration difference) {
  if (difference.inMinutes < 1) {
    return DurationTersity.second;
  } else if (difference.inHours < 24) {
    return DurationTersity.minute;
  } else if (difference.inHours < 48) {
    return DurationTersity.hour;
  } else {
    return DurationTersity.day;
  }
}
