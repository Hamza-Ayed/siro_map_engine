# Siro GL examples

Sample app for `siro_gl` and `siro_gl_compat`. It has 33 examples in 6 categories: basics, camera, interaction, annotations, layers and sources, and advanced.

## Run

```bash
flutter pub get
flutter run --dart-define=SIRO_PUBLIC_KEY=<your publishable key>
```

The key is needed only by the route and search examples. Other examples run without it. Never commit the key.

## Verified

- Android: itel A665L (physical device). All 33 examples opened, and a scripted run tapped their buttons. No crash was seen. The Google-compatible example's search and route worked with the key. Logcat capture was empty, so crash detection relied on the app staying in the foreground.
- iOS: iPhone 17 Pro simulator (iOS 26.0), per `siro_maps_ios`. Not run on a physical iPhone.

Known limits are in each package's README: [siro_gl](../siro_gl/README.md), [siro_gl_compat](../siro_gl_compat/README.md), [siro_maps_android](../siro_maps_android/README.md) and [siro_maps_ios](../siro_maps_ios/README.md).
