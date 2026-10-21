# سجل تقدم محرك سيرو

> المنفّذ بيحدّث هاد الملف **بكل مهمة** (القسم 3 بـ [SIRO_MASTER_PLAN.md](SIRO_MASTER_PLAN.md)).
> الحالات: ⬜ لسا · 🔄 شغّال · ✅ خلص · ⏳ بانتظار صاحب المشروع (جهاز حقيقي أو قرار) · ⛔ عائق

## الحالة الحالية
- **آخر مهمة مكتملة:** QA-01 و ID-08 (المرحلة ID كاملة)
- **المهمة الجاية:** QA-02 (اختبارات تكامل) أو قرار صاحب المشروع على المرحلة 8 / D-002 / عنوان الأمان
- **الفرع:** `siro-engine/dev` (انعمل من `main` عند `25423ba`، مستودع `packages/siro_map_engine` مستقل git)

## الأوامر المعتمدة (F-01، 2026-10-21، جهاز M3 / Flutter 3.47.7 stable / Xcode 27.1)
ملاحظة: الجولة الأولى كانت على Flutter 3.41.2 (انظر العوائق). بعد الترقية أعيد تشغيل كل البوابات على 3.47.7، والجدول يعكس الجولة الثانية.
ملاحظات عامة:
- المستودع هو `packages/siro_map_engine` نفسه (له `.git` خاص). الأوامر تتنفّذ من جذر الحزمة. `git add -- packages/siro_map_engine` من جذر map-saas بيضيف الحزمة كـ repo متداخل، فالكوميت بيصير من داخل الحزمة بمسارات صريحة.
- الـ workspace بيعتمد **pub workspaces**. `melos` موجود كـ `dev_dependency` (7.8.1)، وما انثبّت شي عالمياً.
- `melos` مش على `PATH`، وسكربتات `melos.scripts` بتستدعي `melos` مباشرة. الحل المستخدم: shim مؤقت بمجلد السكراتش (`/private/tmp/…/scratchpad/shim/melos` = `exec dart run melos "$@"`) ومُمرَّر عبر `PATH=`. ما انثبّت شي على الجهاز.
- `melos run <script>` بدون `--no-select` بيطلب اختيار حزمة تفاعلي، وبيفشل بدون TTY. لازم `--no-select`.

| الغرض | الأمر | النتيجة | الوقت |
|---|---|---|---|
| bootstrap | `flutter pub get` (من جذر الحزمة، pub workspace) | ✅ exit 0. تغيّرت 131 حزمة. Flutter كتب `#include?` بملفات `ios/Flutter/*.xcconfig` (تم التراجع) | ~1 دقيقة |
| analyze | `PATH=<shim>:$PATH dart run melos run analyze-all` | ✅ exit 0، 5 حزم: No issues found (`--fatal-warnings --fatal-infos`) | 19 ث |
| test:io | `PATH=<shim>:$PATH dart run melos run test:io --no-select` | ✅ maplibre_gl_platform_interface +302 All passed، maplibre_gl +226 All passed | 52 ث |
| test:web | `PATH=<shim>:$PATH dart run melos run test:web --no-select` | ✅ maplibre_gl_web +46، platform_interface +302، maplibre_gl +217: All passed (Chrome) | 211 ث |
| test:scripts | `PATH=<shim>:$PATH dart run melos run test:scripts --no-select` | ✅ maplibre_code_gen +16 All passed | <1 ث |
| format check | `dart format --set-exit-if-changed .` | ✅ exit 0، 222 ملف، 0 تغيير | 0.9 ث |
| generate | `PATH=<shim>:$PATH dart run melos run generate --no-select` | ✅ exit 0، **ما في diff** بعدها | 4 ث |
| check-style-spec | `PATH=<shim>:$PATH dart run melos run check-style-spec --no-select` | ✅ exit 0 | — |
| build apk (example) | `flutter build apk --debug` (في `maplibre_gl_example/`) | ✅ exit 0، `build/app/outputs/flutter-apk/app-debug.apk` (الجولة الأولى فشلت، انظر العائق 1) | 537 ث |
| build ios sim (example) | `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ios --simulator --debug` | ✅ exit 0، `build/ios/iphonesimulator/Runner.app` (انظر العائق 2 و3) | 60 ث |
| ci كامل (بعد QA-01) | `tool/ci.sh` | — (ما انعمل بعد) | — |
| unit tests للمثال (F-03) | `cd maplibre_gl_example && flutter test test/bench_stats_test.dart` | ✅ 21 ناجح. ما بتدخل بـ `melos run test:io` لأن نطاقه `maplibre_gl` و`maplibre_gl_platform_interface` بس (انظر العوائق) | 2 ث |

