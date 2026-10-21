part of '../siro_gl.dart';

/// Result of [SiroCache.stats].
class SiroCacheStats {
  /// Creates the stats. Each field is null when it cannot be read.
  const SiroCacheStats({
    this.databasePath,
    this.databaseSizeBytes,
    this.maxAmbientBytes,
  });

  /// The offline database file, or null where there is no file system.
  final String? databasePath;

  /// Size of [databasePath] on disk, in bytes.
  final int? databaseSizeBytes;

  /// The ambient cache limit this app last set with
  /// [SiroCache.setMaximumAmbientCacheSize]. The SDK has no getter for it.
  final int? maxAmbientBytes;

  @override
  String toString() =>
      'SiroCacheStats(databaseSizeBytes: $databaseSizeBytes, '
      'maxAmbientBytes: $maxAmbientBytes, databasePath: $databasePath)';
}

/// The map's cache: the ambient cache (tiles the map has loaded) and the
/// offline database behind it.
///
/// Web keeps tiles in the browser, so the calls that talk to the native
/// database do nothing there. [stats] reports what it can, and
/// [seedFromAsset] throws on web.
class SiroCache {
  SiroCache._();

  static int? _maxAmbientBytes;

  /// Sets the ambient cache limit to [bytes]. Android and iOS.
  static Future<void> setMaximumAmbientCacheSize(int bytes) async {
    if (bytes < 0) {
      throw ArgumentError.value(bytes, 'bytes', 'must not be negative');
    }
    if (kIsWeb) return;
    await _globalChannel.invokeMethod<void>(
      'setMaximumAmbientCacheSize',
      <String, dynamic>{'bytes': bytes},
    );
    _maxAmbientBytes = bytes;
  }

  /// Marks the ambient cache stale, so tiles are checked again before use.
  /// Android and iOS.
  static Future<void> invalidateAmbientCache() async {
    if (kIsWeb) return;
    await _globalChannel.invokeMethod<void>('invalidateAmbientCache');
  }

  /// Compacts the offline database file. Android only: the iOS SDK has no
  /// such call, and there this throws a [PlatformException] with code
  /// `UNSUPPORTED`.
  static Future<void> packDatabase() async {
    if (kIsWeb) return;
    await _globalChannel.invokeMethod<void>('packDatabase');
  }

  /// Turns forced offline mode on or off. See [setOffline].
  static Future<void> setOfflineMode(bool offline) async {
    if (kIsWeb) return;
    await setOffline(offline);
  }

  /// Reports the database path and size, and the limit this app set.
  static Future<SiroCacheStats> stats() async {
    final path = kIsWeb ? null : await getOfflineDatabasePath();
    final size = path == null ? null : await databaseFileSize(path);
    return SiroCacheStats(
      databasePath: path,
      databaseSizeBytes: size,
      maxAmbientBytes: _maxAmbientBytes,
    );
  }

  /// Copies the offline database bundled as [assetPath] into the cache and
  /// merges its regions in. Skips the copy when [versionTag] matches the one
  /// recorded by the last seed, so a relaunch does not repeat the work.
  ///
  /// Returns true when the seed was merged, false when it was skipped.
  /// Android and iOS only.
  static Future<bool> seedFromAsset(
    String assetPath, {
    String? versionTag,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Seeding the offline database is not available on web.',
      );
    }
    final databasePath = await getOfflineDatabasePath();
    if (databasePath == null) return false;
    if (versionTag != null &&
        await readSeedVersion(databasePath) == versionTag) {
      return false;
    }
    final data = await rootBundle.load(assetPath);
    final tempPath = await writeTemporaryFile(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      'siro_seed_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await mergeOfflineRegions(tempPath);
    if (versionTag != null) {
      await writeSeedVersion(databasePath, versionTag);
    }
    return true;
  }

  /// The box of [radiusKm] around [center], as a latitude and longitude box.
  ///
  /// Latitude is clamped to ±85. Longitude is clamped to just inside ±180:
  /// `LatLng` wraps 180 to -180, which would turn the box inside out. A box
  /// that crosses the antimeridian is therefore cut at the edge, not split.
  static LatLngBounds boundsAround(LatLng center, double radiusKm) {
    const kmPerDegreeLatitude = 111.32;
    final latitudeDelta = radiusKm / kmPerDegreeLatitude;
    final cosLatitude = cos(center.latitude * pi / 180).abs();
    final longitudeDelta =
        radiusKm / (kmPerDegreeLatitude * max(cosLatitude, 1e-6));
    double clampLatitude(double value) => value.clamp(-85.0, 85.0);
    double clampLongitude(double value) => value.clamp(-179.9999, 179.9999);
    return LatLngBounds(
      southwest: LatLng(
        clampLatitude(center.latitude - latitudeDelta),
        clampLongitude(center.longitude - longitudeDelta),
      ),
      northeast: LatLng(
        clampLatitude(center.latitude + latitudeDelta),
        clampLongitude(center.longitude + longitudeDelta),
      ),
    );
  }

  /// Downloads the tiles around [center] for [minZoom]..[maxZoom] as an
  /// offline region, marked as automatic. Keeps at most
  /// [maxAutomaticRegions] automatic regions and deletes the oldest ones.
  ///
  /// The download is not limited to Wi-Fi: that check is not implemented yet.
  static Future<OfflineRegion> prefetchAround(
    LatLng center, {
    required double radiusKm,
    required String styleUrl,
    int minZoom = 10,
    int maxZoom = 14,
    int maxAutomaticRegions = 3,
  }) async {
    final region = await downloadOfflineRegion(
      OfflineRegionDefinition(
        bounds: boundsAround(center, radiusKm),
        mapStyleUrl: styleUrl,
        minZoom: minZoom.toDouble(),
        maxZoom: maxZoom.toDouble(),
      ),
      metadata: const {'siro_auto': true},
    );
    await _trimAutomaticRegions(maxAutomaticRegions);
    return region;
  }

  static Future<void> _trimAutomaticRegions(int keep) async {
    final regions =
        (await getListOfRegions())
            .where((region) => region.metadata['siro_auto'] == true)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    for (final oldest in regions.take(max(0, regions.length - keep))) {
      await deleteOfflineRegion(oldest.id);
    }
  }
}
