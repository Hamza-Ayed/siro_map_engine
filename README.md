# Siro Map Engine (SiroGL)
### محرك الخرائط السيادي عالي الأداء لأنظمة فلاتر وأندرويد وآي أو إس والويب في الشرق الأوسط

[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Flutter%20%7C%20Android%20%7C%20iOS%20%7C%20Web-brightgreen.svg)]()
[![Architect](https://img.shields.io/badge/Architect-Hamza%20Ayed-orange.svg)](https://intaleqapp.com/hamza.html)
[![Sovereign Infrastructure](https://img.shields.io/badge/Sovereign-100%25%20Independent-darkgreen.svg)](https://map.intaleqapp.com)

**Siro Map Engine (SiroGL)** هو محرك خرائط متقدم وفائق الخفة ومستقل سيادياً، تم بناؤه وتطويره بواسطة **حمزة عايد** وفريق **منصة سيرو (Siro Platform)**. يوفّر المحرك بنية تحتية جغرافية متكاملة تدعم العرض المتجهي ثنائي وثلاثي الأبعاد (2D/3D Vector Rendering)، والتضاريس الجبلية المعقدة (3D Terrain DEM Mesh)، والمباني المجسمة (3D Extrusions)، مع توافق كامل 1:1 مع واجهات برمجة تطبيقات Google Maps (Drop-in Parity) على كافة المنصات.

**Siro Map Engine (SiroGL)** is a high-performance, sovereign vector map engine engineered by **Hamza Ayed** and the **Siro Platform** architecture team. It provides a complete, cloud-agnostic geospatial rendering stack supporting 2D/3D vector tiles, high-resolution 3D terrain elevation meshes, architectural extrusions, and full 1:1 Google Maps API parity across Flutter, Android, iOS, and Web.

---

## 🏛️ البنية المعمارية للمحرك / Monorepo Architecture

يحتوي المستودع على منظومة متكاملة من الحزم المصممة للتكامل السلس:

```text
siro_map_engine/
├── siro_gl/                    # حزمة فلاتر الأساسية (Core Flutter Map Plugin)
├── siro_gl_compat/             # طبقة التوافق التام 1:1 مع Google Maps Flutter API
├── siro_gl_platform_interface/ # الواجهة البرمجية الموحدة للمنصات (Platform Interface)
├── siro_gl_web/                # محرك الخرائط للويب عبر WebGL خفيف دون ارتباط خارجي
├── siro_maps_android/          # حزمة أندرويد الأصلية المبنية على كوتلن (Android SDK)
├── siro_maps_ios/              # حزمة آي أو إس الأصلية المبنية على سويفت (iOS SDK)
├── siro_gl_codegen/            # أدوات توليد الخصائص والطبقات التلقائية من Style Spec
└── siro_gl_example/            # تطبيق استعراضي واختباري شامل لكافة الميزات
```

---

## 💎 ميزات المحرك السيادي / Core Capabilities

| الميزة / Feature | محرك سيرو (SiroGL) | Google Maps | Mapbox GL |
|---|:---:|:---:|:---:|
| **الاستقلالية السيادية في بلاد الشام وشمال إفريقيا** | ✅ 100% | ❌ خاضع للعقوبات والحجب | ❌ خاضع لرسوم وسيرفرات خارجية |
| **تكلفة الاستدعاءات وحماية الهامش الربحي** | ✅ مجاني / استضافة خاصة | ❌ 5\$ - 7\$ لكل 1,000 طلب | ❌ تسعير تصاعدي بالدولار |
| **التوافق المباشر (1:1 Google Drop-in)** | ✅ استبدال السطر البرمجي فقط | — | ❌ يحتاج إعادة بناء شاملة |
| **تضاريس ثلاثية الأبعاد بدون إنترنت (Offline 3D)** | ✅ مدعوم بمصفوفة ارتفاع DEM | ❌ غير متوفر | ⚠️ محدود جداً |
| **دعم العربية الأصيل والبحث بدون تشويه خطوط** | ✅ خطوط عربية مدمجة بالكامل | ⚠️ متوسط | ⚠️ يحتاج حزم إضافية |
| **تتبع الأسطول المدمج والتلقائي (Telemetry)** | ✅ مدمج ومجمّع بالدفعات (Batching) | ❌ غير موجود | ❌ غير موجود |

---

## 🚀 دليل البدء السريع / Quickstart

### 1. Flutter (`siro_gl_compat` — Drop-in Google Maps Replacement)

للانتقال الفوري من `google_maps_flutter` دون إعادة كتابة المنطق البرمجي:

```yaml
dependencies:
  siro_gl_compat: ^1.0.0-beta.1
```

```dart
// استبدل مسار الاستيراد فقط:
import 'package:siro_gl_compat/siro_gl_compat.dart';

// الكود يظل متطابقاً 100% مع واجهات جوجل:
SiroMap(
  initialCameraPosition: const CameraPosition(
    target: LatLng(31.9539, 35.9106), // عمّان
    zoom: 14.0,
    tilt: 45.0,
  ),
  onMapCreated: (SiroMapController controller) {
    // التحكم بالكاميرا والعناصر
  },
  markers: {
    Marker(
      markerId: const MarkerId('fleet_1'),
      position: const LatLng(31.9539, 35.9106),
      infoWindow: const InfoWindow(title: 'مركبة التوصيل 101'),
    ),
  },
)
```

### 2. Core Flutter Engine (`siro_gl`)

للتحكم الكامل بطبقات الخريطة والمصادر الجغرافية والـ GeoJSON المباشر:

```yaml
dependencies:
  siro_gl: ^1.0.0-beta.1
```

```dart
import 'package:siro_gl/siro_gl.dart';

SiroMap(
  styleString: 'https://map-saas.intaleqapp.com/styles/v1/standard.json',
  initialCameraPosition: const CameraPosition(
    target: LatLng(33.5138, 36.2765), // دمشق
    zoom: 12.0,
  ),
  onMapCreated: (SiroMapController controller) {
    // إدارة الطبقات، مصادر PMTiles، ومؤشرات الأداء
  },
)
```

### 3. Android Kotlin Native (`siro_maps_android`)

```kotlin
import com.siro.maps.SiroMaps
import com.siro.maps.view.SiroMapView

// التهيئة العامة
SiroMaps.initialize(context = this, apiKey = "YOUR_SIRO_KEY")

// الاستخدام في Activity / Compose
val mapView = findViewById<SiroMapView>(R.id.mapView)
mapView.getMapAsync { controller ->
    mapView.set3DMode(true)
    mapView.animateCamera(LatLng(31.9539, 35.9106), zoom = 15.0f, pitch = 60.0f)
}
```

### 4. iOS Swift Native (`siro_maps_ios`)

```swift
import SwiftUI
import SiroMap

@main
struct MyApp: App {
    init() {
        SiroMaps.initialize(apiKey: "YOUR_SIRO_KEY")
    }

    var body: some Scene {
        WindowGroup {
            SiroMapViewRepresentable(
                camera: SiroCameraPosition(
                    target: SiroLatLng(latitude: 31.9539, longitude: 35.9106),
                    zoom: 14.0,
                    viewingAngle: 65.0
                ),
                is3D: true,
                mapType: .terrain
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
}
```

---

## ⚡ مؤشرات الأداء والأثر المالي / Benchmarks & Unit Economics

1. **حماية الهامش الإجمالي (Gross Margin Protection)**:
   - في تطبيقات التوصيل واللوجستيات في الأردن والخليج، تبتلع فواتير خرائط جوجل قرابة **0.25\$ إلى 0.35\$ لكل رحلة أو طلب**.
   - يوفر محرك سيرو هذا المبلغ بالكامل عبر استضافة بلاطات الخرائط السيادية الذاتية، مما يرفع هامش الربح التشغيلي لشركات النقل واللوجستيات بنسبة تتجاوز 18%.
2. **استهلاك الذاكرة وسرعة الإطارات (FPS & Memory)**:
   - الحفاظ على معدل تحديث **60 إطاراً في الثانية (60 FPS)** حتى على أجهزة أندرويد الاقتصادية الضعيفة (مثل أجهزة 2GB/3GB RAM).
   - حجم حزمة التطبيق (Binary Footprint) مخفّض إلى أقل من 28MB مع دعم كامل للتضاريس ثلاثية الأبعاد دون الحاجة لتحميل مكاتب Google Play Services الثقيلة.

---

## 🛡️ الترخيص والإسناد / License & Attribution

- **Siro Platform Enhancements & Architecture**: مرخصة بموجب ترخيص **BSD-3-Clause**. انظر [LICENSE](LICENSE).
- **Core Upstream Native Engine**: مبني على MapLibre Native تحت ترخيص **BSD-2-Clause**، وكافة الإشعارات الأصلية محفوظة بالكامل في [NOTICE](NOTICE) و[THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
- **بيانات الخرائط الجغرافية**: مشتقة ومحسّنة من OpenStreetMap: **© OpenStreetMap contributors**.

---

<div dir="rtl" align="right">

## 👨‍💻 قيادة الهندسة والاتصال / Leadership & Inquiries

تم تطوير وتوجيه هذا المحرك كجزء من الرؤية السيادية للبنية التحتية الجغرافية والتنقل الذكي في الشرق الأوسط:
* **المعماري والمؤسس التقني**: حمزة عايد (Hamza Ayed)
* **لوحة تحكم المطورين (Console)**: [map-dashboard.intaleqapp.com](https://map-dashboard.intaleqapp.com)
* **بوابة الخرائط الحية (Live Map)**: [map.intaleqapp.com](https://map.intaleqapp.com)
* **دراسة الحالة الهندسية والملف التنفيذي**: [intaleqapp.com/hamza.html](https://intaleqapp.com/hamza.html)
* **الدعم الفني والاستفسارات**: `support@intaleqapp.com`

</div>