**ملاحظة:** `flutter build ios` بيكتب `Pods` integration (`project.pbxproj`، `contents.xcworkspacedata`، `Podfile.lock`، و`#include?` بالـ xcconfig). التغييرات دي تراجعت بعد كل بناء، وما انكتبت بالكوميت.

## القرارات
| ID | القرار | الحالة | التاريخ |
|---|---|---|---|
| D-001 | صاحب الحقوق بملفات الترخيص: **"Siro Maps"** | معتمد | 2026-10-21 |
| D-002 | مجلد `website/`: حذف (التوثيق بيصير بـ `docs/`) | مقترح | 2026-10-21 |
| D-003 | إعادة تسمية الـ packages الداخلية بالمحرك الأصلي (`org.maplibre.android`، `MLN*`): **لا**، بس الإحداثيات والهوية الثنائية | معتمد | 2026-10-21 |
| D-004 | الـ 3D على الموبايل بالمرحلة الحالية عن طريق WebView + maplibre-gl-js محلي (`siro_gl_terrain`) | معتمد | 2026-10-21 |
| D-005 | المستودع الأصلي C++ منفصل: `~/development/App/siro-native` | معتمد | 2026-10-21 |
| D-006 | المثال المتداخل `maplibre_gl/example` (pub example، خارج الـ workspace) صار اسمه `siro_gl_minimal_example`، عشان ما يتعارض مع `siro_gl_example` | معتمد | 2026-10-21 |
| D-007 | ملفات الـ API (`maplibre_gl.dart`، `maplibre_gl_web.dart`، `method_channel_maplibre_gl.dart`) بيتغيّر اسمها بـ ID-03، ID-02 بيغيّر بس اسم الحزمة | معتمد | 2026-10-21 |

