# مرجع الواجهات / API reference

صفحات قصيرة لكل واجهة جديدة، مع مثال. الدوال الكاملة بالـ dartdoc في الكود.
Short pages for each new API, with an example. Full signatures are in the dartdoc comments.

| الواجهة / API | الوصف / What it does | الصفحة / Page |
|---|---|---|
| `SiroCache` | الكاش المحلي وقاعدة الأوفلاين: الحد، الإحصاءات، البذرة، ومنطقة الـ prefetch / The ambient cache and offline database: limit, stats, seed, prefetch | [cache.md](cache.md) |
| `setNetworkStatsEnabled`، `getNetworkStats`، `resetNetworkStats` | عداد طلبات الخريطة / Counts the map's requests | [network.md](network.md) |
| `setSiroRequestHeaders` | هيدرات Siro (`X-Siro-App`، `X-Siro-Version`) / Siro's identifying headers | [network.md](network.md) |
| `setOffline` | وضع الأوفلاين المفروض / Forced offline mode | [network.md](network.md) |
| `SiroMap(debugOverlay: true)` | لوحة للتجربة: FPS، طلبات، حجم القاعدة / A tuning panel: FPS, requests, database size | [debug-overlay.md](debug-overlay.md) |
