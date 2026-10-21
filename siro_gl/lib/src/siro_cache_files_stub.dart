// Web stub for the cache's file work. The web has no file system, so there
// is no database file to measure or seed.

/// Size of the file at [path], or null when there is no file system.
Future<int?> databaseFileSize(String path) async => null;

/// Writes [bytes] to a temporary file and returns its path.
Future<String> writeTemporaryFile(List<int> bytes, String name) {
  throw UnsupportedError(
    'Seeding the offline database is not available on web.',
  );
}

/// The version tag of the last seed written next to [databasePath], or null.
Future<String?> readSeedVersion(String databasePath) async => null;

/// Records [versionTag] as the seed version next to [databasePath].
Future<void> writeSeedVersion(String databasePath, String versionTag) async {}
