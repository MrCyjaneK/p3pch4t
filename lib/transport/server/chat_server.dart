import 'dart:convert';

import 'package:openpgp/openpgp.dart';
import 'package:p3pch4t/helpers/pgp.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:p3pch4t/transport/server/calendar.v1/syncv1.dart';
import 'package:p3pch4t/transport/server/ssmdc.v1/event.dart';
import 'package:p3pch4t/transport/server/ssmdc.v1/selfpgp.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:p3pch4t/transport/server/handleText.dart';
import 'package:p3pch4t/transport/server/handleIntroduction.dart';
import 'package:p3pch4t/transport/server/serveFile.dart';
import 'package:p3pch4t/transport/server/handleFile.dart';
import 'package:http/http.dart' as http;

Future<void> runWebserver() async {
  try {
    var resp = await http.read(Uri.parse('http://127.0.0.1:16424/'));
    if (resp == "p3p") {
      print("Server running, not starting");
      return;
    } else {}
  } catch (e) {
    print(e);
  }
  var app = Router();

  app.get('/', (Request request) {
    print("Got a / request");
    return Response.ok('p3p');
  });

  app.all('/core/selfpgp', coreSelfpgp);
  app.all('/core/event', coreEvent);
  app.all('/file.v1/<userId>/<fileId>/<start>/<end>', serveFile);
  app.all('/file.v2/<userId>/<fileId>/<start>/<end>', serveFileV2);
  app.all('/ssmdc.v1/<groupUid>/core/selfpgp', ssmdcv1coreSelfpgp);
  app.all('/ssmdc.v1/<groupUid>/core/event', ssmdcv1coreEvent);
  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(app);
  var server = await shelf_io.serve(handler, '127.0.0.1', 16424);
}

coreEvent(Request request) async {
  var req = await decodeObj(
      await request.readAsString(), prefs.getString("privkey").toString());
  print("Got new event: ${req["body"]["body"]["type"]}");
  switch (req["body"]["body"]["type"]) {
    case "text.v1":
      return await handleTextV1(req);
    case 'introduce.v1':
      return await handleIntroductionV1(req);
    case 'file.v1':
      return await handleFileV1(req);
    case 'calendar.v1.sync.v1':
      return await handleCalendarV1SyncV1(req);
    default:
      return json({"ok": false, "message": "Unsupported event type"});
  }

  return json({"ok": true});
}

// request: /core/selfpgp
coreSelfpgp(Request request) async {
  //var req = await decodeObj(await request.readAsString());
  var pubkey =
      await OpenPGP.convertPrivateKeyToPublicKey(prefs.getString("privkey")!);

  return Response.ok(pubkey);
}

// all requests body must be packaged in something that looks like this:
// body: {
//   "senderpgp": "----- {...} -----",
//   "signature": "----- {...} -----", // signature of .body
//   "body": "{...}" json-encoded object
// }
// and encrypted with target's OpenPGP key. (except for /core/selfpgp
// - which returns plaintext PGP key)
Future<Map<String, dynamic>> decodeObj(String req, String privkey) async {
  var rawBody = jsonDecode(
    await OpenPGP.decrypt(
      req,
      privkey,
      passpharse,
    ),
  );

  bool isValid = await OpenPGP.verify(
    rawBody["signature"],
    rawBody["body"],
    rawBody["senderpgp"],
  );
  rawBody["body"] = jsonDecode(rawBody["body"]);
  return {
    "isValid": isValid,
    "body": rawBody,
  };
}

Response json(dynamic obj) {
  return Response.ok(
    jsonEncode(obj),
    headers: {
      "Content-Type": "application/json",
    },
  );
}

// [p3pch4t]
// type = http
// host = 127.0.0.1
// port = 16424
// keys = p3pch4t.dat
