# خطة الـ 3D لمحرك سيرو (للتنفيذ)

> هاي الخطة بتفصّل **المرحلة 5** من [SIRO_ROADMAP.md](SIRO_ROADMAP.md).
> مكتوبة عشان ينفذها وكيل (Claude). كل مهمة إلها **مدخلات، خطوات، ملفات، وشرط قبول**.

---

## ⚠️ قواعد إلزامية للمنفّذ

> **القواعد وسير العمل وبوابات الجودة كلها من [SIRO_MASTER_PLAN.md](SIRO_MASTER_PLAN.md) القسم 1 والقسم 3، وهي الحاكمة.** المهام هون معرّفاتها `D-T0` … `D-T10` بـ PROGRESS.md.

1. **ممنوع تعديل** أي ملف برا `packages/siro_map_engine/`. الملفات `apps/**` و `packages/flutter-sdk/**` و `packages/android-kotlin-sdk/**` و `packages/ios-swift-sdk/**` **للقراءة فقط**، كمرجع.
2. مهمة وحدة بكل جلسة، والـ commit رسالته `feat(siro-gl): D-T<n> ...`.
3. إذا ما قدرت توصل لشرط القبول، أو صادفت قرار مش موجود بالخطة: **وقّف واكتب تقرير**. لا تخمّن ولا تعدّل نطاق المهمة.
4. ممنوع أي مكتبة جديدة غير المذكورة هون، إلا بعد موافقة.
5. كل نص بيظهر للمستخدم بيكون بالعربي. أسماء الكود بالإنجليزي.
6. هاي المرحلة بتبلّش **بعد المرحلة ID**. يعني الأسماء `siro_gl`، `siro_gl_platform_interface`، `siro_gl_example`، مش `maplibre_gl*`.
7. إصدار maplibre-gl-js جوا الـ WebView هو نفس إصدار `siro_gl_web` (حاليًا 6.4.1)، إلا إذا T0 أثبت سبب لغيره.

---

## 1. الوضع الحالي (نتيجة الدراسة)

### كيف بنينا الـ 3D حاليًا
**ما استخدمنا المحرك الأصلي (native) على Android وiOS.** الحل كان **WebView** بيشغّل **maplibre-gl-js 4.7.1** (نسخة الويب)، لأنه هو اللي بيدعم `setTerrain`.

| العنصر | المكان |
|---|---|
| الويدجت والكنترولر | `packages/flutter-sdk/lib/src/intaleq_3d_map.dart` (`Intaleq3DMap` و `Intaleq3DController`) |
| صفحة HTML/JS | مكتوبة كـ string جوا Dart (`_generateEngineHtml`، الأسطر 345 لـ 845) |
| مكتبة JS | `https://unpkg.com/maplibre-gl@4.7.1`، بتنزل من الإنترنت كل مرة |
| بيانات الارتفاعات (DEM) | `s3.amazonaws.com/elevation-tiles-prod/terrarium` (AWS عام، مش إلنا) |
| الستايل | `https://map-saas.intaleqapp.com/style-3d-terrain.json` (فيه `"terrain"` و hillshade وكنتور) |
| الجسر Dart ↔ JS | `runJavaScript("window.fn(...)")` باتجاه، و `JavaScriptChannel 'Intaleq3DBridge'` بالاتجاه الثاني |
| الاستخدام بالتطبيق | `apps/siro_maps/lib/views/map/map_view.dart:1851`: لما `mapTheme == terrain3D` بنستبدل الخريطة كاملة بـ `Intaleq3DMap` |
| استوديو التضاريس | `apps/siro_maps/lib/views/map/widgets/siro_3d_terrain_studio_screen.dart` (معالم، دوران، تضخيم، كنتور) |
| الـ SDKs الأصلية (Kotlin/Swift) | بتحمّل `style-3d-terrain.json` بس. المحرك الأصلي **بيتجاهل terrain** وبيرسم hillshade مسطّح بس، يعني ما في 3D حقيقي |

