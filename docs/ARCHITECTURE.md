# خريطة الكود (محرك سيرو)

> وثيقة للمطوّرين. بتوصف الطبقات والقنوات وكل اسم طريقة بين Dart والمنصات، وبتشرح مولّد الكود، وبتسجّل الفجوات المعروفة.
> الجدول بالقسم 4 **مولّد من الكود نفسه** بـ `grep` (انظر القسم 4)، مش مكتوب يدوياً.

## 1. الطبقات

```
تطبيق Dart
   │
maplibre_gl                       واجهة عامة: SiroMap، MapLibreMapController، دوال global
   │                              (lib/src/controller.dart، global.dart، maplibre_map.dart)
   │
maplibre_gl_platform_interface    عقد مجرّد MapLibrePlatform + تنفيذ القناة
   │                              (method_channel_maplibre_gl.dart، global_platform.dart)
   │
   ├── Method Channel ─────────── Android: Java/Kotlin            iOS: Swift
   │                              GlobalMethodHandler.java         MapLibreMapsPlugin.swift
   │                              MapLibreMapController.java       MapLibreMapController.swift
   │                                    │                                 │
   │                              org.maplibre.android.*           MLNMapView (MapLibre iOS)
   │                              (المحرك الأصلي، Maven)           (المحرك الأصلي، SPM/pod)
   │
   └── Web (JS interop) ──────── maplibre_gl_web: maplibre_web_gl_platform.dart
                                  └─ maplibre-gl-js (JS، مش قناة)
```

- **الدوال العامة على مستوى التطبيق** (`setHttpHeaders`، `setOffline`، `getNetworkStats`...) بتمشي على قناة الـ global، وهي `plugins.flutter.io/maplibre_gl`.
- **أوامر كل خريطة** بتمشي على قناة خاصة بكل خريطة، `plugins.flutter.io/maplibre_gl_<id>`.
- **Web ما بيستخدم قنوات.** بيحمّل `maplibre-gl-js` ويتعامل معه بـ JS interop.

> ملاحظة: أسماء القنوات الحالية هي الأصلية (`plugins.flutter.io/...`). تغيير الأسماء لـ `com.siro.gl/...` بيصير بـ ID-03 و ID-04 و ID-05. هاد الملف بيتحدّث حينها.

## 2. القنوات

| القناة | معرّفة بـ | الاستخدام |
|---|---|---|
| `plugins.flutter.io/maplibre_gl` | `maplibre_gl/lib/src/global.dart`، `maplibre_gl_platform_interface/lib/src/global_platform.dart` | دوال على مستوى التطبيق: الكاش، الأوفلاين، الهيدرات، عداد الشبكة، `preWarm` |
| `plugins.flutter.io/maplibre_gl_<id>` | `maplibre_gl_platform_interface/lib/src/method_channel_maplibre_gl.dart` (سطر 134) | كل أوامر الخريطة: الكاميرا، الطبقات، المصادر، الـ annotations، الأحداث |
| `plugins.flutter.io/maplibre_gl` على الـ native | Android: `MapLibreMapsPlugin.java` (سطر 46 و52)، وتوزيع الأوامر في `GlobalMethodHandler.java`. iOS: `MapLibreMapsPlugin.swift` (سطر 12 و24) | استقبال القناة العامة |
| `plugins.flutter.io/maplibre_gl_<id>` على الـ native | Android: `MapLibreMapController.java` (سطر 306). iOS: `MapLibreMapController.swift` (سطر 129-130) | أوامر كل خريطة |

## 3. مولّد الكود

المولّد في `scripts/` (حزمة `scripts` بالـ workspace، واسمها `maplibre_code_gen` لحد ID-02).

- **المدخل:** `scripts/input/style.json` (نسخة من مواصفة MapLibre style، والإصدار بـ `style_spec_version.txt`).
- **الكود:** `scripts/lib/generate.dart` بيقرأ المدخل وبيشغّل القوالب بـ `mustache_template`، وبيعمل `dart format` على الناتج.
- **التشغيل:** `melos run generate` (من جذر الحزمة، مع `--no-select` لو خارج التيرمنال).
- **التحقق:** `melos run check-style-spec` بيتأكد إن `style.json` مطابق للإصدار المثبّت.