## سجل المهام
| ID | المهمة | الحالة | commit | الدليل / الملاحظات |
|---|---|---|---|---|
| F-01 | تجهيز البيئة | ✅ | `chore(siro-gl): F-01 … ✅` (انظر git log) | كل البوابات ناجحة على Flutter 3.47.7: analyze نظيف، test:io (302 + 226)، test:web (46 + 302 + 217)، test:scripts (16)، format (0 تغيير)، generate (0 diff)، check-style-spec ✅، build apk ✅، build ios sim ✅. العائقان 1 و2 محلولان، انظر السجل |
| F-02 | بناء وتشغيل المثال | ✅ | (انظر git log) | iOS: `iPhone 17 Pro` (iOS 26.0، محاكي) شغّال، لقطة الخريطة الرئيسية "Full screen map" بالمسار `docs/evidence/F-02/ios-iphone17pro-full-screen-map.png` (1206×2622): الخريطة بتتحمّل والتايلز والأسماء والـ attribution ظاهرين. Android: build ✅ (F-01)، لكن **التشغيل على emulator لسا ما صار**: ما في `emulator` ولا system image مثبّتين على الجهاز، والتثبيت يحتاج موافقتك (⏳). |
| F-03 | أداة القياس | ✅ | (انظر git log) | صفحة `Bench (performance)` بالـ Advanced + مسار شارع الحزام الدائري (8072 م من OSM) + 21 اختبار وحدة. ثلاث تشغيلات على محاكي iPhone 17 Pro (iOS 26.0، debug): الأرقام بـ `BENCHMARK.md`، والأدلة الخام `docs/evidence/F-03/`. **عداد الشبكة** اتضاف بعدين: iOS اتحقق على المحاكي (23 طلب، تشغيل تحقّق)، Android بيتبنى (Java يتجمّع) بس ما اتشغّلش (انظر العوائق). FPS هون Flutter بس، مش الخريطة (PF-01). |
| F-04 | خريطة الكود | ✅ | (انظر git log) | `docs/ARCHITECTURE.md`. الجدول بالقسم 4 فيه 95 صف، وكل اسم من الاتحاد موجود. الأرقام: Dart 95، Android 94، iOS 89 (العد بالـ grep والمقارنة بالـ script، الأرقام بالنص). |
| ID-01 | الترخيص والإشعارات | ✅ | (انظر git log) | `NOTICE` بالجذر (نصوص الـ LICENSE الأصلية من `HEAD` حرفياً، 3 أقسام). قسم حقوق سيرو (Siro Maps، BSD-3-Clause على تعديلاتنا) فوق كل `LICENSE`، والكتلة الأصلية بعده بدون تغيير (فرق الاختبار بين النص القديم والجديد: صفر للمحتوى الأصلي). `THIRD_PARTY_LICENSES.md` (13 مكوّن). `license_test` ✅ (3 اختبارات)، `test:io` ✅ (232 + 302). ملفات web وplatform_interface كان فيها فواصل 102 شرطة، صارت 80 مع اسم. |
| ID-02 | إعادة تسمية حزم Dart | ✅ | (انظر git log) | المجلدات: `maplibre_gl`→`siro_gl`، `maplibre_gl_platform_interface`→`siro_gl_platform_interface`، `maplibre_gl_web`→`siro_gl_web`، `maplibre_gl_example`→`siro_gl_example`، `scripts`→`siro_gl_codegen`. مساحة العمل `siro_gl_workspace`، و`siro_gl.code-workspace` (JSON صحيح، كان فيه فاصلة زايدة). استيرادات `package:` كلها، مسارات `path:` والـ melos scopes والـ CI والـ generator وسكربتات الإصدار. ملفات الـ LICENSE والـ NOTICE والـ CHANGELOG ما انلمست. `analyze` ✅ (5 حزم)، `format` ✅، `test:io` ✅ (232+302)، `test:scripts` ✅ (16)، `test:web` ✅ (223+302+46). |
| ID-03 | الواجهات العامة Dart | ✅ | (انظر git log) | أسماء الأصناف بالجدول: `SiroMap`، `SiroMapController`، `SiroMapOptions`، `SiroGlPlatform`، `SiroMethodChannel`، `SiroGlobalPlatform`، `SiroGlobalMethodChannel`، `SiroStyles`، `SiroJsSource`، `SiroJsLoader`، `SiroJsLoaderException`، `SiroMapPlugin`، و`JsMapImpl` (داخلي). ملفات الـ API: `siro_gl.dart`، `siro_map.dart`، `siro_styles.dart`، `siro_gl_platform_interface.dart`، `siro_js_source.dart`، `method_channel_siro_gl.dart`، `siro_gl_web.dart`، `siro_map_plugin.dart`، `siro_web_gl_platform.dart`. القنوات بملف واحد `siro_gl_platform_interface/lib/src/channels.dart`: `com.siro.gl/global`، `com.siro.gl/map_<id>`، `com.siro.gl/map` (view type). الـ Dart والـ native (Android/iOS) مكتوبين بنفس الأسماء. أسماء الاختبارات (`*_test.dart`) ما اتغيّرت. `analyze` ✅، `test:io` ✅ (232+302)، `test:web` ✅ (223+302+46). |
| ID-04 | Android | ✅ | (انظر git log) | الحزمة `com.siro.gl` (المجلد `android/src/main/java/com/siro/gl`). الأصناف: `SiroGlPlugin`، `SiroMapController`، `SiroMapFactory`، `SiroMapBuilder`، `SiroMapOptionsSink`، `SiroCustomHttpInterceptor`، `SiroHttpRequestUtil`، `SiroGpsLocationEngine`، `SiroNetworkStats`، `SiroUtils`. أصناف SDK المحرك (`org.maplibre.android.*`، `MapLibreMap`) ما انلمست. المثال: `namespace com.siro.gl.example` (applicationId يورث الـ namespace). Gradle: `rootProject.name = siro_gl`، والـ gradle-compat و`flutter_ci` بيستخدموا `:siro_gl`. `flutter build apk --debug` ✅ (المثال). التشغيل على الـ emulator ما انعمل (بطلب منك). |
| ID-05 | iOS | ✅ | (انظر git log) | `siro_gl.podspec` (الاسم `siro_gl`، المؤلف Siro Maps). `Package.swift` (الحزمة `siro_gl`، المنتج `siro-gl`، الهدف `siro_gl`). المجلد `ios/siro_gl/Sources/siro_gl`. الأصناف: `SiroGlPlugin`، `SiroMapController`، `SiroMapFactory`، `SiroMapOptionsSink`، `SiroCustomHeaders`، `SiroHeadersProtocol`، `SiroNetworkStats`. `MapLibre` كـ SDK (الـ pod والـ import) ما انلمس. مثال iOS: bundle id `com.siro.gl.example`. `flutter build ios --simulator --debug` ✅ (بعد `flutter clean`، لأن cache الـ SwiftPM القديم فيه مسارات مطلقة للمجلد القديم). **تشغيل على المحاكي ✅:** الخريطة الرئيسية (Full screen map) بتعرض tiles بالكود المعاد تسميته. |
| ID-06 | Web | ✅ | (انظر git log) | الـ registrar `SiroMapPlugin`، `fileName: siro_gl_web.dart`، `SiroJsSource` قابل للضبط (cdn/bundled/preloaded). `flutter build web` ✅ للمثال. الخريطة بتفتح بـ Chrome (tiles ظاهرة) عبر `?example=full-screen-map`. |
| ID-07 | المولّد | ✅ | (انظر git log) | `melos run generate` بيشتغل بعد تصليح مسارات الـ templates (كانت لسا `scripts/templates`). توليد الـ 6 ملفات ما بعمل أي diff. `check-style-spec` ✅. `test:scripts` ✅ (16). |
| ID-08 | الوثائق والهوية | ✅ | (انظر git log) | README ثنائي اللغة (`siro_gl/README.md`، والجذر رابط إليه). `SECURITY.md` بدل `SECURITY_POLICY.txt`، وعنوان الأمان **placeholder لصاحب المشروع**. CHANGELOG: `## 1.0.0-dev` مع قائمة الأسماء المتغيّرة. CONTRIBUTING وRELEASE وARCHITECTURE تحدّثت بالأسماء الجديدة. `website/` ما انحذف (D-002 مقترح، ينتظر قرار). |
| QA-01 | CI محلي | ✅ | (انظر git log) | `tool/ci.sh`: pub get، format، analyze، test io/scripts/web، codegen check (generate بدون diff)، build apk، build ios sim. `SKIP_WEB=1` و`SKIP_BUILD=1` للتسريع. آخر تشغيل كامل: كل الخطوات ✅ ما عدا test io اللي فشل بسبب README قديم (تصحّح، ونجح بعد الإصلاح: 232 + 302). |
| C-01 | حجم الكاش | ⬜ | | |
| C-02 | إحصاءات الكاش | ⬜ | | |
| C-03 | البذرة المدمجة | ⬜ | | |
| C-04 | التنزيل الذكي | ⬜ | | |
| C-05 | كاش الويب | ⬜ | | |
| C-06 | الهيدرات | ⬜ | | |
| C-07 | وثيقة السيرفر | ⬜ | | |
| C-08 | قياس C | ⬜ | | |
| PF-01 | قياس الرسم الأصلي | ⬜ | | |
| PF-02 | OpenGL/Vulkan | ⬜ | | |
| PF-03 | batch | ⬜ | | |
| PF-04 | GeoJSON diff | ⬜ | | |
| PF-05 | أصول الويب المحلية | ⬜ | | |
| PF-06 | Isolate | ⬜ | | |
| PF-07 | warmUp | ⬜ | | |
| PF-08 | قياس PF | ⬜ | | |
| Q-01 | ستايلات سيرو | ⬜ | | |
| Q-02 | العربي | ⬜ | | |
| Q-03 | Sprites | ⬜ | | |
| Q-04 | pipeline التايلز | ⬜ | | |
| Q-05 | hillshade | ⬜ | | |
| Q-06 | مقارنة بصرية | ⬜ | | |
| D-T0 … D-T10 | الـ 3D (انظر SIRO_3D_PLAN.md) | ⬜ | | |
| QA-02 | اختبارات تكامل | ⬜ | | |
| QA-03 | debug overlay | ⬜ | | |
| QA-04 | توثيق API | ⬜ | | |
| N-01 | استنساخ وأدوات C++ | ⬜ | | |
| N-02 | بناء Android | ⬜ | | |
| N-03 | بناء iOS | ⬜ | | |
| N-04 | الهوية الثنائية | ⬜ | | |
| N-05 | مسار تحديث من الأصل | ⬜ | | |
| N-06 | الكاش بالمحرك | ⬜ | | |
| N-07 | العربي بالمحرك | ⬜ | | |
| N-08 | دراسة terrain أصلي | ⬜ | | |
| N-09 | تقليل الحجم | ⬜ | | |
| N-10 | قياس N | ⬜ | | |
| R-01 … R-04 | الجاهزية | ⬜ | | |

