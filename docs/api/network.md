# الشبكة / Network

```dart
await setNetworkStatsEnabled(true);
await resetNetworkStats();
// ... use the map ...
final stats = await getNetworkStats();
print('${stats.requests} requests, ${stats.bytes ?? 'no byte count'} bytes');

await setSiroRequestHeaders(app: 'tactical', version: '1.2.3');
await setOffline(true); // fails the map's requests until setOffline(false)
```

## الحدود / Limits

- `bytes`: Android فقط (من Content-Length، والـ chunked ما بيتعدّ). iOS يرجع `null`.
- عداد Android يبدّل الـ HTTP client، فالهيدرات اللي وضعتها `setCustomHeaders` لخريطة معيّنة بتتمسح لحد ما تعيد وضعها.
- `setOffline` على iOS: الـ SDK ما فيه مفتاح، فالـ plugin يفشل طلبات الخريطة بنفسه. الـ packs الموجودة ما بتتغير.
- `setSiroRequestHeaders` يستبدل كل الهيدرات اللي وضعتها قبل، فحط كل اللي تحتاجه في مكان واحد.