| القالب (`scripts/templates/`) | الناتج |
|---|---|
| `LayerPropertyConverter.java.template` | `maplibre_gl/android/.../LayerPropertyConverter.java` |
| `LayerPropertyConverter.swift.template` | `maplibre_gl/ios/.../LayerPropertyConverter.swift` |
| `layer_expressions.dart.template` | `maplibre_gl/lib/src/layer_expressions.dart` |
| `layer_properties.dart.template` | `maplibre_gl/lib/src/layer_properties.dart` |
| `layer_tools.dart.template` | `maplibre_gl_web/lib/src/layer_tools.dart` |
| `source_properties.dart.template` | `maplibre_gl_platform_interface/lib/src/source_properties.dart` |

الملفات الناتجة مكتوب فيها "generated"، ولا تتعدّل يدوياً. التعديل بيكون على القالب أو على `generate.dart`. `SourcePropertyConverter.swift/java` ما بيتولّدوا (يدويين).

## 4. جدول أسماء الطرق (مولّد)

**الأرقام (تم التحقق بـ grep):**

| المصدر | عدد الأسماء المميّزة |
|---|---:|
| Dart (`invokeMethod` / `invokeMapMethod` / `invokeListMethod` وhelper `_getStyleObjectProperties`) | 95 |
| Android (`switch (call.method)` و`switch (methodCall.method)` في `GlobalMethodHandler.java` و`MapLibreMapController.java`) | 94 |
| iOS (`switch methodCall.method` / `switch call.method` في `MapLibreMapsPlugin.swift` و`MapLibreMapController.swift`) | 89 |
| الاتحاد (كل الأسماء) | **95** (= 100% من أسماء Dart، وكل أسماء المنصات موجودة في Dart) |

الجدول تحت فيه صف لكل اسم من الاتحاد (95 صف). العمود "ملاحظة" بيسجّل الفجوات. `—` يعني ما في case بهاي المنصة.

| الطريقة | Dart | Android | iOS | ملاحظة |
|---|---|---|---|---|
| `backgroundLayer#add` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `camera#animate` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `camera#ease` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `camera#move` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `circleLayer#add` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `clearAmbientCache` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `colorReliefLayer#add` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `deleteOfflineRegion` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `downloadOfflineRegion` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `downloadOfflineRegion#setup` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `fillExtrusionLayer#add` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `fillLayer#add` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `getListOfRegions` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `getNetworkStats` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `getOfflineDatabasePath` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `getOfflineRegionStatus` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `heatmapLayer#add` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `hillshadeLayer#add` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `installOfflineMapTiles` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `layer#getVisibility` | method_channel_maplibre_gl.dart | — | — | Dart فقط: ما في case بأي منصة نيتيف. الاستدعاء بيرجع `notImplemented`. |
| `layer#setProperties` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `layer#setVisibility` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `lineLayer#add` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `locationComponent#getLastLocation` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `locationComponent#setManualLocation` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `locationComponent#setTrackingCameraOptions` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#clearAmbientCache` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#editGeoJsonSource` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#editGeoJsonUrl` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#forceOnlineMode` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#getCustomHeaders` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#getMetersPerPixelAtLatitude` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#getStyle` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#getTelemetryEnabled` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#getVisibleRegion` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#invalidateAmbientCache` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#matchMapLanguageWithDeviceDefault` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#pause` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#queryCameraPosition` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#queryRenderedFeatures` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#querySourceFeatures` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#resume` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#setCameraBounds` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#setCustomHeaders` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#setLayerFilter` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#setMapLanguage` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#setMaximumFps` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#setTelemetryEnabled` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#takeSnapshot` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#toLatLng` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#toScreenLocation` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#toScreenLocationBatch` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#update` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#updateContentInsets` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#updateMyLocationTrackingMode` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `map#waitForMap` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `mergeOfflineRegions` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `pauseOfflineRegionDownload` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `preWarm` | global_platform.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `rasterLayer#add` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `resetNetworkStats` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `resetOfflineDatabase` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `resumeOfflineRegionDownload` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `setHttpHeaders` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `setNetworkStatsEnabled` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `setOffline` | global.dart | GlobalMethodHandler.java | — | iOS: ما في case. Android بيدعمها. |
| `setOfflineMaxConcurrentRequests` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `setOfflineTileCountLimit` | global.dart | GlobalMethodHandler.java | MapLibreMapsPlugin.swift |  |
| `source#addGeoJson` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `source#getClusterChildren` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `source#getClusterExpansionZoom` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `source#getClusterLeaves` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `source#getFeatureState` | method_channel_maplibre_gl.dart | MapLibreMapController.java | — | iOS: ما في case (feature state على iOS لسا ما انعمل). |
| `source#removeFeatureState` | method_channel_maplibre_gl.dart | MapLibreMapController.java | — | iOS: ما في case (نفس السبب). |
| `source#setFeature` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `source#setFeatureState` | method_channel_maplibre_gl.dart | MapLibreMapController.java | — | iOS: ما في case (نفس السبب). |
| `source#setGeoJson` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#addImage` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#addImageSource` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#addLayer` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#addLayerBelow` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#addSource` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#getFilter` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#getLayerIds` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#getLayerProperties` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#getSourceIds` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#getSourceProperties` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#removeLayer` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#removeSource` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#setFilter` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#setLight` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#setStyle` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `style#updateImageSource` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `symbolLayer#add` | method_channel_maplibre_gl.dart | MapLibreMapController.java | MapLibreMapController.swift |  |
| `updateOfflineRegionMetadata` | global.dart | GlobalMethodHandler.java | — | iOS: ما في case في الـ switch الرئيسي. |