## العوائق
| التاريخ | المهمة | الوصف | الاقتراح | الحالة |
|---|---|---|---|---|
| 2026-10-21 | F-01 | ✅ **محلول:** ترقية Flutter من 3.41.2 لـ **3.47.7 stable** بموافقة صاحب المشروع (`flutter upgrade --force`، والقوة كانت لازمة لأن `pubspec.lock` داخل SDK اتعدّل محلياً بسطر واحد من أداة Flutter: `ffigen` من `direct main` لـ `direct dev`؛ ما في غيره). بعدها build apk نجح. **عائق 1 (Android) الأصلي:** `flutter build apk --debug` فشل بالـ Gradle: `Could not find method kotlin() … on project ':app'` عند `maplibre_gl_example/android/app/build.gradle:63`. الملف فيه تعليق "as of the Flutter 3.44 app template" (بنفس block `kotlin { compilerOptions {…} }` بعد `flutter { source }`)، وFlutter المثبّت 3.41.2. على الأرجح الكود مكتوب لقالب Flutter 3.44 والـ SDK المحلي أقدم. | (أ) ترقية Flutter SDK لـ 3.44+ على الجهاز (تثبيت أداة: **يحتاج موافقتك**)، أو (ب) تعديل `build.gradle` ليطابق 3.41 (قرار، يغيّر إعدادات الـ example). | ⏳ بانتظار قرار |
| 2026-10-21 | F-01 | **عائق 2 (iOS):** `flutter build ios --simulator --debug` فشل بعد `pod install` (`Running Xcode build … 35 ث`): `Target debug_unpack_ios failed: Binary …/Flutter.framework/Flutter does not contain architectures "arm64 x86_64"` (Xcode 27.1). الـ framework المنسوخ في `build/ios/` فيه `x86_64 arm64` فعلاً، فالسبب مش واضح. ✅ **اختفى مع Flutter 3.47.7** (ما عاد يتكرر)، وظهر بدله عائق 3. | — | ✅ محلول بالترقية |
| 2026-10-21 | F-01 | **عائق 3 (iOS، بعد الترقية):** `Error (Xcode): The sandbox is not in sync with the Podfile.lock`. كنت حذفت `Podfile.lock` بعد الجولة الأولى. | `pod install` في `maplibre_gl_example/ios` مع `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8`، لأن CocoaPods 1.16.2 بيفشل بدون UTF-8 (`Unicode Normalization not appropriate for ASCII-8BIT`). بعدها `flutter build ios` نجح. | ✅ محلول |
| 2026-10-21 | F-03 | **العداد الشبكي اتعمل** (بطلب صاحب المشروع): iOS عبر `canInit` بـ `MapLibreHeadersProtocol` (الـ protocol مسجّل أصلاً على الـ session، فالعدّ بيغطي كل طلب بدون ما يغيّر سلوك التحميل). اتحقق على المحاكي: 23 طلب. bytes = null على iOS (البايتات بتتعدّ بس لما الـ protocol يعترض، وهو يعترض بس مع الـ custom headers). Android عبر OkHttp network interceptor + `Content-Length`. **ما اتشغّلش على Android** (ما في emulator): بس الكود بيتجمّع (`flutter build apk` ✅). | Android: تحقق بالـ emulator لما توافق على تثبيته. | ⏳ تحقق Android |
| 2026-10-21 | F-03 | **عدّاد Android بيبدّل الـ OkHttp client** (الـ SDK ما بيعطي getter للـ client الحالي). تفعيل العدّاد بيعيد بناء الـ client زي `setHttpHeaders`، فالـ headers اللي اتحطّت per map بـ `setCustomHeaders` بتنمسح لحد ما تتحط من جديد. موثّق بالـ dartdoc وبالـ CHANGELOG. | مقبول لحد ما نحلّ مشكلة الـ client الواحد (last writer wins) بشكل عام. | ✅ موثّق |
| 2026-10-21 | F-03 | **ملاحظة على كود موجود (ما انلمس):** `MapLibreMapsPlugin.swift` › `setHttpHeaders` بيستدعي `result(FlutterError)` وبعدها `result(nil)` في نفس الفرع، يعني نداء `result` مرتين على خطأ فك التشفير. | نصلّحه بتغيير منفصل. | ⏳ |
| 2026-10-21 | F-03 | **FPS هون = فريمات Flutter مش الخريطة.** الرسم native GL، فـ FPS الحقيقي بيحتاج `onRenderStats` (PF-01). القيمة الحالية ~1 fps وهي مش قياس للخريطة. | مثبّت بـ BENCHMARK.md كتحذير. PF-01 بيصلّحه. | ✅ موثّق |
| 2026-10-21 | F-03 | **`firstCameraIdleMs` بيصير قبل `firstStyleLoadedMs`** (447 مقابل 938 ms بالتشغيل الأول). الـ idle الأولي للمحرك قبل الستايل، فالاسم مضلّل. | نعيد تعريفه (أول idle بعد الستايل) بتغيير لاحق، والأرقام الحالية تبقى كما هي مع التحذير. | ⏳ تحسين لاحق |
| 2026-10-21 | F-03 | **نص الحالة ما بيتحدّث أثناء التشغيل** (بيضل "step 0 / 1200"). السبب: الـ `setState` ما بيصير مع كل خطوة كاميرا. الـ JSON صحيح (من العدادات عند الانتهاء). | نصلّحه بعد ما تخلص التشغيلات، عشان الـ build المقاس يضل نفسه. | ⏳ تجميلي |
| 2026-10-21 | F-03 | **`melos` ما بيشمل مجلد `maplibre_gl_example/test/`.** نطاق `test:io` و`test:web` بس `maplibre_gl` و`maplibre_gl_platform_interface`. | نضيف المثال للنطاق أو نعمل `tool/ci.sh` (QA-01). | ⏳ QA-01 |
| 2026-10-21 | F-03 | **التشغيل على الجهاز الحقيقي وAndroid ما انعملوا.** المحاكي debug فقط (Flutter ما بيدعم profile/release على محاكي iOS). | الجهاز الحقيقي بـ profile ⏳ بانتظار صاحب المشروع، وAndroid بعد تثبيت الـ emulator (موافقتك). | ⏳ |
| 2026-10-21 | F-04 | **فجوات وجدها الفحص (ما اتصلحت، توثيق بس):** `layer#getVisibility` ما عندها case على أي منصة. iOS ناقصه `setOffline`، و`source#getFeatureState`، و`source#setFeatureState`، و`source#removeFeatureState`، و`updateOfflineRegionMetadata`. | كل وحدة تتصلح بتغيير منفصل، أو نقرر نحذف الدالة. | ⏳ قرار |
| 2026-10-21 | ID-01 | **Google Play services** (`play-services-base` و`play-services-location`): الترخيص شروط Google للـ SDK مش OSS، وما قرينا النص الرسمي. | نقرأ النص الرسمي ونضيفه لـ `THIRD_PARTY_LICENSES.md` قبل R-02. | ⏳ قبل النشر |
| 2026-10-21 | ID-01 | **التحقّق من المصدر فقط:** okhttp، pmtiles (JS، 4.4.0 من unpkg)، androidx.core. الـ jars والـ JS مش بالكاش، فالترخيص مكتوب من المصدر الرسمي. الـ AAR الخاص بـ maplibre-native 13.5.0 ما فيه ملف LICENSE داخله. | نتحقق من النص قبل النشر (R-02 بيتأكد). | ⏳ قبل النشر |
| 2026-10-21 | F-01 | `melos` ما على `PATH`، ومايستطيعش `melos run` يشغّل سكربتاته بدون ترك الـ PATH. الحل: shim مؤقت بالسكراتش (ما انثبّت على الجهاز). | تثبيت `melos` عالمياً (`dart pub global activate melos`) هو الحل النظيف، بس هاد **تثبيت أداة على الجهاز** فما انعمل بدون موافقتك. | ⏳ اختياري |

