# خريطة الكود (محرك سيرو)

> وثيقة للمطوّرين. بتوصف الطبقات والقنوات وكل اسم طريقة بين Dart والمنصات، وبتشرح مولّد الكود، وبتسجّل الفجوات المعروفة.
> الجدول بالقسم 4 **مولّد من الكود نفسه** بـ `grep` (انظر القسم 4)، مش مكتوب يدوياً.

## 1. الطبقات

```
تطبيق Dart
   │
siro_gl                       واجهة عامة: SiroMap، SiroMapController، دوال global
   │                              (lib/src/controller.dart، global.dart، siro_map.dart)
   │
siro_gl_platform_interface    عقد مجرّد SiroGlPlatform + تنفيذ القناة
   │                              (method_channel_siro_gl.dart، global_platform.dart)
   │
   ├── Method Channel ─────────── Android: Java/Kotlin            iOS: Swift
   │                              GlobalMethodHandler.java         SiroGlPlugin.swift
   │                              SiroMapController.java       SiroMapController.swift
   │                                    │                                 │
   │                              org.maplibre.android.*           MLNMapView (MapLibre iOS)
   │                              (المحرك الأصلي، Maven)           (المحرك الأصلي، SPM/pod)
   │
   └── Web (JS interop) ──────── siro_gl_web: siro_web_gl_platform.dart
                                  └─ maplibre-gl-js (JS، مش قناة)
```

- **الدوال العامة على مستوى التطبيق** (`setHttpHeaders`، `setOffline`، `getNetworkStats`...) بتمشي على قناة الـ global، وهي `com.siro.gl/global`.
- **أوامر كل خريطة** بتمشي على قناة خاصة بكل خريطة، `com.siro.gl/map_<id>`.
- **Web ما بيستخدم قنوات.** بيحمّل `maplibre-gl-js` ويتعامل معه بـ JS interop.

> ملاحظة: أسماء القنوات هي `com.siro.gl/...` (ثوابت في `siro_gl_platform_interface/lib/src/channels.dart`). الأسماء الأصلية `plugins.flutter.io/maplibre_gl...` اتغيّرت بـ ID-03 مع الـ native بـ ID-04 و ID-05.

## 2. القنوات

| القناة | معرّفة بـ | الاستخدام |
|---|---|---|
| `com.siro.gl/global` | `siro_gl/lib/src/global.dart`، `siro_gl_platform_interface/lib/src/global_platform.dart` | دوال على مستوى التطبيق: الكاش، الأوفلاين، الهيدرات، عداد الشبكة، `preWarm` |
| `com.siro.gl/map_<id>` | `siro_gl_platform_interface/lib/src/method_channel_siro_gl.dart` (سطر 134) | كل أوامر الخريطة: الكاميرا، الطبقات، المصادر، الـ annotations، الأحداث |
| `com.siro.gl/global` على الـ native | Android: `SiroGlPlugin.java` (سطر 46 و52)، وتوزيع الأوامر في `GlobalMethodHandler.java`. iOS: `SiroGlPlugin.swift` (سطر 12 و24) | استقبال القناة العامة |
| `com.siro.gl/map_<id>` على الـ native | Android: `SiroMapController.java` (سطر 306). iOS: `SiroMapController.swift` (سطر 129-130) | أوامر كل خريطة |

## 3. مولّد الكود

المولّد في `scripts/` (حزمة `siro_gl_codegen` بالـ workspace).

- **المدخل:** `scripts/input/style.json` (نسخة من مواصفة MapLibre style، والإصدار بـ `style_spec_version.txt`).
- **الكود:** `scripts/lib/generate.dart` بيقرأ المدخل وبيشغّل القوالب بـ `mustache_template`، وبيعمل `dart format` على الناتج.
- **التشغيل:** `melos run generate` (من جذر الحزمة، مع `--no-select` لو خارج التيرمنال).
- **التحقق:** `melos run check-style-spec` بيتأكد إن `style.json` مطابق للإصدار المثبّت.