### أسباب التعليق اللي لقيتها بالكود
| # | السبب | المكان | الأثر |
|---|---|---|---|
| L1 | **المسار بينبعث من جديد مع كل rebuild.** `routePoints` بينبني كـ List جديدة بكل build (`expand().toList()`)، والمقارنة `!=` بتطلع دائمًا true، فبنبعث كل المسار JSON عبر الجسر | `map_view.dart:1852-1856` + `intaleq_3d_map.dart:228` | ضغط كبير على الجسر و `setData` مع كل تحديث GPS |
| L2 | **إعادة بناء الشاشة كاملة.** `BlocConsumer` بدون `buildWhen`، فأي emit بيعيد بناء الشاشة والويدجت | `map_view.dart:299` | بيكبّر مشكلة L1 و L3 |
| L3 | **الكاميرا بتقفز.** `easeTo(200ms)` مع كل fix وصل من GPS، وكل وحدة بتلغي اللي قبلها. ما في interpolation جوا JS | `intaleq_3d_map.dart:682` | حركة متقطعة، وتعليق مع الحركة الكثيرة |
| L4 | **ماركر السيارة DOM ثقيل.** فيه `filter: blur()` و `drop-shadow` مضاعف، و `transition`، وبيتعاد رسمه بكل فريم وقت حركة الكاميرا | الأسطر 437-462 | ضغط على الـ compositing بالـ WebView |
| L5 | **تحميل تايلز كثير.** zoom 18.8 مع pitch 68، و `maxPitch: 85`، و DEM `maxzoom: 15`، و `antialias: true`، والـ pixelRatio كامل | الأسطر 419-428، 495-501 | تايلز كثيرة للأفق، ذاكرة، و GPU |
| L6 | **ما في كاش.** JS والستايل والتايلز والـ DEM كلها من الشبكة، بدون أي كاش خاص فينا | — | تحميل بطيء، واستهلاك سيرفر |
| L7 | **onMapCreated بينادى مرتين** (مرة من `onPageFinished` ومرة من `mapLoaded`)، وفي `setState` بدون فحص `mounted` | الأسطر 287-336 | سلوك غير متوقع، وأوامر بتنبعث قبل ما الخريطة تجهز |
| L8 | **الحالة بتنحقن بالـ HTML كنص.** الـ HTML بيتولّد كـ string، وأي تغيير بيحتاج تحميل الصفحة من جديد. وفي متغير `currentBearing` عام مش معرّف | الأسطر 359-845 و 791 | صعوبة صيانة، وأخطاء صامتة |

### مخاطر ترخيص لازم ننتبهلها (للعلم، مش للتنفيذ هون)
- `server.arcgisonline.com` (Esri World Imagery) موجود بالستايل. استخدامه التجاري بده حساب وشروط Esri.
- الخطوط من `cdn.protomaps.com`. هاي اعتمادية خارجية.

---

## 2. القرار المعماري

- **حزمة جديدة جوا الـ workspace:** `packages/siro_map_engine/siro_gl_terrain/`.
  هيك `siro_gl` الأساسية ما بتعتمد على `webview_flutter`، واللي بده 3D بيضيف الحزمة هاي.
- **الرسم على Android وiOS:** WebView فيها maplibre-gl-js **مدمجة كـ asset محلي**، مش من unpkg.
- **الرسم على Flutter Web:** مباشرة عن طريق `siro_gl_web` / maplibre-gl-js، بدون WebView (مهمة T9).
- **الجسر:** قناة أوامر وحدة مكتوبة بأنواع واضحة (typed)، فيها batching و coalescing.
- **الحركة:** الـ interpolation للكاميرا والسيارة بيصير **جوا JS بـ requestAnimationFrame**. Dart بيبعث نقاط GPS بس.
- **الكاش:** `maplibregl.addProtocol('siro', ...)` + IndexedDB مع LRU للتايلز والـ DEM.
- **التوافق:** الـ API العامة بتغطي كل دوال `Intaleq3DController` الحالية بنفس الأسماء، عشان الترحيل بالمرحلة 8 يكون تبديل مباشر.
- **لاحقًا (المرحلة 7):** إذا المحرك الأصلي دعم terrain، بنبدّل طبقة الرسم بدون ما نغيّر الـ API.

---

## 3. المهام

### T0: تحقق وقياس (بدون كود إنتاجي)
**الهدف:** نحسم الحقائق قبل ما نبني.
1. اقرأ CHANGELOG لـ maplibre-native Android `13.5.0` و iOS `6.28.0` وما بعدهم: هل في دعم `terrain` / `raster-dem` 3D على الموبايل؟ سجّل النتيجة مع رابط المصدر.
2. حدد آخر إصدار مستقر من maplibre-gl-js (4.x أو 5.x)، وقارن تغييرات terrain والأداء مع 4.7.1. واختار إصدار نثبّته.
3. اعمل صفحة قياس بمثال `maplibre_gl_example` (أو مجلد مؤقت جوا الـ workspace) بتنسخ سلوك `Intaleq3DMap` الحالي كما هو، وفيها عداد FPS بـ JS (requestAnimationFrame) بيبعث متوسط كل ثانية لـ Dart.
4. سيناريو قياس ثابت: محاكاة قيادة على مسار بعمّان (ملف GeoJSON ثابت بـ `test/fixtures/amman_route.geojson`)، نقطة GPS كل ثانية لمدة 3 دقائق، مع rebuild للويدجت مع كل نقطة (هيك بيحاكي L1 و L2).
5. سجّل: متوسط FPS، أقل FPS، عدد الفريمات اللي أبطأ من 50ms، الذاكرة، وحجم البيانات المنزّلة.

