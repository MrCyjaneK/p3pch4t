import 'package:flutter/services.dart';
import 'package:objectbox/objectbox.dart';
import 'package:openpgp/openpgp.dart' as pgp;
import 'package:p3pch4t/helpers/pgp.dart';
import 'package:p3pch4t/helpers/prefs.dart';

@Entity()
class PublicKey {
  PublicKey({
    required this.publicKey,
  });

  @Id()
  int id = 0;

  @Property(type: PropertyType.date)
  DateTime timeAdded = DateTime.now();

  String publicKey;

  Future<String> encryptForMe(Uint8List data) async {
    var encrypted = await pgp.OpenPGP.encryptBytes(data, publicKey);
    var signed = await pgp.OpenPGP.signBytes(
        encrypted, publicKey, prefs.getString("privkey")!, passpharse);
    var armored = await pgp.OpenPGP.armorEncode(signed);
    return armored;
  }
}

Future<PublicKey> getSelfPubKey() async {
  return PublicKey(
    publicKey: await pgp.OpenPGP.convertPrivateKeyToPublicKey(
      prefs.getString("privkey")!,
    ),
  );
}
