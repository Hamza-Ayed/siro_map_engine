# كاش الخوادم / Server caching

هذه وثيقة للخادم اللي بيخدم البلاطات والستايلات والـ glyphs والـ sprites. المحرك بيعتمد على هيدرات الكاش، فإذا كانت صح، الكاش بيشتغل من غير ما نغيّر كود التطبيق.
This is for the server that serves tiles, styles, glyphs and sprites. The engine relies on cache headers, so when they are right, caching works without changing app code.

## المسارات / Paths

- كل إصدار من البلاطات في المسار: `/v1/tiles/{z}/{x}/{y}.pbf` (غيّر `v1` مع كل إعادة بناء).
- Put a version in the tile path. Change the version whenever the tiles are rebuilt.

## الهيدرات / Headers

```
Cache-Control: public, max-age=31536000, immutable
ETag: "<hash of the tile>"
Content-Encoding: gzip   (أو br للـ pbf)
Access-Control-Allow-Origin: *   (للويب)
```

- `immutable` مع إصدار في المسار: المتصفح والمحرك ما بيطلبوا البلاطة مرة ثانية.
- ETag: عشان 304 تشتغل لو الإصدار ما تغيّر، والمحرك بيحترمها.
- ما تضيف `Cache-Control: no-cache` على البلاطات، لأنها بتكسر الكاش.

## CDN

- خلّي الـ CDN يكاش البلاطات حسب المسار (مع الإصدار)، مش حسب الـ query string.
- ضغط gzip أو br للـ pbf. الـ pbf ما بينضغط مرتين.
- CORS: `Access-Control-Allow-Origin` لازم يكون موجود لطلبات الويب، وإلا المتصفح بيرفض البلاطة.

## ما لا يُكاش / What should not be cached forever

- الستايل JSON: يتحدّث، فـ `max-age` قصير، أو إصدار جديد بالمسار.

ملاحظة: هذه وثيقة فقط. التنفيذ على الخادم خارج هذا المستودع.
Note: this is documentation only. The server itself is outside this repository.