**الملف الناتج:** `siro_gl_terrain/BENCHMARK.md` فيه جدول "قبل".
**شرط القبول:** أرقام موثّقة على جهاز Android متوسط وجهاز iPhone.

### T1: هيكل الحزمة
1. أنشئ `siro_gl_terrain/` (pubspec، lib، test، example أو صفحة بمثال الـ workspace)، وضيفها لـ `workspace:` بـ `packages/siro_map_engine/pubspec.yaml`.
2. الاعتماديات: `webview_flutter` و `webview_flutter_android` و `webview_flutter_wkwebview`، و `siro_gl_platform_interface` عشان نوع `LatLng`.
3. الهيكل:
```
lib/
  siro_gl_terrain.dart            // exports
  src/siro_terrain_map.dart       // الويدجت
  src/siro_terrain_controller.dart
  src/bridge/commands.dart        // أنواع الأوامر (sealed classes)
  src/bridge/events.dart          // أنواع الأحداث
  src/bridge/bridge.dart          // الطابور والإرسال
  src/options.dart                // SiroTerrainOptions
assets/web/
  index.html
  siro_terrain.js                 // منطقنا
  vendor/maplibre-gl.js|.css      // نسخة مثبتة + LICENSE
```
**شرط القبول:** الحزمة بتعمل build، وصفحة المثال بتفتح شاشة فاضية بدون أخطاء.

### T2: الأصول المحلية وفصل HTML عن Dart (يحل L8 وجزء من L6)
1. نزّل maplibre-gl-js بالإصدار اللي اخترناه بـ T0 لـ `assets/web/vendor/`، مع `LICENSE.txt` و `VERSION`.
2. انقل الـ HTML والـ JS من `_generateEngineHtml` لملفات حقيقية. **ممنوع string interpolation** للحالة.
3. الإعدادات الأولية بتنبعث كأمر `init` بعد ما الصفحة تجهز: center، zoom، pitch، bearing، styleUrl، demUrl، exaggeration، إلخ.
4. التحميل: `loadFlutterAsset('packages/siro_gl_terrain/assets/web/index.html')`. لازم تتأكد إنه بيشتغل على Android وiOS، وإذا لا، وثّق البديل.
5. صحّح `currentBearing` العام، واستخدم `'use strict'`.

**شرط القبول:** الخريطة 3D بتشتغل مع **الإنترنت مقطوع** بالنسبة لـ JS و CSS (التايلز ممكن تفشل)، وما في طلب لـ unpkg.

### T3: الجسر المكتوب (يحل L7)
1. **Dart → JS:** دالة وحدة `window.siro.exec(batchJson)`. الـ batch هو مصفوفة أوامر `{t: 'setRoute', ...}`.
2. **طابور Dart:**
   - الأوامر قبل `ready` بتتخزّن وبتنبعث مرة وحدة بعد ما يوصل `ready`.
   - **coalescing:** أوامر الكاميرا والموقع من نفس النوع بنفس الفريم، بيضل منها الأحدث بس.
   - الإرسال بيصير مرة وحدة لكل فريم Flutter (`SchedulerBinding.addPostFrameCallback`).
3. **JS → Dart:** `SiroBridge.postMessage(json)` بأحداث مكتوبة: `ready`، `tap`، `longPress`، `cameraIdle`، `elevation`، `fps`، `error`.
4. `onMapCreated` بينادى **مرة وحدة** بس، بعد `ready`. وكل `setState` محمي بـ `mounted`.
5. `dispose`: بيوقف الأنيميشن جوا JS (`siro.exec([{t:'destroy'}])`)، وبيفرّغ الطابور.
6. اختبارات وحدة للطابور: coalescing، التخزين قبل ready، والترتيب.

**شرط القبول:** الاختبارات ناجحة. وبالمثال، 100 أمر موقع بثانية وحدة بيوصلوا لـ JS كحد أقصى ~60 batch.

