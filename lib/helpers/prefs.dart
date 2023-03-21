import 'package:p3pch4t/classes/calendar.v1/calendarevent.dart';
import 'package:p3pch4t/classes/downloadqueue.dart';
import 'package:p3pch4t/classes/event.dart';
import 'package:p3pch4t/classes/fileevt.dart';
import 'package:p3pch4t/classes/filev2.dart';
import 'package:p3pch4t/classes/message.dart';
import 'package:p3pch4t/classes/privkey.dart';
import 'package:p3pch4t/classes/ssmdc.v1/groupconfig.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

late SharedPreferences prefs;

late Box<User> userBox;
late Box<Message> messageBox;
late Box<PublicKey> publicKeyBox;
late Box<Event> eventBox;
late Box<FileEvt> fileevtBox;
late Box<FileV2> fileV2Box;
late Box<DownloadItem> downloadItemBox;
late Box<SSMDCv1GroupConfig> ssmdcv1GroupConfigBox;
late Box<P3pCalendarEvent> p3pCalendarEventBox;

late final Store store;

bool isStoreLoaded = false;

Future<void> initStorage() async {
  if (isStoreLoaded) return;
  isStoreLoaded = true;
  final docsDir = await getApplicationDocumentsDirectory();
  final storePath = p.join(docsDir.path, "p3p-ch4t-dtrue");
  try {
    print(docsDir);
    store = await openStore(directory: storePath);
  } catch (e) {
    print("e!!!: $e");
    store = Store.attach(getObjectBoxModel(), storePath);
  }
  userBox = store.box();
  messageBox = store.box();
  publicKeyBox = store.box();
  eventBox = store.box();
  fileevtBox = store.box();
  fileV2Box = store.box();
  downloadItemBox = store.box();
  ssmdcv1GroupConfigBox = store.box();
  p3pCalendarEventBox = store.box();
  cleanEvents();
  prefs = await SharedPreferences.getInstance();
}

void cleanEvents() {
  List<Event> events = [];
  events = eventBox.getAll();
  for (var event in events) {
    if (event.destinations.isEmpty) {
      eventBox.remove(event.id);
    }
  }
}