| القالب (`scripts/templates/`) | الناتج |
|---|---|
| `LayerPropertyConverter.java.template` | `siro_gl/android/.../LayerPropertyConverter.java` |
| `LayerPropertyConverter.swift.template` | `siro_gl/ios/.../LayerPropertyConverter.swift` |
| `layer_expressions.dart.template` | `siro_gl/lib/src/layer_expressions.dart` |
| `layer_properties.dart.template` | `siro_gl/lib/src/layer_properties.dart` |
| `layer_tools.dart.template` | `siro_gl_web/lib/src/layer_tools.dart` |
| `source_properties.dart.template` | `siro_gl_platform_interface/lib/src/source_properties.dart` |

الملفات الناتجة مكتوب فيها "generated"، ولا تتعدّل يدوياً. التعديل بيكون على القالب أو على `generate.dart`. `SourcePropertyConverter.swift/java` ما بيتولّدوا (يدويين).

## 4. جدول أسماء الطرق (مولّد)

**الأرقام (تم التحقق بـ grep):**

| المصدر | عدد الأسماء المميّزة |
|---|---:|
| Dart (`invokeMethod` / `invokeMapMethod` / `invokeListMethod` وhelper `_getStyleObjectProperties`) | 95 |
| Android (`switch (call.method)` و`switch (methodCall.method)` في `GlobalMethodHandler.java` و`SiroMapController.java`) | 94 |
| iOS (`switch methodCall.method` / `switch call.method` في `SiroGlPlugin.swift` و`SiroMapController.swift`) | 89 |
| الاتحاد (كل الأسماء) | **95** (= 100% من أسماء Dart، وكل أسماء المنصات موجودة في Dart) |

الجدول تحت فيه صف لكل اسم من الاتحاد (95 صف). العمود "ملاحظة" بيسجّل الفجوات. `—` يعني ما في case بهاي المنصة.

| الطريقة | Dart | Android | iOS | ملاحظة |
|---|---|---|---|---|
| `backgroundLayer#add` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `camera#animate` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `camera#ease` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `camera#move` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `circleLayer#add` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `clearAmbientCache` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `colorReliefLayer#add` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `deleteOfflineRegion` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `downloadOfflineRegion` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `downloadOfflineRegion#setup` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `fillExtrusionLayer#add` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `fillLayer#add` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `getListOfRegions` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `getNetworkStats` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `getOfflineDatabasePath` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `getOfflineRegionStatus` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `heatmapLayer#add` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `hillshadeLayer#add` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `installOfflineMapTiles` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `layer#getVisibility` | method_channel_siro_gl.dart | — | — | Dart فقط: ما في case بأي منصة نيتيف. الاستدعاء بيرجع `notImplemented`. |
| `layer#setProperties` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `layer#setVisibility` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `lineLayer#add` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `locationComponent#getLastLocation` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `locationComponent#setManualLocation` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `locationComponent#setTrackingCameraOptions` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#clearAmbientCache` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#editGeoJsonSource` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#editGeoJsonUrl` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#forceOnlineMode` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#getCustomHeaders` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#getMetersPerPixelAtLatitude` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#getStyle` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#getTelemetryEnabled` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#getVisibleRegion` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#invalidateAmbientCache` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#matchMapLanguageWithDeviceDefault` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#pause` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#queryCameraPosition` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#queryRenderedFeatures` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#querySourceFeatures` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#resume` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#setCameraBounds` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#setCustomHeaders` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#setLayerFilter` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#setMapLanguage` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#setMaximumFps` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#setTelemetryEnabled` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#takeSnapshot` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#toLatLng` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#toScreenLocation` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#toScreenLocationBatch` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#update` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#updateContentInsets` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#updateMyLocationTrackingMode` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `map#waitForMap` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `mergeOfflineRegions` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `pauseOfflineRegionDownload` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `preWarm` | global_platform.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `rasterLayer#add` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `resetNetworkStats` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `resetOfflineDatabase` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `resumeOfflineRegionDownload` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `setHttpHeaders` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `setNetworkStatsEnabled` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `setOffline` | global.dart | GlobalMethodHandler.java | — | iOS: ما في case. Android بيدعمها. |
| `setOfflineMaxConcurrentRequests` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `setOfflineTileCountLimit` | global.dart | GlobalMethodHandler.java | SiroGlPlugin.swift |  |
| `source#addGeoJson` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `source#getClusterChildren` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `source#getClusterExpansionZoom` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `source#getClusterLeaves` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `source#getFeatureState` | method_channel_siro_gl.dart | SiroMapController.java | — | iOS: ما في case (feature state على iOS لسا ما انعمل). |
| `source#removeFeatureState` | method_channel_siro_gl.dart | SiroMapController.java | — | iOS: ما في case (نفس السبب). |
| `source#setFeature` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `source#setFeatureState` | method_channel_siro_gl.dart | SiroMapController.java | — | iOS: ما في case (نفس السبب). |
| `source#setGeoJson` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#addImage` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#addImageSource` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#addLayer` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#addLayerBelow` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#addSource` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#getFilter` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#getLayerIds` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#getLayerProperties` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#getSourceIds` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#getSourceProperties` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#removeLayer` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#removeSource` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#setFilter` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#setLight` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#setStyle` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `style#updateImageSource` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `symbolLayer#add` | method_channel_siro_gl.dart | SiroMapController.java | SiroMapController.swift |  |
| `updateOfflineRegionMetadata` | global.dart | GlobalMethodHandler.java | — | iOS: ما في case في الـ switch الرئيسي. |

