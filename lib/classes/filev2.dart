import 'package:p3pch4t/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';
import 'package:random_string/random_string.dart';

@Entity()
class FileV2 {
  FileV2({
    required this.name,
    required this.parentFile,
  });

  @Id()
  int id = 0;

  String name;

  @Index()
  String fileUid = randomAlphaNumeric(16);
  @Index()
  String parentFile;

  @Property(type: PropertyType.byteVector)
  List<int>? contentBytes;

  @Transient()
  bool get isFile {
    return contentBytes != null;
  }

  @Transient()
  bool get isDirectory {
    return contentBytes == null;
  }
}
