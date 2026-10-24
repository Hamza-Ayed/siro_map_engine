# الخطة التنفيذية الكاملة لمحرك سيرو (Siro GL)

> **هاد الملف هو المرجع الوحيد للتنفيذ.** الملفات التانية ملاحق:
> - [PROGRESS.md](PROGRESS.md): سجل التقدم والقرارات والعوائق. **المنفّذ بيحدّثه بعد كل مهمة.**
> - [SIRO_3D_PLAN.md](SIRO_3D_PLAN.md): تفاصيل المرحلة 5 (الـ 3D).
> - [EXECUTOR_PROMPT.md](EXECUTOR_PROMPT.md): النص اللي بينعطى للمنفّذ ببداية كل جلسة.
> - [SIRO_ROADMAP.md](SIRO_ROADMAP.md): نظرة عامة مختصرة (للبشر).

---

## 0. الهدف النهائي

محرك خرائط **بهوية سيرو بالكامل** (الاسم، الحزم، القنوات، الوثائق، والملفات الثنائية بالمرحلة 7)، وبيتفوّق على الأصل بأرقام مقاسة في:
1. **الكاش:** الخريطة اللي انفتحت مرة بتفتح بعدها بدون سيرفر.
2. **السرعة:** زمن أول رسم والـ FPS.
3. **جودة الرسم:** العربي والستايلات والتايلز.
4. **الـ 3D:** تضاريس ومباني وكاميرا ملاحة سلسة.
5. **المحرك الأصلي C++:** نسخة مبنية من المصدر، باسمنا، فيها تحسيناتنا.

**نقطة البداية (مثبتة):** `flutter-maplibre-gl 0.27.1`، Android `org.maplibre.gl:android-sdk-opengl:13.5.0`، iOS `MapLibre 6.28.0`، Web `maplibre-gl-js 6.4.1` (`kMapLibreJsVersion`).
**البيئة المحلية:** Mac M3 بذاكرة 8GB، Flutter، Xcode 27.1، NDK `28.2` و `29.0`، cmake. **ما في** ninja ولا bazel ولا melos عالمي.

---

## 1. القواعد الإلزامية (أي مخالفة = توقف)

### 1.1 النطاق
- **مسموح التعديل:** `packages/siro_map_engine/**` بس، ومستودع `siro-native` بالمرحلة 7.
- **ممنوع التعديل:** `apps/**`، `packages/flutter-sdk/**`، `packages/android-kotlin-sdk/**`، `packages/ios-swift-sdk/**`، `packages/js-sdk/**`، `packages/tactical_app/**`. هدول **للقراءة فقط**.
- ممنوع أي إشي بيلمس السيرفر (ssh، deploy، رفع ملفات). اللي بيخص السيرفر بينكتب كوثيقة بـ `docs/server/`.
- ممنوع النشر (pub.dev، Maven عام، CocoaPods trunk، GitHub عام). المرحلة 8 بتصير بس بطلب صريح من صاحب المشروع.

### 1.2 Git
- المستودع الرئيسي فيه تعديلات كثيرة مش إلنا. **ممنوع** `git add -A` و `git add .` و `git stash` و `git reset --hard` و `git checkout -- <ملف برا النطاق>` و `git clean`.
- الفرع: `siro-engine/dev`. إذا مش موجود: `git switch -c siro-engine/dev` من HEAD الحالي.
- الإضافة بتصير **دائمًا** بـ: `git add -- packages/siro_map_engine`.
- commit لكل مهمة: `feat(siro-gl): <TASK-ID> <وصف قصير>`، أو `fix` / `perf` / `docs` / `test` / `chore` حسب الحالة.
- ممنوع `git push` إلا بطلب صريح.

### 1.3 الجودة (Definition of Done لكل مهمة)
مهمة ما بتنعلّم ✅ إلا إذا تحقق كل التالي:
1. شرط القبول المكتوب بالمهمة متحقق، **مع دليل** (مخرجات أمر، رقم، مسار صورة) مسجّل بـ PROGRESS.md.
2. أمر التحليل نظيف (الأمر الدقيق مسجّل بـ PROGRESS.md › الأوامر).
3. الاختبارات ناجحة: الموجودة كلها + اختبارات جديدة لكل كود جديد.
4. `dart format` بدون تغييرات.
5. المثال بيعمل build على Android على الأقل. وiOS للمهام اللي بتلمس Swift أو iOS.
6. إذا المهمة بتلمس API عامة: `CHANGELOG.md` محدّث تحت `## Unreleased`.
7. PROGRESS.md محدّث، وفي commit.

### 1.4 السلوك عند الشك
- إذا الخطة بتفترض إشي **وطلع مش صحيح** بالكود أو بالتوثيق الرسمي: سجّله بـ PROGRESS.md › العوائق، واقترح بديل، و**وقّف** إذا البديل بيغيّر النطاق.
- **ممنوع** تعطيل اختبار أو تحليل عشان تمرّر مهمة. ممنوع `// ignore:` بدون سبب مكتوب جنبه.
- **ممنوع** تعلن إنه إشي اتحسّن بدون قياس قبل وبعد.
- أي مكتبة جديدة بتحتاج قرار مسجّل بـ PROGRESS.md › القرارات. المسموح مسبقًا: `webview_flutter*`، `shelf` (بس بالمهمة D-T7 بعد موافقة)، و `pmtiles` JS.
- الأرقام اللي بتحتاج جهاز حقيقي: المنفّذ بيجهّز الأداة والسيناريو، وبيقيس على المحاكي ويعلّمه "محاكي". القياس على الجهاز الحقيقي بيتعلّم ⏳ بانتظار صاحب المشروع.

