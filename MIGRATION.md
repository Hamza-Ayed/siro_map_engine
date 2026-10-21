# الترحيل من flutter-maplibre-gl / Migrating from flutter-maplibre-gl

الحزمة الجديدة `siro_gl` بديلة عن `maplibre_gl`. الأسماء كلها تغيّرت، فيه خطوات واضحة لكل تطبيق.
The new `siro_gl` package replaces `maplibre_gl`. Every name changed, so each app has a clear set of steps.

## 1. الاستيراد / Imports

| قبل / Before | بعد / After |
|---|---|
| `package:maplibre_gl/maplibre_gl.dart` | `package:siro_gl/siro_gl.dart` |
| `package:maplibre_gl_web/...` | `package:siro_gl_web/...` (تلقائي عبر `siro_gl`) |

## 2. الأصناف / Classes

| قبل / Before | بعد / After |
|---|---|
| `MapLibreMap` | `SiroMap` |
| `MapLibreMapController` | `SiroMapController` |
| `MapLibreMapOptions` | `SiroMapOptions` |
| `MapLibreStyles` | `SiroStyles` |
| `MapLibrePlatform` | `SiroGlPlatform` |
| `MapLibreMethodChannel` | `SiroMethodChannel` |
| `MapLibreGlobalPlatform` | `SiroGlobalPlatform` |
| `MapLibreJsSource`، `MapLibreJsLoader`، `MapLibreJsLoaderException` | `SiroJsSource`، `SiroJsLoader`، `SiroJsLoaderException` |

## 3. المنصات / Platforms

- **Android:** الحزمة `org.maplibre.maplibregl` صارت `com.siro.gl`. الـ plugin class: `SiroGlPlugin`.
- **iOS:** الـ pod صار `siro_gl`. الـ plugin class: `SiroGlPlugin`.
- **Web:** الـ plugin class: `SiroMapPlugin`، والملف `siro_gl_web.dart`.

## 4. القنوات / Channels

القنوات تغيّرت. التطبيق ما بيحتاج يتعامل معها مباشرة، لكن لو كان فيه كود مخصص يكلّم القنوات بالاسم، لازم يتغيّر:
Channel names changed. Apps do not need to touch them, but any custom code that talks to channels by name must change:

| قبل / Before | بعد / After |
|---|---|
| `plugins.flutter.io/maplibre_gl` | `com.siro.gl/global` |
| `plugins.flutter.io/maplibre_gl_<id>` | `com.siro.gl/map_<id>` |

## 5. الأشياء اللي ما تغيّرت / What stayed the same

- أسماء الخصائص في الستايل (`line-color`، وغيرها) وأسماء أحداث maplibre-gl-js.
- إصدار المحرك الأصلي: MapLibre Android 13.5.0، وMapLibre iOS 6.28.0، وmaplibre-gl-js (المثبّت في الكود).

## 6. الفجوات المعروفة / Known gaps after migration

- feature state غير متاح على iOS (الـ SDK ما فيه API).
- `updateOfflineRegionMetadata` غير متاح على iOS (الـ SDK ما فيه تعديل للـ pack).
- `packDatabase` غير متاح على iOS.
- التضاريس ثلاثية الأبعاد غير متاحة بعد (انظر `docs/native/TERRAIN_FEASIBILITY.md`).
