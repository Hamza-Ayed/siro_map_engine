import 'dart:io';

/// Size of the file at [path], or null when it does not exist.
Future<int?> databaseFileSize(String path) {
  final file = File(path);
  return Future.value(file.existsSync() ? file.lengthSync() : null);
}

/// Writes [bytes] to a temporary file and returns its path.
Future<String> writeTemporaryFile(List<int> bytes, String name) async {
  final file = File('${Directory.systemTemp.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

String _seedVersionPath(String databasePath) =>
    '${File(databasePath).parent.path}/siro_seed_version.txt';

/// The version tag of the last seed written next to [databasePath], or null.
Future<String?> readSeedVersion(String databasePath) {
  final file = File(_seedVersionPath(databasePath));
  if (!file.existsSync()) return Future.value();
  return Future.value(file.readAsStringSync().trim());
}

/// Records [versionTag] as the seed version next to [databasePath].
Future<void> writeSeedVersion(String databasePath, String versionTag) async {
  await File(_seedVersionPath(databasePath)).writeAsString(versionTag);
}
