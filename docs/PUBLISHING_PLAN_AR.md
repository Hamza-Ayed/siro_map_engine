# خطة نشر حزم Siro Maps (Beta)

الحالة في 2026-10-23. كل خطوة نشر خارجية تحتاج موافقة صريحة قبل التنفيذ. هذه الوثيقة لا تنفّذ أي نشر.

## 1. الحالة الحالية

| الحزمة | المنصة | الهدف | الحالة |
|---|---|---|---|
| `siro_gl_platform_interface` 0.27.1 | pub.dev | Flutter | لها LICENSE، جاهزة للتجربة |
| `siro_gl_web` 0.27.1 | pub.dev | Flutter | لها LICENSE، تعتمد على `siro_gl_platform_interface` |
| `siro_gl` 0.27.1 | pub.dev | Flutter | لها LICENSE، تعتمد على الحزمتين أعلاه |
| `siro_gl_compat` 0.1.0 | pub.dev | Flutter | **لا يوجد LICENSE ولا CHANGELOG**، وpubspec فيه `publish_to: none` |
| `siro_maps_android` 1.0.0 | Maven | Android | تنشر إلى `mavenLocal` فقط |
| `siro_maps_ios` | SwiftPM | iOS | **Package.swift داخل مجلد فرعي من المستودع** |
| المحرك الأصلي Android `siro-native-android-*` 13.7.1-siro.1 | GitHub Release، و`mavenLocal` | يعتمد عليه `siro_gl` وسيعتمد عليه `siro_maps_android` | لا يوجد مستودع Maven عام |

**أسماء pub.dev:** `siro_gl` و`siro_gl_compat` غير مأخوذين (الاستعلام عن `pub.dev/api/packages/<name>` يرجع 404). لم أتحقق من بقية الأسماء بعد.

## 2. عوائق يجب حلها قبل أي نشر

### 2.1 المحرك الأصلي على Android غير متاح لأي مطوّر خارجي
- `siro_gl/android/build.gradle` يبحث عن `com.siro.native:siro-native-android-opengl-<variant>:13.7.1-siro.1` في `google()` و`mavenCentral()` و`mavenLocal()`.
- النسخة الوحيدة الموجودة هي GitHub Release، وهي غير مضافة كمستودع Maven في ملفات البناء.
- **المطلوب:** اختيار مستودع Maven عام، مثل GitHub Packages (القراءة العامة ممكنة) أو مستضاف خاص. Maven Central يحتاج التحقق من نطاق، فهو أبطأ.
- **القرار مطلوب منك.**

### 2.2 `siro_maps_android` يعتمد على `mavenLocal`
- `publishReleasePublicationToMavenLocal` يكفي للتجربة المحلية فقط.
- بعد حل 2.1، ينشر `com.siro.maps:siro-maps-android` إلى المستودع نفسه، وتُحدَّث `api` الخاصة بالمحرك إلى الإصدار المنشور.

### 2.3 iOS لا يُستهلك من هذا المستودع مباشرة
- SwiftPM يقرأ `Package.swift` من جذر المستودع. مجلد `siro_maps_ios` داخل `siro_map_engine`، فلا يمكن إضافته بالرابط.
- **الحل المقترح:** مستودع منفصل `Hamza-Ayed/siro-maps-ios` يحتوي `Package.swift` و`Sources` و`Tests` فقط، مع tag مثل `1.0.0-beta.1`. يُنسخ بـ `git subtree split` أو سكربت نسخ من هذا المستودع.
- الاعتماد على MapLibre `6.28.0` من `maplibre-gl-native-distribution` مثبّت بإصدار دقيق، وهذا مقبول.
- **القرار مطلوب منك.**

### 2.4 تضارب الإصدارات
- `siro_gl/pubspec.yaml` يقول `0.27.1`، وREADME يقول `1.0.0-dev`، وCHANGELOG غير متطابق معه.
- `siro_maps_android/build.gradle` يقول `1.0.0`، والمحرك `13.7.1-siro.1`.
- **المقترح:** كل حزم Flutter تبدأ بـ `1.0.0-beta.1` (إصدار prerelease يقبله pub.dev، ولا يفرض ثباتاً). وحزم Android وiOS تبدأ بـ `1.0.0-beta.1`. نوحّد README وCHANGELOG عليه.

### 2.5 حزمة `siro_gl_compat` غير جاهزة لـ pub.dev
- تحتاج LICENSE (BSD-3-Clause مثل الحزم الأخرى)، وCHANGELOG، وإزالة `publish_to: none`.
- تعتمد على `siro_gl` بالمسار `path: ../siro_gl`. على pub.dev يجب أن تُعدَّل إلى `siro_gl: ^1.0.0-beta.1` بعد نشر `siro_gl`.

## 3. ترتيب النشر

ترتيب الاعتماد: المحرك الأصلي، ثم حزم Android وiOS، ثم حزم Flutter من الأسفل إلى الأعلى.

1. **حسم 2.1 و2.3 و2.4 و2.5** (قرارات وتعديلات بدون نشر).
2. **نشر المحرك الأصلي** إلى المستودع المختار (إجراء خارجي، يحتاج موافقتك).
3. **نشر `siro_maps_android`** إلى Maven بعد نشر المحرك.
4. **إنشاء مستودع iOS** ووضع tag `1.0.0-beta.1` (إجراء خارجي، يحتاج موافقتك).
5. **pub.dev** بهذا الترتيب: `siro_gl_platform_interface` ثم `siro_gl_web` ثم `siro_gl` ثم `siro_gl_compat`.
6. **تحقق من النشر:** مشروع Flutter جديد خارج المستودع يعتمد على الحزم من pub.dev، ويبني على Android وiOS، ويعمل مثال البحث والمسار.

## 4. أوامر مقترحة (لا تُنفَّذ قبل الموافقة)

تحقق بدون نشر:

```bash
cd packages/siro_map_engine/siro_gl_platform_interface && dart pub publish --dry-run
cd ../siro_gl_web && dart pub publish --dry-run
cd ../siro_gl && dart pub publish --dry-run
```

النشر الفعلي (يحتاج موافقتك، ولا يُرجَع عنه):

```bash
cd packages/siro_map_engine/siro_gl_platform_interface && dart pub publish
```

## 5. ما يحتاج موافقتك صراحةً

- إنشاء أو اختيار مستودع Maven.
- نشر المحرك الأصلي ونشر `siro_maps_android`.
- إنشاء مستودع `siro-maps-ios` وإضافة tag.
- نشر أي حزمة إلى pub.dev. النشر لا يمكن التراجع عنه، ويبقى الإصدار مرئياً حتى لو أُلغي.
- تغيير `publish_to` في `siro_gl_compat` وتعديل الإصدارات.

## 6. ما لا يشمله النشر

- iOS لم يُختبر على جهاز حقيقي، ولم يُختبر إلا على iOS 26.0 في المحاكي.
- الفجوات المعروفة موجودة في README كل حزمة، ولا يعالجها النشر.
- Infinix لم يُختبر، والبحث بالعربية لم يُختبر على الجهاز.