### 1.5 الترخيص (غير قابل للتفاوض)
- كل الكود الأصلي ترخيصه BSD-2 / BSD-3. **ممنوع حذف أي إشعار حقوق قديم.** بننقله لـ `NOTICE` / `THIRD_PARTY_LICENSES` كما هو.
- ممنوع استخدام اسم "MapLibre" أو "Mapbox" بالترويج أو بأسماء المنتجات. ذكرهم بالتراخيص والإشادة (attribution) مسموح ومطلوب.
- بيانات OpenStreetMap لازم يضل معها attribution "© OpenStreetMap contributors".
- ملفات جديدة كاملة نكتبها إحنا بيكون عليها header حقوق سيرو. الملفات المعدّلة من الأصل بيضل عليها header الأصلي (إذا موجود)، ومنضيف تحته سطر حقوقنا.

---

## 2. الهوية (جدول التسميات المعتمد)

| الأصل | سيرو |
|---|---|
| مجلد `maplibre_gl/` | `siro_gl/` |
| مجلد `maplibre_gl_platform_interface/` | `siro_gl_platform_interface/` |
| مجلد `maplibre_gl_web/` | `siro_gl_web/` |
| مجلد `maplibre_gl_example/` | `siro_gl_example/` |
| حزمة `scripts` (`maplibre_code_gen`) | `siro_gl_codegen` |
| workspace `maplibre_gl_workspace` | `siro_gl_workspace` |
| `MapLibreMap` | `SiroMap` |
| `MapLibreMapController` | `SiroMapController` |
| `MapLibreMapOptions` | `SiroMapOptions` |
| `MapLibrePlatform` | `SiroGlPlatform` |
| `MapLibreMethodChannel` | `SiroMethodChannel` |
| `MapLibreGlobalPlatform` / `...MethodChannel` / `...Web` | `SiroGlobalPlatform` / `...MethodChannel` / `...Web` |
| `MapLibreStyles` | `SiroStyles` |
| `MapLibreJsSource` / `MapLibreJsLoader` / `MapLibreJsLoaderException` | `SiroJsSource` / `SiroJsLoader` / `SiroJsLoaderException` |
| `MapLibreMapJsImpl` | تسمية داخلية، بتضل كما هي أو بتصير `JsMapImpl` (مش عامة) |
| قناة `plugins.flutter.io/maplibre_gl` | `com.siro.gl/global` |
| قناة `plugins.flutter.io/maplibre_gl_<id>` | `com.siro.gl/map_<id>` |
| Android `org.maplibre.maplibregl` | `com.siro.gl` |
| Android example `org.maplibre.example` | `com.siro.gl.example` |
| iOS pod / module `maplibre_gl` | `siro_gl` |
| أصناف Java/Swift `MapLibreMapController` إلخ | `SiroMapController` إلخ |
| صاحب الحقوق | **قيمة من PROGRESS.md › القرارات › D-001** |

**ما بيتغيّر لحد المرحلة 7:** اعتماديات المحرك الأصلي (`org.maplibre.gl:*`، pod `MapLibre`، npm `maplibre-gl`)، وأسماء أصناف المحرك الأصلي اللي بنستدعيها (`MLNMapView`، `org.maplibre.android.*`).
**الأسماء العامة القديمة:** ما في typedefs توافقية (الحزمة ما انتشرت). الترحيل بيصير بالمرحلة 8 عبر `MIGRATION.md`.

---

## 3. سير العمل لكل مهمة (إلزامي)

1. اقرأ PROGRESS.md وتأكد إنه المهام السابقة المطلوبة ✅.
2. علّم المهمة 🔄 بـ PROGRESS.md.
3. **استكشف قبل ما تكتب:** اقرأ الملفات المذكورة، ودوّر على كل الاستخدامات (`grep -rn`). إذا الواقع مختلف عن الخطة، اتبع 1.4.
4. نفّذ بأصغر تغييرات ممكنة، بنفس أسلوب الكود المحيط.
5. اكتب الاختبارات.
6. شغّل بوابات الجودة (1.3).
7. **راجع الـ diff تبعك بنفسك:** `git diff -- packages/siro_map_engine`. دوّر على كود ميت، أسماء قديمة، أسرار، وملفات build دخلت بالغلط.
8. حدّث PROGRESS.md (الحالة، الدليل، الملاحظات، وأي قرارات).
9. اعمل commit.
10. اكتب تقرير مختصر: شو اتعمل، شو اتقاس، شو ما اتحقق، والمهمة الجاية.

---

## 4. المراحل والمهام

> الرمز `[S/m]` معناه Sonnet بـ effort medium، و `[S/h]` معناه Sonnet بـ effort high، و `[O/h]` معناه Opus بـ effort high (أو Sonnet/high مع مراجعة).

### المرحلة F: الأساس وخط القياس

