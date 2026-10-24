# Siro GL

**Siro GL** خريطة لـ Flutter مبنية على MapLibre، من إنتاج Siro Maps. الاسم والحزم والقنوات والتوثيق كلها سيرو. المحرك الأصلي على الموبايل والويب هو MapLibre، ونسخته مثبّتة بالملف `THIRD_PARTY_LICENSES.md`.

**Siro GL** is a Flutter map library from Siro Maps, built on MapLibre. The package names, channels and documentation are Siro's. The native engines on mobile and web are MapLibre's, pinned in `THIRD_PARTY_LICENSES.md`.

---

## الحالة / Status

**Beta.** الفجوات المعروفة موجودة في README كل حزمة. / Known gaps are listed in each package's README.

| المنصة / Platform | المحرك / Engine | الحالة / Status |
|---|---|---|
| Android | MapLibre Android 13.5.0 | يبني ويعمل على جهاز فعلي (itel A665L) ✅ |
| iOS | MapLibre iOS 6.28.0 | يبني ويعرض الخريطة على المحاكي ✅ |
| Web | maplibre-gl-js (الإصدار في `siro_gl_web/lib/src/js_loader.dart`) | يبني ويعرض الخريطة في Chrome ✅ |

النسخة `1.0.0-dev`، مبنية على `flutter-maplibre-gl` 0.27.1. تفاصيل التغييرات بـ [CHANGELOG.md](../CHANGELOG.md).
Version `1.0.0-dev`, based on `flutter-maplibre-gl` 0.27.1. Changes are in [CHANGELOG.md](../CHANGELOG.md).

## التثبيت / Installation

الحزمة منشورة على [pub.dev](https://pub.dev/packages/siro_gl) كنسخة Beta `1.0.0-beta.1`:

The package is published on [pub.dev](https://pub.dev/packages/siro_gl) as the Beta `1.0.0-beta.1`:

```yaml
dependencies:
  siro_gl: ^1.0.0-beta.1
```

## الاستخدام / Usage

```dart
import 'package:flutter/material.dart';
import 'package:siro_gl/siro_gl.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SiroMap(
      styleString: 'https://map-saas.intaleqapp.com/styles/v1/standard.json',
      initialCameraPosition: const CameraPosition(
        target: LatLng(31.9539, 35.9106),
        zoom: 11,
      ),
      onMapCreated: (SiroMapController controller) {
        // Use the controller for camera moves, layers and sources.
      },
    );
  }
}
```

## القنوات / Channels

الأسماء في الكود وفي الـ native متطابقة، وكلها ثوابت بملف واحد:
`siro_gl_platform_interface/lib/src/channels.dart`

| القناة / Channel | الاستخدام / Use |
|---|---|
| `com.siro.gl/global` | دوال على مستوى التطبيق (الكاش، الهيدرات، عداد الشبكة) |
| `com.siro.gl/map_<id>` | أوامر كل خريطة |
| `com.siro.gl/map` | نوع الـ platform view |

## عداد الشبكة / Network counter

`setNetworkStatsEnabled(true)` ثم `getNetworkStats()` بيعطيك عدد طلبات الخريطة (tiles والستايل والـ sprites والـ glyphs). على iOS ما فيه عدّ للبايتات. التفاصيل بـ [CHANGELOG.md](../CHANGELOG.md).

## التطوير / Development

```bash
# from the package root
flutter pub get
tool/ci.sh                  # format, analyze, tests, codegen check, builds
SKIP_BUILD=1 tool/ci.sh     # tests only
```

التوليد من `style.json` بـ `melos run generate` (انظر [siro_gl_codegen/README.md](../siro_gl_codegen/README.md)).
The layer and source code is generated from `style.json` with `melos run generate` (see [siro_gl_codegen/README.md](../siro_gl_codegen/README.md)).

الوثائق الداخلية: [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) (خريطة الكود)، و[BENCHMARK.md](../BENCHMARK.md) (القياسات).
Internal docs: [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) (code map) and [BENCHMARK.md](../BENCHMARK.md) (measurements).

## الترخيص والإسناد / License and attribution

- حقوق Siro Maps على تعديلاتنا: BSD-3-Clause. انظر [LICENSE](LICENSE).
- كل مكوّن خارجي بترخيصه: [THIRD_PARTY_LICENSES.md](../THIRD_PARTY_LICENSES.md)، ونصوص الإشعارات الأصلية بـ [NOTICE](../NOTICE).
- بيانات الخريطة من OpenStreetMap: **© OpenStreetMap contributors**.

Siro Maps' changes are licensed BSD-3-Clause (see [LICENSE](LICENSE)). Each third-party component keeps its own license, listed in [THIRD_PARTY_LICENSES.md](../THIRD_PARTY_LICENSES.md) and [NOTICE](../NOTICE). Map data is © OpenStreetMap contributors.

## المساهمة والأمان / Contributing and security

- المساهمة: [CONTRIBUTING.md](../CONTRIBUTING.md)
- الإبلاغ عن ثغرة: [SECURITY.md](../SECURITY.md)
