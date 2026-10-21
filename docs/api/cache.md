# SiroCache

الكاش المحلي (البلاطات اللي شافها المحرك) وقاعدة الأوفلاين وراه. Android وiOS. على الويب البلاطات في كاش المتصفح، والدوال هون ما تعمل شي إلا `stats`.
The ambient cache (tiles the engine has seen) and the offline database behind it. Android and iOS. On web, tiles live in the browser cache: these calls do nothing there, except `stats`.

```dart
await SiroCache.setMaximumAmbientCacheSize(300 * 1024 * 1024); // 300 MB
await SiroCache.invalidateAmbientCache();                       // mark stale
final stats = await SiroCache.stats();
print(stats.databaseSizeBytes);

// Seed the offline database from a bundled file, once per version.
await SiroCache.seedFromAsset('assets/seed/jordan.db', versionTag: 'jordan-2026-10');

// Download the tiles around a point. Keeps the 3 newest automatic regions.
await SiroCache.prefetchAround(
  const LatLng(31.9539, 35.9106),
  radiusKm: 8,
  styleUrl: 'https://example.com/style.json',
);
```

## الحدود / Limits

- `packDatabase()`: Android فقط. iOS يرجع `UNSUPPORTED` لأن الـ SDK ما فيه هالدالة.
- `SiroCacheStats.maxAmbientBytes`: آخر قيمة وضعها التطبيق. الـ SDK ما فيه getter لها.
- `prefetchAround`: ما فيه تحديد للـ Wi-Fi فقط بعد. التنزيل يمشي على أي شبكة.
- `seedFromAsset`: الملف لازم يكون صيغة offline database للمحرك (ينتجه `exportOfflineDatabase`).
