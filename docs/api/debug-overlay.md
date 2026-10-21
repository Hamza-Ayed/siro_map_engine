# لوحة التجربة / Debug overlay

```dart
SiroMap(styleString: '...', debugOverlay: true);
```

تعرض: FPS (فريمات Flutter فقط)، وعدد طلبات الخريطة، وحجم قاعدة الأوفلاين. للتجربة فقط.
Shows: FPS (Flutter frames only), the map's request count, and the offline database size. For tuning only.

FPS هون ما هو FPS الخريطة: الخريطة ترسم بشكل native. FPS الخريطة يحتاج PF-01.
The FPS here is not the map's FPS: the map draws natively. The map's own FPS needs PF-01.