**F-01 تجهيز البيئة** `[S/m]`
- اعمل فرع `siro-engine/dev`.
- بـ `packages/siro_map_engine`: `flutter pub get`، وبعدها اكتشف الطريقة الصحيحة لتشغيل melos 7 مع pub workspaces (`dart run melos ...` أو `dart pub global activate melos`). **سجّل الأوامر الدقيقة** بـ PROGRESS.md › الأوامر: bootstrap، analyze، test:io، test:web، format، generate.
- شغّل الكل وسجّل النتيجة كما هي. إذا في فشل أصلًا، سجّله كخط أساس وما تصلّحه هون، إلا إذا كان مانع للبناء.
- **القبول:** جدول أوامر شغّال بـ PROGRESS.md، ونتيجة كل واحد.

**F-02 بناء وتشغيل المثال** `[S/m]`
- `flutter build apk --debug` و `flutter build ios --simulator --debug` للمثال. شغّله على محاكي iOS وAndroid emulator (إذا متاح)، وخذ لقطة شاشة لصفحة الخريطة الرئيسية.
- **القبول:** مسارات اللقطات بـ `docs/evidence/F-02/`، والـ builds ناجحة.

**F-03 أداة القياس (Bench Harness)** `[S/h]`
- صفحة جديدة بالمثال: `lib/examples/bench_page.dart` (أو بنفس نمط تسجيل الصفحات الموجود بـ `main.dart` و `page.dart`).
- بتقيس:
  - **زمن أول رسم:** من `initState` لأول `onStyleLoaded`، ولأول `onMapIdle` / `onCameraIdle`.
  - **FPS:** بـ `SchedulerBinding.addTimings` للفريمات تبعت Flutter. وللرسم الأصلي، سجّل إنه بيحتاج hook بالمرحلة PF (ما تزوّر).
  - **السيناريو الثابت:** `assets/bench/amman_route.geojson` (مسار حقيقي حوالي 8 كم بعمّان، بتولّده بأداة أو بتكتب إحداثياته يدويًا من OSM)، تحريك الكاميرا عليه بنقطة كل 100ms لمدة 120 ثانية، مع pitch 60.
  - **الشبكة:** عدد وحجم الطلبات. على Android عبر `MapLibreCustomHttpInterceptor` (عدّاد)، وعلى iOS عبر `URLProtocol` أو الـ headers delegate الموجود. ميزة debug بس.
  - **الذاكرة:** `ProcessInfo.currentRss` من `dart:io`.
- النتائج بتطلع JSON على الشاشة ومنسوخة لـ clipboard، والمنفّذ بيلزقها بـ `BENCHMARK.md`.
- **القبول:** ثلاث تشغيلات على المحاكي، بمتوسط وانحراف، مسجّلة بـ `BENCHMARK.md` › "Baseline (simulator)". وصف الجهاز الحقيقي ⏳.

**F-04 خريطة الكود** `[S/m]`
- `docs/ARCHITECTURE.md`: الطبقات (Dart ← platform interface ← method channel ← Java/Kotlin/Swift ← المحرك الأصلي)، كل قناة وكل method name، مولّد الكود (`scripts/templates`)، وأين بيتعرّف كل إشي. جدول بكل `case "..."` بـ `GlobalMethodHandler.java` و `MapLibreMapController.java` ونظيرها بـ Swift.
- **القبول:** المستند بيغطي 100% من method names (اعمل grep وقارن العدد وسجّله).

### المرحلة ID: الهوية والترخيص

**ID-01 الترخيص والإشعارات (أول إشي، قبل أي إعادة تسمية)** `[S/m]`
- `NOTICE` بالجذر: محتوى كل ملفات LICENSE الحالية **حرفيًا** (الجذر + كل حزمة)، مع عنوان لكل قسم.
- `LICENSE` لكل حزمة: قسم حقوق سيرو (D-001) بـ BSD-3-Clause على تعديلاتنا، وبعده الفاصل (80 شَرطة) والإشعارات الأصلية كما هي. **انتبه:** `test/license_test.dart` بيفرض بنية معينة (فاصل 80 شرطة، بعده اسم، بعده سطر فاضي). خلّي البنية متوافقة مع الاختبار، وما تعدّل الاختبار إلا عشان يقبل القسم الجديد.
- `THIRD_PARTY_LICENSES.md`: جدول بالمكونات (maplibre-native، maplibre-gl-js، flutter-maplibre-gl، flutter-mapbox-gl، okhttp، play-services، pmtiles) مع ترخيص ورابط كل واحد.
- **القبول:** `license_test` ناجح، وكل الإشعارات القديمة موجودة (`diff` بين النصوص القديمة والقسم المقابل فاضي).

**ID-02 إعادة تسمية حزم Dart والمجلدات** `[S/h]`
- `git mv` للمجلدات حسب جدول القسم 2. حدّث `pubspec.yaml` بكل الحزم (name، dependencies، repository، homepage، issue_tracker، documentation، funding بيتشال، topics، screenshots descriptions)، و `workspace:` بالجذر، و `flutter_maplibre_gl.code-workspace` (بيصير `siro_gl.code-workspace`).
- كل `import 'package:maplibre_gl...` بيتحدّث.
- `flutter: plugin: platforms:` (pluginClass، package، fileName) لازم يتطابق مع ID-04 و ID-05. **نفّذ ID-02 و ID-03 و ID-04 و ID-05 على التوالي بنفس الجلسة** إذا البناء بيتكسّر بينهم، وعلّمهم سوا.
- **القبول:** `flutter pub get` بالجذر ناجح، والتحليل نظيف.