### T4: الحركة السلسة جوا JS (يحل L3)
1. أمر `updateLocation {lng, lat, heading, speed, ts}` بيخزّن هدف بس، ما بيحرّك الكاميرا مباشرة.
2. حلقة `requestAnimationFrame` وحدة جوا JS:
   - interpolation للموقع بين آخر نقطتين حسب الوقت، مع تنبؤ خفيف (dead reckoning) حتى 1.2 ثانية حسب السرعة والاتجاه.
   - تنعيم الزاوية (نفس فكرة `smoothAngle` بس مربوطة بالوقت مش بالـ factor الثابت).
   - تحديث الكاميرا بـ `map.jumpTo` جوا الحلقة، **مش `easeTo`**.
   - أنماط كاميرا: `cockpit` و `chase` و `top`، بنفس قيم zoom و tilt و lookAhead الموجودة بـ `navigation_cubit.dart:675-720` (انسخ القيم وما تعدّل الملف).
3. الحلقة بتوقف لما ما في متابعة، أو لما المستخدم يلمس الخريطة (وبتبعث حدث `followInterrupted`)، أو لما التطبيق يروح للخلفية.
4. الدوران (orbit) يدخل بنفس الحلقة.

**شرط القبول:** بسيناريو T0، ما في قفزات مرئية بالكاميرا، ومتوسط FPS أعلى من "قبل".

### T5: ماركر خفيف وطبقات المسار (يحل L1 و L4)
1. استبدل ماركر DOM بـ **GeoJSON source + symbol layer**: صورة السيارة PNG بدقة @2x و @3x (نحوّل الـ SVG الحالي لصورة)، `icon-rotate` من خاصية heading، `icon-rotation-alignment: map`، `icon-pitch-alignment: map`.
   هالة التوهج بتصير `circle` layer بـ `circle-blur`، مش CSS filter.
2. ماركر الوجهة: symbol layer كمان.
3. المسار:
   - `setRoute` بيقبل نقاط + `routeId` أو hash. الـ controller ما بيبعث إذا الـ hash ما تغيّر (هيك المشكلة L1 بتنحل جوا المحرك نفسه، حتى لو التطبيق بيعيد البناء).
   - أمر `setRouteProgress(index)` بيلوّن الجزء اللي انقطع بلون رمادي، بدون ما نبعث المسار من جديد (`line-gradient` أو `line-trim-offset` إذا مدعوم بالإصدار).
4. الويدجت: `didUpdateWidget` بيقارن بالمحتوى (hash)، مش بالمرجع.

**شرط القبول:** بسيناريو T0 (rebuild مع كل نقطة) المسار بينبعث **مرة وحدة** بس، وما في عناصر DOM للماركرات.

### T6: ضبط الأداء والجودة (يحل L5)
خيارات بـ `SiroTerrainOptions` بقيم افتراضية مدروسة:
- `pixelRatio: min(devicePixelRatio, 2)`، و `antialias` بيكون false على أجهزة Android الضعيفة (نحددها بعدد أنوية المعالج أو الذاكرة عن طريق بارامتر بيبعثه Dart).
- `maxPitch` بيكون 72 بالملاحة و 85 بالاستوديو بس.
- DEM `maxzoom: 12`: بيانات SRTM أو Copernicus دقتها 30 متر، فما بتستفيد فعليًا فوق z12. **قيس الفرق بالشكل والأداء.**
- `fadeDuration: 0` بالملاحة، و `maxTileCacheSize` محدد، و `refreshExpiredTiles: false`.
- `exaggeration` بيتغير حسب الـ zoom (expression)، مثلًا 1.0 بالشوارع و 2.0 بالجبال، بدل 2.0 ثابت بكل مكان.
- `setRenderQuality(low|medium|high)` كأمر واحد بيجمع كل الخيارات فوق.
- **WebView Android:** جرّب hybrid composition مقابل texture layer، وسجّل الفرق بـ BENCHMARK. استخدم الأفضل كافتراضي.

**شرط القبول:** جدول "بعد T6" بـ BENCHMARK.md. الهدف: متوسط FPS ≥ 50 على الجهاز المتوسط، والفريمات اللي فوق 50ms أقل بـ 70% عن "قبل".

