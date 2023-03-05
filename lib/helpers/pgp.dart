import 'package:openpgp/openpgp.dart';
import 'package:p3pch4t/prefs.dart';

const passpharse = "null";

Future<void> GenPGP(String name, String email) async {
  Stopwatch stopwatch = Stopwatch()..start();
  var keyOptions = KeyOptions()
    ..rsaBits = 4096
    ..algorithm = Algorithm.RSA;
  print("generating....");

  try {
    var keyPair = await OpenPGP.generate(
        options: Options()
          ..name = name
          ..email = email
          ..passphrase = passpharse
          ..keyOptions = keyOptions);
    print(keyPair.publicKey);
    print("${stopwatch.elapsed.inMilliseconds} ms");
    prefs.setString("privkey", keyPair.privateKey);
  } catch (e) {
    print(e.toString());
  }
}