**ID-03 إعادة تسمية الواجهات العامة بـ Dart** `[S/h]`
- طبّق جدول القسم 2 على الأصناف والملفات (`maplibre_map.dart` بيصير `siro_map.dart`، `maplibre_styles.dart` بيصير `siro_styles.dart`، إلخ). الأصناف الخاصة كمان، إذا اسمها فيه MapLibre بدون ما يكون من المحرك الأصلي.
- القنوات: ثبّت أسماء القنوات كـ ثوابت بملف واحد `siro_gl_platform_interface/lib/src/channels.dart`، واستخدمها بكل مكان.
- **ممنوع:** تغيير أسماء خصائص الستايل (`line-color` إلخ)، أو أسماء أحداث JS تبعت maplibre-gl-js.
- **القبول:** `grep -rniE "maplibre" --include=*.dart siro_gl*/lib` ما بيطلع غير مراجع لـ maplibre-gl-js بـ `siro_gl_web` (interop مع `maplibregl` global)، وكل وحدة موثّقة بتعليق بنفس السطر أو قائمة بـ PROGRESS.md.

**ID-04 Android** `[S/h]`
- `git mv` لـ `org/maplibre/maplibregl` بيصير `com/siro/gl`، و `package` بكل ملف، و `group` و `namespace`، و `MapLibreMapsPlugin` بيصير `SiroGlPlugin`، وباقي الأصناف حسب الجدول. أسماء القنوات بنفس قيم `channels.dart`.
- المثال: `namespace` و `applicationId` بيصيروا `com.siro.gl.example`، ومسار `MainActivity`.
- قوالب المولّد `LayerPropertyConverter.java.template`.
- **القبول:** `flutter build apk --debug` للمثال ناجح، والخريطة بتفتح على المحاكي، وكل صفحات المثال (عيّنة: 5 صفحات منهم annotations و offline و layers) بتشتغل.

**ID-05 iOS** `[S/h]`
- `maplibre_gl.podspec` بيصير `siro_gl.podspec` (name، summary، homepage، author من D-001)، `Package.swift` (اسم الحزمة والمنتج والـ target؛ اعتمادية `maplibre-gl-native-distribution` بتضل)، ومسار `Sources/siro_gl`، والأصناف Swift حسب الجدول، والقنوات.
- قالب `LayerPropertyConverter.swift.template`.
- المثال: `Podfile` و bundle id `com.siro.gl.example`.
- **القبول:** `flutter build ios --simulator --debug` ناجح، والخريطة بتفتح على محاكي iOS.

**ID-06 Web** `[S/m]`
- registrar والـ view type، وأسماء الأصناف. `js_loader`: الـ CDN بيضل لحد PF-05، بس بيصير قابل للضبط.
- **القبول:** `flutter build web` للمثال ناجح، والخريطة بتفتح بـ Chrome، و `test:web` ناجح.

**ID-07 المولّد والتحقق من الستايل** `[S/m]`
- `siro_gl_codegen` بيولّد للمسارات والأسماء الجديدة. شغّل `generate` وتأكد إنه **ما في diff** (بعد إعادة التسمية، المخرجات لازم تطابق المولّد).
- **القبول:** generate بعدها `git status` نظيف، و `check-style-spec` ناجح.

**ID-08 الوثائق والهوية** `[S/m]`
- `README.md` جديد بالعربي والإنجليزي، `CONTRIBUTING.md`، `SECURITY.md` (بدل `SECURITY_POLICY.txt`)، `CODE_OF_CONDUCT.md`، `RELEASE.md`، `CHANGELOG.md` بيبلّش بـ `## 1.0.0-dev` مع سطر "Based on flutter-maplibre-gl 0.27.1"، وبتنحذف أو بتتعدّل `website/` (قرار D-002).
- attribution الافتراضي بالخريطة: "© Siro · © OpenStreetMap contributors". خيار `attributionButtonPosition` الموجود بيضل.
- **القبول:** `grep -rniE "maplibre" --exclude-dir={build,.dart_tool} . | grep -viE "license|notice|third_party|maplibre-gl-js|org\.maplibre\.gl|MapLibre'|MLN|maplibregl"` بيرجع قائمة فاضية، أو استثناءات موثّقة.

### المرحلة C: الكاش والعمل بدون إنترنت

> **موجود أصلًا (ما تكرره):** `installOfflineMapTiles`، `setOffline`، `mergeOfflineRegions`، `getOfflineDatabasePath`، `exportOfflineDatabase`، `setOfflineTileCountLimit`، `setHttpHeaders`، `downloadOfflineRegion`، `clearAmbientCache`، `resetOfflineDatabase`، `pause/resumeOfflineRegionDownload`، `getOfflineRegionStatus`، `setOfflineMaxConcurrentRequests`، `preWarm`.

**C-01 حجم الكاش وإدارته** `[S/m]`
- API: `SiroCache.setMaximumAmbientCacheSize(int bytes)`، `invalidateAmbientCache()`، `packDatabase()`.
  - Android: `OfflineManager.setMaximumAmbientCacheSize(long, ResultCallback)`، `invalidateAmbientCache`، `packDatabase`.
  - iOS: `MLNOfflineStorage.shared.setMaximumAmbientCacheSize(_:withCompletionHandler:)`، `invalidateAmbientCache`، و pack (تحقق من الاسم بالـ headers).
  - Web: no-op موثّق (الكاش تابع C-05).