### T7: الكاش (يحل L6)
1. `maplibregl.addProtocol('siro', handler)`: كل مصادر الستايل (تايلز، DEM، sprites، glyphs) بيتحوّل مسارها لـ `siro://...` عن طريق `transformStyle` / `transformRequest`.
2. الـ handler: بيدوّر بـ IndexedDB أول، وإذا ما لقي بيجيب من الشبكة وبيخزّن. فيه LRU بحد أقصى قابل للضبط (افتراضي 200MB)، ومدة صلاحية حسب نوع المورد (DEM والخطوط: سنة، التايلز: حسب الإصدار بالمسار).
3. أوامر: `cacheStats`، `clearCache`، و `prefetch(bbox, minZ, maxZ)` لتنزيل منطقة مسبقًا.
4. **إذا IndexedDB ما اشتغل** بالـ WebView مع `loadFlutterAsset` (origin `file://`): البديل خادم HTTP محلي داخل التطبيق باستخدام `shelf` على `127.0.0.1` بيخدم الأصول وبيعمل proxy مع كاش على القرص. **هاد بده موافقة قبل التنفيذ** (قاعدة 4).
5. وثّق إعداد DEM خاص فينا (للسيرفر لاحقًا): تايلز terrarium أو terrain-rgb بصيغة WebP من Copernicus GLO-30 لمنطقة التغطية. المحرك بياخذ `demTileUrl` كإعداد، والافتراضي AWS لحد ما سيرفرنا يجهز.

**شرط القبول:** نفتح منطقة، نعيد تشغيل التطبيق بدون إنترنت، وتظهر بالـ 3D كاملة. والفتح الثاني ما بيعمل أي طلب شبكة للتايلز المخزّنة.

### T8: اكتمال الـ API والاستوديو
1. `SiroTerrainController` بيغطي كل دوال `Intaleq3DController`:
   `updateUserLocation`، `setRoute`، `clearRoute`، `setDestination`، `setTerrainExaggeration`، `setPitch`، `setBearing`، `flyTo`، `startOrbit`، `stopOrbit`، `setSunLighting`، `toggleContours`، `toggleBuildings`، `setStyle`.
2. إضافات: `setCameraMode`، `setRouteProgress`، `setRenderQuality`، `pause()` و `resume()`، `queryElevation(LatLng)`، `cacheStats()`، `prefetch()`.
3. `setStyle` بيرجّع terrain والطبقات المخصصة تلقائيًا بعد `style.load` (إصلاح للسلوك الحالي اللي بيستخدم exaggeration قديمة).
4. شاشة مثال "استوديو" بتشبه `siro_3d_terrain_studio_screen.dart` (نسخ للمثال بس) لتجربة كل الدوال.
5. `MIGRATION.md`: جدول بيربط كل دالة قديمة بالجديدة، للمرحلة 8.

**شرط القبول:** كل دالة إلها زر بالمثال واختبار وحدة على مستوى الأمر اللي بيطلع منها.

### T9: Flutter Web بدون WebView (اختيارية)
- على `kIsWeb`، `SiroTerrainMap` بيستخدم maplibre-gl-js مباشرة (عن طريق `siro_gl_web` أو `HtmlElementView`)، مع نفس ملف `siro_terrain.js` ونفس الأوامر.

**شرط القبول:** نفس صفحة المثال شغّالة على Chrome.

### T10: الاختبارات والتوثيق النهائي
- Integration test: فتح، init، 30 ثانية من سيناريو القيادة، التأكد إنه ما في `error` events، وإنه FPS المرسل أعلى من حد معيّن.
- `README.md` للحزمة: التثبيت، المثال، الخيارات، والقيود (WebView، الحاجة لـ WebGL2).
- تحديث `BENCHMARK.md` بالأرقام النهائية مقابل "قبل".

---

## 4. ترتيب التنفيذ والتقدير

| المهمة | تعتمد على | الصعوبة |
|---|---|---|
| T0 | — | سهلة/متوسطة |
| T1 | — | سهلة |
| T2 | T1 | متوسطة |
| T3 | T2 | متوسطة/صعبة |
| T4 | T3 | صعبة |
| T5 | T3 | متوسطة |
| T6 | T4، T5 | صعبة (قياس على أجهزة) |
| T7 | T3 | صعبة |
| T8 | T4، T5 | متوسطة |
| T9 | T8 | متوسطة |
| T10 | الكل | سهلة |

---

## 5. توصية النموذج

| المهام | النموذج | الـ effort |
|---|---|---|
| T1، T2، T10، وتوثيق T8 | Haiku | medium |
| T0، T5، T8 | Sonnet | medium |
| T3، T4، T6، T7 | Sonnet (أو Opus إذا علِق) | high |
