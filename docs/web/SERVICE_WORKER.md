# كاش الويب بـ Service Worker / Web cache with a service worker

يخزّن `siro_gl_web/assets/siro_sw.js` بلاطات الخريطة والـ glyphs والـ sprites بـ Cache API. الخريطة اللي فتحت مرة بتفتح بعدها بدون شبكة، والتخزين محدود بعدد المداخل (2000).
The script stores map tiles, glyphs and sprites in the Cache API. A map that was opened once opens again without the network. The store is limited to 2000 entries.

## التفعيل / Enabling it

1. انسخ `siro_sw.js` لجذر تطبيق الويب (جنب `index.html`).
   Copy `siro_sw.js` to the web root of your app (next to `index.html`).
2. في `index.html` أضف قبل تحميل تطبيق Flutter:
   In `index.html`, add this before the Flutter app loads:

```html
<script>
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('siro_sw.js');
    });
  }
</script>
```

3. الـ service worker يشتغل على `https` أو `localhost` فقط، وهذا قيد من المتصفح.
   A service worker only runs on `https` or `localhost`. This is a browser rule.

## ما الذي يُخزّن / What is cached

- `.pbf`, `.mvt` (بلاطات المتجهات)، و`.png`, `.jpg`, `.webp` (بلاطات الصور و sprites).
- أي مسار فيه `/tiles/`، أو `/glyphs/`، أو `/sprite`.
- ردود `GET` الناجحة فقط. الباقي بيروح للشبكة مباشرة.

## ما الذي لا يُخزّن / What is not cached

- طلبات الستايل نفسه (JSON) وأي شي غير الموارد أعلاه. الستايل بيتحمّل من الشبكة كل مرة.

## التحقق / Checking it

افتح DevTools، تبويب Application، Cache Storage، واسم الكاش `siro-gl-map-v1`. بعد التصفح بتشوف المداخل. أعد تحميل الصفحة مع Offline في تبويب Network، والخريطة لازم تظهر من الكاش.
Open DevTools, the Application tab, Cache Storage, and the cache named `siro-gl-map-v1`. After browsing, the entries appear there. Reload with Offline set in the Network tab: the map should draw from the cache.

ملاحظة: التحقق بالكامل تم على Chrome في هذه المرحلة بالـ DevTools يدوياً. اختبار آلي للـ service worker ما انعمل بعد.
Note: the check was done by hand in Chrome's DevTools. An automated test for the service worker does not exist yet.
