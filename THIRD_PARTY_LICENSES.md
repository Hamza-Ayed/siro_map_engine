# THIRD_PARTY_LICENSES (محرك سيرو)

هاد الملف بيسجّل كل مكوّن خارجي بيتضمّن أو بيتحمّل مع المحرك، مع ترخيصه ورابطه والإصدار المثبّت.

- نصوص الترخيص الكاملة للمكوّنات اللي بتتضمّن بالكود موجودة بـ [LICENSE](LICENSE) و[NOTICE](NOTICE)، كما هي حرفياً.
- عمود **التحقّق** بيوضّح: "من الملف" يعني إن الترخيص اتقرأ من نص موجود بالمستودع أو بالـ SPM checkout. "من المصدر" يعني إنه مُعرّف من الرابط الرسمي، ولازم يتحقق قبل النشر (R-02).

| المكوّن | الإصدار المثبّت | الترخيص | الرابط | أين بيُستخدم | التحقّق |
|---|---|---|---|---|---|
| maplibre-native (Android) | 13.5.0 (`org.maplibre.gl:android-sdk-opengl`) | BSD-2-Clause | https://github.com/maplibre/maplibre-native | `maplibre_gl/android/build.gradle` (سطر 68). الـ AAR ما فيه ملف LICENSE داخله | من الملف (نص الإشعار في `LICENSE`، القسم maplibre-gl-native) |
| maplibre-native (iOS) | MapLibre 6.28.0 (SPM `maplibre-gl-native-distribution`) | BSD-2-Clause | https://github.com/maplibre/maplibre-gl-native-distribution | `maplibre_gl/ios/maplibre_gl/Package.swift` | من الملف (`LICENSE.md` بالـ SPM checkout: "BSD 2-Clause License") |
| maplibre-gl-js | 6.4.1 (`kMapLibreJsVersion`) | BSD-3-Clause | https://github.com/maplibre/maplibre-gl-js | `maplibre_gl_web/lib/src/js_loader.dart` (سطر 16)، محمّل من unpkg | من الملف (القسم maplibre-gl-js في `LICENSE`) |
| flutter-maplibre-gl (الأصل) | 0.27.1 | BSD-3-Clause | https://github.com/maplibre/flutter-maplibre-gl | الأساس اللي تفرّع منه المحرك | من الملف (الكتلة الأولى في `LICENSE`، والـ Siro section فوقها) |
| flutter-mapbox-gl (fork 2021) | نقطة الفرع: 6 مارس 2021 | BSD-2-Clause | https://github.com/tobrun/flutter-mapbox-gl | كود منسوخ من الـ fork | من الملف (القسم flutter-mapbox-gl في `LICENSE`) |
| mapbox-gl-js (حتى v1.13) | v1.13 وما قبلها | BSD-3-Clause | https://github.com/mapbox/mapbox-gl-js | أجزاء كود مأخوذة | من الملف (القسم mapbox-gl-js في `LICENSE`) |
| glfx.js | غير مذكور بالملف | MIT (نص الإذن في الملف) | https://github.com/evanw/glfx.js | أجزاء كود مأخوذة | من الملف (القسم glfx.js في `LICENSE`) |
| d3-color | غير مذكور بالملف | BSD-3-Clause | https://github.com/d3/d3-color | أجزاء كود مأخوذة | من الملف (القسم d3-color في `LICENSE`) |
| okhttp | 5.4.0 | Apache-2.0 | https://github.com/square/okhttp | `maplibre_gl/android/build.gradle` (سطر 69) | من المصدر، ما في الـ jar بالكاش فما اتحقّق من الملف |
| Google Play services (base، location) | 18.10.1 و21.4.0 | شروط Google للـ SDK (مش OSS) | https://developers.google.com/android/guides/setup | `maplibre_gl/android/build.gradle` (سطر 70-71) | **⏳ لازم نقرأ النص الرسمي قبل النشر** |
| pmtiles (JS) | 4.4.0 | BSD-3-Clause | https://github.com/protomaps/PMTiles | `maplibre_gl_example/web/index.html` (سطر 36)، محمّل من unpkg | من المصدر، ⏳ لازم يتحقق قبل النشر |
| androidx.core:core-ktx | 1.18.0 | Apache-2.0 | https://developer.android.com/jetpack/androidx | `maplibre_gl/android/build.gradle` (سطر 85) | من المصدر، ⏳ تحقق قبل النشر |

## ملاحظات

- الكود الخارجي اللي تضمّن بالنص (flutter-mapbox-gl، mapbox-gl-js، glfx.js، d3-color) نصوص إشعاراتها كما هي بـ `LICENSE`، ولا يُحذف منها أي حرف (R-02 بيتأكد من هاد).
- الـ JS (maplibre-gl-js و pmtiles) مش ممسوك بالنسخة الحالية، بيتحمّل من CDN. لما نعمل bundled (PF-05)، بتصير هاي الملفات جزء من الحزمة وبتحتاج نصوص إشعاراتها بـ `LICENSE` الخاصة بالحزمة.
- حقوق سيرو على تعديلاتنا: BSD-3-Clause، باسم Siro Maps (القرار D-001 بـ PROGRESS.md). الأمر بسيط: حقوق سيرو ما بتلغي أي إشعار خارجي.