- **تحقق قبل التنفيذ** إنه كل دالة موجودة بإصدار الـ SDK المثبت (افتح الـ AAR / headers). اللي مش موجود بيتسجّل بالعوائق.
- **القبول:** اختبارات Dart للقناة (mock)، وزر بالمثال بيضبط الحجم لـ 300MB وبيرجع نجاح على Android وiOS.

**C-02 إحصاءات الكاش** `[S/m]`
- `SiroCache.stats()` بيرجع `{databasePath, databaseSizeBytes, maxAmbientBytes}` (حجم الملف من القرص). عدد التايلز إذا ممكن بدون ما نفتح SQLite بالتوازي مع المحرك. إذا مش آمن، ما بنضيفه.
- **القبول:** الرقم بيكبر بعد التصفح بالمثال، وبيصغر بعد `clearAmbientCache`.

**C-03 خريطة البذرة (Seed) المدمجة** `[S/h]`
- `SiroCache.seedFromAsset(String assetPath, {String? versionTag})`: بينسخ ملف `.db` (صيغة offline database تبعت المحرك) من الـ assets لملف مؤقت، وبينادي `mergeOfflineRegions`، وبيحفظ `versionTag` بـ SharedPreferences أو ملف صغير عشان ما يتكرر، وبيتجاهل إذا نفس الإصدار.
- **أداة توليد البذرة:** `tool/make_seed/README.md` بيشرح كيف نولّد offline db لمنطقة الأردن z0-10 عن طريق `downloadOfflineRegion` على المحاكي، وبعدها `exportOfflineDatabase`. وسكربت Dart بيشغّل الخطوات. **ما بنضيف ملفات كبيرة للمستودع:** البذرة التجريبية بالمثال حدها 5MB (مثلًا عمّان z10-13).
- **القبول:** مثال بإنترنت مقطوع من أول تشغيل بيعرض المنطقة المبذورة.

**C-04 سياسة الكاش والتنزيل الذكي** `[S/h]`
- `SiroCache.setOfflineMode(bool)` (غلاف واضح لـ `setOffline`)، و `prefetchAround(LatLng center, double radiusKm, {int minZoom, int maxZoom, bool wifiOnly})` بيبني bounds ويستدعي `downloadOfflineRegion` بـ metadata `{siro_auto: true}`، ومع حد أقصى لعدد المناطق التلقائية (بيحذف الأقدم).
- فحص wifi: بدون مكتبة جديدة. الفحص بيكون بـ native (ConnectivityManager / NWPathMonitor) جوا الـ plugin.
- **القبول:** اختبارات حساب الـ bounds، وبالمثال المنطقة بتنزل وبتظهر بقائمة المناطق مع الـ metadata.

**C-05 كاش الويب** `[S/h]`
- Service Worker اختياري: `siro_gl_web/assets/siro_sw.js` بيخزّن طلبات التايلز والـ glyphs والـ sprites بالـ Cache API (cache-first، LRU بالعدد). تفعيله بيكون بخطوة موثّقة بـ `index.html` تبع التطبيق.
- **القبول:** مثال الويب بعد reload بيعرض التايلز من `ServiceWorker` (تتحقق منه بـ DevTools أو بسكربت فحص).

**C-06 هيدرات الطلبات** `[S/m]`
- `setHttpHeaders` موجود. ضيف `SiroGl.setRequestHeadersProvider` بقيم ثابتة: `X-Siro-App`، `X-Siro-Version`، وعلى Android وiOS بيتحطوا بكل طلب. تحقق إنه `MapLibreCustomHttpInterceptor` (بعد التسمية) بيحترم ETag و 304 وما بيكسر الكاش (لا تضيف `Cache-Control: no-cache`).
- **القبول:** عداد الشبكة من F-03 بيبيّن إنه الهيدرات موجودة، وإنه الفتح الثاني ما عمل طلبات جديدة لنفس التايلز.

**C-07 وثيقة السيرفر** `[S/m]`
- `docs/server/CACHING.md`: مسارات تايلز فيها إصدار، `Cache-Control: public, max-age=31536000, immutable`، ETag، CDN، ضغط gzip/br للـ pbf، و CORS. **وثيقة بس.**

**C-08 قياس المرحلة** `[S/m]`
- F-03 قبل وبعد: بيانات الفتح الأول، الفتح الثاني، والفتح بدون إنترنت. حدّث BENCHMARK.md.

### المرحلة PF: السرعة على مستوى Flutter والجسر

**PF-01 أداة قياس الرسم الأصلي** `[S/h]`
- Android: `MapView.addOnDidFinishRenderingFrameListener` (فيه `RenderingStats` بالإصدارات الحديثة، تحقق منه) لعدّ الفريمات وزمنها. iOS: `mapViewDidFinishRenderingFrame(_:fullyRendered:)` (وأي frame stats متاحة).
- حدث `onRenderStats` (debug بس، اختياري)، وبيتغذّى منه F-03.
- **القبول:** FPS أصلي حقيقي بالـ bench، مش بس FPS تبع Flutter.

**PF-02 OpenGL مقابل Vulkan على Android** `[S/h]`
- خيار gradle `siroRenderer=opengl|vulkan` (من `gradle.properties` تبع التطبيق)، بيبدّل `android-sdk-opengl` بـ `android-sdk` مع منطق الـ exclusion الموجود.
- قِس الاثنين بـ bench. **ما تغيّر الافتراضي** إلا بقرار مسجّل D-xxx مبني على أرقام جهاز حقيقي.
- **القبول:** الخياران بيعملوا build وبيشتغلوا، والأرقام مسجلة.