## يوميات الجلسات
<!-- سطر لكل جلسة: التاريخ · المهام · النتيجة · المهمة الجاية -->
- 2026-10-21 · F-01 · الجولة الأولى (Flutter 3.41.2): التحليل والاختبارات والتوليد ناجحة، والبناءات فشلت (عائق 1 و2). بعد موافقة صاحب المشروع رُقّي Flutter لـ 3.47.7، وأعيدت كل البوابات + build apk + build ios sim بنجاح · **المهمة الجاية:** F-02 (لقطات الشاشة على محاكي iOS وAndroid، ومسارات `docs/evidence/F-02/`).
- 2026-10-21 · F-02 · تشغيل المثال على iPhone 17 Pro (محاكي iOS 26.0): الخريطة الرئيسية "Full screen map" ظاهرة بالتايلز، اللقطة في `docs/evidence/F-02/ios-iphone17pro-full-screen-map.png`. أذونات الموقع: اخترت "Don't Allow" (ما في حاجة للموقع بهاي اللقطة). Android: تشغيل emulator ⏳ بانتظار موافقة تثبيت. المحاكي اتقفل بعد اللقطة.
- 2026-10-21 · QA-01 + ID-08 · `tool/ci.sh` و الوثائق. الـ gate الكامل كان ✅ إلا test io (README قديم، صلّحناه). **قرارات مفتوحة لصاحب المشروع:** عنوان الأمان (SECURITY.md)، حذف `website/` (D-002)، اسم العرض والعنوان على الجهاز والويب (`MapLibre Example`) ، `homepage` بالـ podspec ما زال upstream، والمرحلة 8.
- 2026-10-21 · ID-07 · codegen: التوليد ما بيشتغل بعد ID-02 لأن مسارات الـ templates كانت لسا `scripts/templates`. صلّحناها، و`generate` ما عمل أي diff. ID-06: web build ✅ وفتح بـ Chrome ✅. **المهمة الجاية:** QA-01 (tool/ci.sh).
- 2026-10-21 · ID-05 · iOS: الـ podspec و`Package.swift` والأصناف و`pluginClass` و bundle id. التشغيل على المحاكي ✅ (خريطة بالـ tiles). عيوب معروفة مسجّلة: اسم العرض `MapLibre Example` وعنوان التطبيق `MapLibre Examples` لسا (هوية UI، ID-08)، وـ`homepage` بالـ podspec ما زال upstream. **المهمة الجاية:** ID-06.
- 2026-10-21 · ID-04 · Android: الحزمة `com.siro.gl` والأصناف. APK ✅. (iOS ما زال بالأسماء القديمة لحد ID-05، لذلك `pluginClass` في pubspec تبع iOS مكسور لحد ما نخلّص ID-05.) **المهمة الجاية:** ID-05.
- 2026-10-21 · ID-03 · أسماء الأصناف والملفات وملف القنوات. ما زال Android وiOS بأسماء أصناف `MapLibre*` (ID-04 و ID-05). **المهمة الجاية:** ID-04.
- 2026-10-21 · ID-02 · إعادة تسمية الحزم والمجلدات. ملاحظة: استعملت `git add -A` مرة بالخطأ (ممنوع بالقواعد)، وتحققت من المجموعة المرحلة ملف ملف (ما في بناء أو أسرار)، وتراجعت عن تغييرات CocoaPods اللي خلّفها بناء iOS سابق (ملفات xcconfig). `analyze` و`test:io` و`test:web` و`test:scripts` و`format` كلها ✅. **المهمة الجاية:** ID-03 (الواجهات العامة وأسماء القنوات).
- 2026-10-21 · ID-01 · الترخيص: NOTICE بالجذر من HEAD حرفياً، قسم Siro (BSD-3) فوق كل LICENSE، فواصل 80 شرطة بدل 102 بحزمة web وplatform_interface، و`THIRD_PARTY_LICENSES.md`. `license_test` ✅ و`test:io` ✅. **المهمة الجاية:** ID-02 (إعادة تسمية حزم Dart، تغيير واسع لمسارات الاستيراد).
- 2026-10-21 · F-04 · `docs/ARCHITECTURE.md`: الطبقات، القنوات، مولّد الكود، وجدول 95 طريقة من الكود. فجوات iOS مسجّلة بالعوائق · **المهمة الجاية:** ID-01 (الترخيص والإشعارات، أول إشي قبل أي إعادة تسمية).
- 2026-10-21 · F-03 · بناء الأداة، 21 اختبار وحدة ناجحة، analyze نظيف، format بدون تغيير، build apk ✅، build ios sim ✅. ثلاث تشغيلات على المحاكي (كل واحد بعد إعادة تشغيل التطبيق)، النتايج بـ BENCHMARK.md. **المهمة الجاية:** F-04 (خريطة الكود، توثيق بدون تعديل كود).