## 5. الفجوات المعروفة (من الفحص أعلاه)

1. **`layer#getVisibility`**: موجودة في الـ platform interface بس، ما في case بأي منصة نيتيف. الاستدعاء بيرجع `notImplemented` على Android (`MapLibreMapController.java`، سطر 3124) وبيرجع `FlutterMethodNotImplemented` على iOS (`MapLibreMapController.swift`، سطر 1659). الإصلاح: إضافة الـ case على المنصتين، أو حذف الدالة لو ما بنحتاجها.
2. **`setOffline` على iOS**: الدالة العامة بتستدعيها، وما في case على iOS. قبل ما تعتمد على `setOffline` بـ iOS، اتحقق.
3. **feature state على iOS** (`source#getFeatureState`، `source#setFeatureState`، `source#removeFeatureState`): ما انعملوش على iOS. المثال بيوثّق هاد (FeatureStateExample مش مدعوم على iOS).
4. **`updateOfflineRegionMetadata` على iOS**: ما في case في الـ switch الرئيسي.

هاي الفجوات ما اتصلحتش في F-04 (الوثيقة فقط). كل وحدة بتحتاج قرار أو تغيير كود منفصل.

## 6. أين أعدّل ماذا

| بدي أضيف... | الخطوات |
|---|---|
| دالة عامة (على مستوى التطبيق) | 1) الدالة في `maplibre_gl/lib/src/global.dart`. 2) `case` في `GlobalMethodHandler.java` و`MapLibreMapsPlugin.swift`. |
| أمر على خريطة (الكاميرا، طبقة، مصدر) | 1) الدالة على `MapLibreMapController` في `maplibre_gl/lib/src/controller.dart`. 2) الواجهة في `maplibre_gl_platform_interface/lib/src/maplibre_gl_platform_interface.dart`. 3) التنفيذ في `method_channel_maplibre_gl.dart`. 4) `case` في `MapLibreMapController.java` و`MapLibreMapController.swift`. 5) تنفيذ الويب في `maplibre_gl_web/lib/src/maplibre_web_gl_platform.dart`. |
| خاصية طبقة أو مصدر | عدّل `scripts/templates/` أو `scripts/lib/generate.dart`، ثم `melos run generate`. ما تعدّل الملفات الناتجة. |
| واجهة الـ native لـ Android | `maplibre_gl/android/src/main/java/org/maplibre/maplibregl/` (الـ view في `MapLibreMapFactory.java`، والـ builder في `MapLibreMapBuilder.java`). |
| واجهة الـ native لـ iOS | `maplibre_gl/ios/maplibre_gl/Sources/maplibre_gl/` (الـ view في `MapLibreMapFactory.swift`، والـ controller في `MapLibreMapController.swift`). |
| الهيدرات والشبكة | `MapLibreHeadersProtocol.swift` و`MapLibreCustomHeaders.swift` (iOS)، و`MapLibreCustomHttpInterceptor.java` و`MapLibreHttpRequestUtil.java` و`MapLibreNetworkStats.java` (Android). |
| الكاش والأوفلاين | `OfflineManagerUtils.swift` و`OfflineChannelHandler.swift` (iOS)، و`OfflineManagerUtils.java` و`OfflineChannelHandlerImpl.java` (Android)، و`maplibre_gl/lib/src/offline_region.dart`. |
| الأمثلة | `maplibre_gl_example/lib/examples/` (مجموعات: basics، camera، interaction، annotations، layers، advanced). |