## 5. الفجوات المعروفة (من الفحص أعلاه)

1. **`layer#getVisibility`**: موجودة في الـ platform interface بس، ما في case بأي منصة نيتيف. الاستدعاء بيرجع `notImplemented` على Android (`SiroMapController.java`، سطر 3124) وبيرجع `FlutterMethodNotImplemented` على iOS (`SiroMapController.swift`، سطر 1659). الإصلاح: إضافة الـ case على المنصتين، أو حذف الدالة لو ما بنحتاجها.
2. **`setOffline` على iOS**: الدالة العامة بتستدعيها، وما في case على iOS. قبل ما تعتمد على `setOffline` بـ iOS، اتحقق.
3. **feature state على iOS** (`source#getFeatureState`، `source#setFeatureState`، `source#removeFeatureState`): ما انعملوش على iOS. المثال بيوثّق هاد (FeatureStateExample مش مدعوم على iOS).
4. **`updateOfflineRegionMetadata` على iOS**: ما في case في الـ switch الرئيسي.

هاي الفجوات ما اتصلحتش في F-04 (الوثيقة فقط). كل وحدة بتحتاج قرار أو تغيير كود منفصل.

## 6. أين أعدّل ماذا

| بدي أضيف... | الخطوات |
|---|---|
| دالة عامة (على مستوى التطبيق) | 1) الدالة في `siro_gl/lib/src/global.dart`. 2) `case` في `GlobalMethodHandler.java` و`SiroGlPlugin.swift`. |
| أمر على خريطة (الكاميرا، طبقة، مصدر) | 1) الدالة على `SiroMapController` في `siro_gl/lib/src/controller.dart`. 2) الواجهة في `siro_gl_platform_interface/lib/siro_gl_platform_interface.dart`. 3) التنفيذ في `method_channel_siro_gl.dart`. 4) `case` في `SiroMapController.java` و`SiroMapController.swift`. 5) تنفيذ الويب في `siro_gl_web/lib/src/siro_web_gl_platform.dart`. |
| خاصية طبقة أو مصدر | عدّل `scripts/templates/` أو `scripts/lib/generate.dart`، ثم `melos run generate`. ما تعدّل الملفات الناتجة. |
| واجهة الـ native لـ Android | `siro_gl/android/src/main/java/com/siro/gl/` (الـ view في `SiroMapFactory.java`، والـ builder في `SiroMapBuilder.java`). |
| واجهة الـ native لـ iOS | `siro_gl/ios/siro_gl/Sources/siro_gl/` (الـ view في `SiroMapFactory.swift`، والـ controller في `SiroMapController.swift`). |
| الهيدرات والشبكة | `SiroHeadersProtocol.swift` و`SiroCustomHeaders.swift` (iOS)، و`SiroCustomHttpInterceptor.java` و`SiroHttpRequestUtil.java` و`SiroNetworkStats.java` (Android). |
| الكاش والأوفلاين | `OfflineManagerUtils.swift` و`OfflineChannelHandler.swift` (iOS)، و`OfflineManagerUtils.java` و`OfflineChannelHandlerImpl.java` (Android)، و`siro_gl/lib/src/offline_region.dart`. |
| الأمثلة | `siro_gl_example/lib/examples/` (مجموعات: basics، camera، interaction، annotations، layers، advanced). |
