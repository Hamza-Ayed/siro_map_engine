# حجم المحرك الأصلي: خط الأساس / Native size baseline

قياس واحد للمقارنة لاحقاً (N-09). كل رقم مأخوذ من الملف الفعلي، وما في بناء جديد.
One measurement to compare against later (N-09). Every number comes from the real file. Nothing was built for this.

| الملف / Artifact | الإصدار / Version | الحجم / Size | ملاحظة / Note |
|---|---|---:|---|
| `android-sdk-opengl-13.5.0.aar` (المحرك الأصلي لأندرويد / Android native engine) | 13.5.0 | 164,655,352 bytes (≈157 MiB) | كل الـ ABIs، 150 ملف |
| `MapLibre.xcframework` (iOS، مجلد الحزمة المحلي / local SwiftPM checkout) | 6.28.0 | ≈25 MB على القرص | الحجم الكامل للـ xcframework بكل الـ slices، تم قياسه بـ `du` |

ملاحظات / Notes:
- قياس الـ AAR لكل ABI (N-09) يحتاج فك الضغط والمقارنة لكل `jni/<abi>/`. لم يتم بعد.
- تعطيل الميزات عبر خيارات البناء (N-09) يحتاج بناء المحرك من المصدر (N-02، N-03)، وهذا بعد موافقتك على الأدوات.
- المرجع للمقارنة لاحقاً هو هذه الأرقام.