**PF-03 عمليات مجمّعة (batch)** `[S/h]`
- اقرأ كيف `annotation_manager.dart` والـ controller بيبعثوا `symbols#add` و `line#add` إلخ. ضيف `controller.applyBatch(List<SiroOp>)`: قناة وحدة بتنفذ add/update/remove لمصادر وطبقات و features بنداء واحد، على Android وiOS وWeb.
- **القبول:** bench بـ 2000 رمز: زمن الإضافة قبل وبعد. الهدف تحسن 3 أضعاف أو أكثر، أو توثيق السبب إذا ما وصلنا.

**PF-04 تحديث GeoJSON بالفرق** `[S/h]`
- تحقق إذا المحرك الأصلي فيه `updateData` جزئي على GeoJSONSource بالإصدار المثبت (maplibre-gl-js فيه `updateData` بـ GeoJSONSourceDiff). إذا موجود: `setGeoJsonSourceDiff(sourceId, {add, update, remove})` بيعتمد على `promoteId`. إذا مش موجود على الموبايل: fallback بيحافظ على نسخة Dart وبيبعث الكامل، بس **بمعدل محدد** (throttle 1 لكل فريم).
- **القبول:** اختبار تحريك 300 سيارة بتحديث كل ثانية، مع FPS قبل وبعد.

**PF-05 أصول الويب المحلية** `[S/m]`
- `SiroJsSource.bundled()`: maplibre-gl-js (6.4.1، نفس الإصدار) و CSS كـ assets بـ `siro_gl_web`، مع LICENSE تبعها. الافتراضي بيصير bundled، والـ CDN خيار.
- **القبول:** مثال الويب بيشتغل بدون طلبات لـ unpkg.

**PF-06 Isolate للترميز الثقيل** `[S/m]`
- أي `jsonEncode` أو تحويل لـ GeoJSON أكبر من حد (مثلًا 200KB) بيصير بـ `Isolate.run`. قِس قبل وبعد. إذا الفرق أقل من 5%، سجّله وارجع عنه.

**PF-07 warmUp** `[S/m]`
- `preWarm` موجود. وثّقه، واربطه بتحميل الستايل مسبقًا للكاش عبر `SiroGl.warmUp(styleUrl)` (طلب مسبق للستايل والـ sprites والـ glyphs الأساسية).
- **القبول:** زمن أول رسم بعد warmUp أقل (مقاس).

**PF-08 قياس المرحلة.**

### المرحلة Q: جودة الرسم (ستايل وبيانات)

**Q-01 ستايلات سيرو** `[S/h]`
- `siro_gl/assets/styles/`: `siro-light.json`، `siro-dark.json`، `siro-nav.json`، `siro-hybrid.json`، مبنيين على مخطط (schema) التايلز تبعنا. **ارجع لـ** `packages/flutter-sdk/assets/style*.json` **للقراءة**، عشان تعرف أسماء الـ source-layers المستخدمة.
- كل ستايل بيمرّ على validator (`check-style-spec` أو `@maplibre/maplibre-gl-style-spec` gl-style-validate عبر npx). `SiroStyles.light` إلخ بيرجعوا مسار asset أو URL قابل للضبط.
- **القبول:** الأربعة صالحين، ولقطات لعمّان بـ `docs/evidence/Q-01/`.

**Q-02 العربي** `[S/h]`
- `text-field`: `coalesce(name:ar, name, name:en)`.
- خطوط glyphs عربية محلية: سكربت بـ `tool/glyphs/` بيولّد PBF من خط مفتوح الترخيص (Noto Naskh Arabic / Noto Sans Arabic، OFL) بأداة مفتوحة (`fontnik` / `build_pbf_glyphs`)، للنطاقات اللازمة بس (0-255، 1536-1791 العربي، 65024-65279 أشكال العرض، إلخ). ونحمّلهم عبر `asset://` أو بروتوكول محلي (تحقق إنه المحرك بيدعم `asset://` للـ glyphs على Android وiOS).
- **ضبط التصادم:** `symbol-sort-key` حسب الأهمية (rank/population)، `text-padding`، `text-variable-anchor`، `text-max-width` مناسب للعربي.
- **القبول:** لقطات قبل وبعد لعمّان وإربد بـ zoom 12 و 15 و 17، بدون حروف مقطّعة أو مربعات، وتحسّن مقاس بعدد الأسماء المعروضة بدون تداخل.

**Q-03 Sprites** `[S/m]`
- أيقونات SVG لسيرو بـ `tool/sprites/` (مصدر SVG، وتوليد @1x و @2x و @3x بأداة `spreet` أو مكافئ). الأيقونات المصممة بيقدمها صاحب المشروع، والمنفّذ بيجهّز pipeline بأيقونات مؤقتة من Material Symbols (Apache-2.0) مع الترخيص.

**Q-04 Pipeline التايلز (وثيقة + سكربت، بدون سيرفر)** `[S/h]`
- `tool/tiles/`: إعداد planetiler (Java، OpenMapTiles schema) أو tippecanoe للأردن (استخراج من Geofabrik). تبسيط حسب الـ zoom، حذف الحقول اللي ما بنستخدمها (نستخرجها من الستايلات بسكربت)، ومخرج PMTiles.
- **القبول:** بناء محلي لعمّان بس، مع جدول حجم التايلز قبل وبعد التنقية.

