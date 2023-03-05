import 'package:p3pch4t/classes/ssmdc.v1/groupconfig.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
import 'package:shelf/shelf.dart';

ssmdcv1coreSelfpgp(Request request, String groupUid) async {
  SSMDCv1GroupConfig? group = ssmdcv1GroupConfigBox
      .query(SSMDCv1GroupConfig_.uid.equals(groupUid))
      .build()
      .findFirst();
  if (group == null) {
    return Response.notFound("not found");
  }
  var pubkey = await group.groupPublicKey();

  return Response.ok(pubkey);
}
