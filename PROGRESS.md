# سجل تقدم محرك سيرو

> المنفّذ بيحدّث هاد الملف **بكل مهمة** (القسم 3 بـ [SIRO_MASTER_PLAN.md](SIRO_MASTER_PLAN.md)).
> الحالات: ⬜ لسا · 🔄 شغّال · ✅ خلص · ⏳ بانتظار صاحب المشروع (جهاز حقيقي أو قرار) · ⛔ عائق

## الحالة الحالية
- **آخر مهمة مكتملة:** F-01
- **المهمة الجاية:** F-02
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

**ملاحظة:** `flutter build ios` بيكتب `Pods` integration (`project.pbxproj`، `contents.xcworkspacedata`، `Podfile.lock`، و`#include?` بالـ xcconfig). التغييرات دي تراجعت بعد كل بناء، وما انكتبت بالكوميت.

## القرارات
| ID | القرار | الحالة | التاريخ |
|---|---|---|---|
| D-001 | صاحب الحقوق بملفات الترخيص: **"Siro Maps"** | معتمد | 2026-10-21 |
| D-002 | مجلد `website/`: حذف (التوثيق بيصير بـ `docs/`) | مقترح | 2026-10-21 |
| D-003 | إعادة تسمية الـ packages الداخلية بالمحرك الأصلي (`org.maplibre.android`، `MLN*`): **لا**، بس الإحداثيات والهوية الثنائية | معتمد | 2026-10-21 |
| D-004 | الـ 3D على الموبايل بالمرحلة الحالية عن طريق WebView + maplibre-gl-js محلي (`siro_gl_terrain`) | معتمد | 2026-10-21 |
| D-005 | المستودع الأصلي C++ منفصل: `~/development/App/siro-native` | معتمد | 2026-10-21 |

## سجل المهام
| ID | المهمة | الحالة | commit | الدليل / الملاحظات |
|---|---|---|---|---|
| F-01 | تجهيز البيئة | ✅ | `chore(siro-gl): F-01 … ✅` (انظر git log) | كل البوابات ناجحة على Flutter 3.47.7: analyze نظيف، test:io (302 + 226)، test:web (46 + 302 + 217)، test:scripts (16)، format (0 تغيير)، generate (0 diff)، check-style-spec ✅، build apk ✅، build ios sim ✅. العائقان 1 و2 محلولان، انظر السجل |
| F-02 | بناء وتشغيل المثال | ⬜ | | |
| F-03 | أداة القياس | ⬜ | | |
| F-04 | خريطة الكود | ⬜ | | |
| ID-01 | الترخيص والإشعارات | ⬜ | | |
| ID-02 | إعادة تسمية حزم Dart | ⬜ | | |
| ID-03 | الواجهات العامة Dart | ⬜ | | |
| ID-04 | Android | ⬜ | | |
| ID-05 | iOS | ⬜ | | |
| ID-06 | Web | ⬜ | | |
| ID-07 | المولّد | ⬜ | | |
| ID-08 | الوثائق والهوية | ⬜ | | |
| QA-01 | CI محلي | ⬜ | | |
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
| 2026-10-21 | F-01 | `melos` ما على `PATH`، ومايستطيعش `melos run` يشغّل سكربتاته بدون ترك الـ PATH. الحل: shim مؤقت بالسكراتش (ما انثبّت على الجهاز). | تثبيت `melos` عالمياً (`dart pub global activate melos`) هو الحل النظيف، بس هاد **تثبيت أداة على الجهاز** فما انعمل بدون موافقتك. | ⏳ اختياري |

## يوميات الجلسات
<!-- سطر لكل جلسة: التاريخ · المهام · النتيجة · المهمة الجاية -->
- 2026-10-21 · F-01 · الجولة الأولى (Flutter 3.41.2): التحليل والاختبارات والتوليد ناجحة، والبناءات فشلت (عائق 1 و2). بعد موافقة صاحب المشروع رُقّي Flutter لـ 3.47.7، وأعيدت كل البوابات + build apk + build ios sim بنجاح · **المهمة الجاية:** F-02 (لقطات الشاشة على محاكي iOS وAndroid، ومسارات `docs/evidence/F-02/`).