**Q-05 Hillshade وتدرّج الارتفاع** `[S/m]`
- طبقات `hillshade` و `color-relief` (إذا مدعومة بالإصدار، تحقق) بستايل `siro-terrain.json`، كإعداد للـ 3D.

**Q-06 قياس ومقارنة بصرية** `[S/m]`
- `docs/evidence/Q-06/`: نفس 5 مواقع (عمّان، إربد، العقبة، دمشق، المنامة) بنفس الكاميرا، قبل وبعد.

### المرحلة D: الـ 3D
**نفّذ [SIRO_3D_PLAN.md](SIRO_3D_PLAN.md) بالترتيب T0 → T10**، بمعرّفات `D-T0` … `D-T10`. ملاحظات ربط:
- الحزمة: `siro_gl_terrain/` بجانب `siro_gl/` (بعد المرحلة ID).
- maplibre-gl-js داخل الـ WebView: **نفس الإصدار المستخدم بـ `siro_gl_web` (6.4.1)**، إلا إذا T0 أثبت سبب لغيره. الكود الحالي بالتطبيق على 4.7.1، والفرق بالـ API لازم يتوثّق بـ T0.
- بعد المرحلة N، إذا المحرك الأصلي صار يدعم terrain: `siro_gl_terrain` بيصير عنده backend ثاني native بدون ما يتغير الـ API (مهمة N-08).

### المرحلة QA: الجودة المستمرة (بتمشي مع كل المراحل)

**QA-01 CI محلي** `[S/m]`: سكربت `tool/ci.sh` بيشغّل format و analyze و test:io و test:web و generate-diff-check و build apk و build ios simulator، ومخرجه ملخص. **كل مهمة بتشغّله قبل الـ commit** (بعد ما يكون موجود).
**QA-02 اختبارات تكامل** `[S/h]`: `siro_gl_example/integration_test/` (فتح خريطة، ستايل، كاميرا، annotations، كاش، offline) على Android وiOS.
**QA-03 Debug overlay** `[S/m]`: `SiroMap(debugOverlay: true)` بيعرض FPS، والتايلز المحمّلة، وحالة الكاش، وزمن آخر رسم.
**QA-04 التوثيق** `[S/m]`: `docs/api/` لكل واجهة جديدة، بالعربي والإنجليزي، مع مثال لكل وحدة.

### المرحلة N: المحرك الأصلي C++ (siro-native)

> مستودع منفصل، لأنه ضخم (حوالي 1-2GB مع submodules): `~/development/App/siro-native` (git مستقل). ما بينحط داخل map-saas.
> **تحذير موارد:** الجهاز فيه 8GB رام ومساحة فاضية حوالي 100GB. البناء بطيء. استخدم `-j4`، وسكّر التطبيقات الثقيلة. أي بناء أطول من دقيقتين بيشتغل بالخلفية.

**N-01 الاستنساخ والأدوات** `[S/h]`
- `git clone --recurse-submodules https://github.com/maplibre/maplibre-native ~/development/App/siro-native`، وبعدها checkout على الـ tags المطابقة: `android-v13.5.0` و `ios-v6.28.0` (تحقق من أسماء الـ tags الفعلية). **سجّل** الـ commits.
- الأدوات حسب `platform/android/README` و `platform/ios/README` بالمستودع: غالبًا `ninja` و `bazelisk` (عبر brew، **بموافقة** لأنها تثبيتات على الجهاز)، وJDK المطلوب، وNDK المطلوب.
- **القبول:** بيئة جاهزة، والأوامر مسجلة بـ PROGRESS.md.

**N-02 بناء Android من المصدر** `[O/h]`
- ابنِ AAR للـ OpenGL (والـ Vulkan إذا ممكن) حسب توثيق المستودع (`./gradlew :MapLibreAndroid:assemble...Release`، تحقق من اسم المهمة). وانشر محليًا: `publishToMavenLocal` بإحداثيات `com.siro.native:siro-native-android-opengl:13.5.0-siro.1`.
- `siro_gl/android/build.gradle`: خيار `siroNative=local` بيستخدم `mavenLocal()` والإحداثيات الجديدة، والافتراضي بيضل المحرك الأصلي من Maven Central.
- **القبول:** المثال بيشتغل على AAR مبني محليًا، والـ bench بيطلع نفس الأرقام تقريبًا (±5%). هاد بيثبت إنه البناء سليم.

**N-03 بناء iOS من المصدر** `[O/h]`
- XCFramework حسب توثيق المستودع (Bazel). مسار محلي، و`siro_gl.podspec` / `Package.swift` بيدعموا `SIRO_NATIVE_PATH` (متغير بيئة) للتبديل.
- **القبول:** نفس قبول N-02 على iOS.

**N-04 الهوية الثنائية** `[S/h]`
- اسم المكتبة والـ bundle id ومعلومات الإصدار و User-Agent الافتراضي (`SiroGL/<version>`). **ممنوع** إعادة تسمية الـ packages الداخلية (`org.maplibre.android.*`، `MLN*`) هلأ: كلفة صيانة عالية مع التحديثات. سجّل ذلك كقرار.
- **القبول:** User-Agent بالطلبات بيطلع `SiroGL`، وملف الترخيص مضمّن بالـ AAR والـ framework.

**N-05 مسار تحديث من الأصل** `[S/h]`
- فرع `siro/main` فوق tag أصلي، وتعديلاتنا commits صغيرة واضحة. `UPSTREAM_SYNC.md` بيشرح خطوات rebase على tag جديد، وكيف نحل التعارضات، واختبارات التحقق.
- **القبول:** تجربة rebase فعلية على tag أحدث بفرع مؤقت، والنتيجة موثقة.

**N-06 الكاش على مستوى المحرك** `[O/h]`
- ادرس `platform/default/src/mbgl/storage/offline_database.cpp` و `database_file_source.cpp`: سياسة الطرد (eviction) الحالية والحجم الافتراضي.
- تحسينات مقترحة (كل وحدة قرار مستقل وقياس):
  - (أ) حجم افتراضي أكبر قابل للضبط عند البناء.
  - (ب) أولوية بقاء لتايلز الـ zoom المنخفض (≤10) والـ glyphs والـ sprites، فما تنطرد قبل تايلز التفاصيل.
  - (ج) `max-stale`: استخدام النسخة المخزّنة المنتهية بدون انتظار الشبكة، وتحديثها بالخلفية (stale-while-revalidate) إذا مش موجود.
- **القبول:** اختبارات C++ للطرد (gtest موجود بالمستودع)، ومقاييس bench للفتح الثاني والوضع الضعيف للشبكة.

**N-07 العربي بالمحرك** `[O/h]`
- ادرس مسار التشكيل (`src/mbgl/text/`، `platform/*/src/.../bidi`، `i18n`). حدّد مشاكل حقيقية بلقطات (حروف مقطعة على الخطوط المنحنية، ترتيب أرقام، علامات التشكيل، fallback للخطوط).
- عالج **المشاكل المثبتة بس**، كل وحدة بـ commit واختبار render (render-tests بالمستودع، `metrics/`).
- **القبول:** render tests جديدة ناجحة، ولقطات قبل وبعد.

**N-08 التضاريس 3D على الموبايل** `[O/h]` (بحث، وبعدها قرار)
- تحقق من حالة دعم terrain بالمحرك الأصلي (issues، PRs، فروع). إذا موجود بإصدار أحدث: خطة ترقية. إذا مش موجود: تقدير تقني مكتوب (مكونات: DEM tile source موجود لـ hillshade، mesh، depth، تعديل الـ symbol placement، الكاميرا) بأسابيع العمل. **وقّف هون** لقرار صاحب المشروع (D-xxx) قبل أي تنفيذ.
- **القبول:** `docs/native/TERRAIN_FEASIBILITY.md`.

**N-09 تقليل الحجم** `[S/h]`
- قِس حجم الـ AAR والـ framework لكل ABI. جرّب تعطيل ميزات ما بنستخدمها عبر خيارات البناء الموجودة (مثل الـ location component إذا ما بنحتاجه، أو ABI معين). قبل وبعد.

**N-10 قياس المرحلة.**

### المرحلة R: الجاهزية للإصدار (بدون نشر)

**R-01** `MIGRATION.md`: من `maplibre_gl` / `Intaleq*` لـ `siro_gl` / `siro_gl_terrain`، بجدول دوال كامل (بيشمل دوال `packages/flutter-sdk` اللي التطبيقات بتستخدمها: اقرأها وما تعدّلها).
**R-02** مراجعة ترخيص نهائية (سكربت بيتأكد إنه كل NOTICE موجود بالـ AAR والـ framework والـ pub package).
**R-03** نسخة `1.0.0-rc.1` بـ CHANGELOG، و tag محلي `siro-gl-v1.0.0-rc.1` (بدون push).
**R-04** تقرير نهائي: BENCHMARK كامل مقابل الأصل، وقائمة الميزات، والقيود المعروفة.

> **المرحلة 8 (ربط التطبيقات والنشر) برا نطاق المنفّذ.** بتبلّش بس بطلب صريح من صاحب المشروع.

---

## 5. الترتيب والاعتماديات

```
F-01 → F-02 → F-03 → F-04
  → ID-01 → (ID-02..ID-05 سوا) → ID-06 → ID-07 → ID-08 → QA-01
  → C-01 → C-02 → C-03 → C-04 → C-05 → C-06 → C-07 → C-08
  → PF-01 → PF-02 … PF-08
  → Q-01 → Q-02 → Q-03 → Q-04 → Q-05 → Q-06
  → D-T0 … D-T10            (QA-02/03/04 بتمشي بالتوازي بعد ID)
  → N-01 → N-02 → N-03 → N-04 → N-05 → N-06 → N-07 → N-08(قرار) → N-09 → N-10
  → R-01 … R-04
```
ممكن نقدّم المرحلة D قبل Q إذا صاحب المشروع طلب (قرار بـ PROGRESS.md).

## 6. النماذج والـ effort
- الافتراضي **Sonnet / medium**.
- `[S/h]` لأي مهمة فيها native (Java/Kotlin/Swift)، أو جسر، أو أداء، أو كاش.
- `[O/h]` لمهام C++ (N-02، N-03، N-06، N-07، N-08). إذا استخدمت Sonnet، لازم مراجعة من Opus قبل ✅.
- Haiku ممكن بس للتوثيق (ID-08، C-07، QA-04، R-01).
