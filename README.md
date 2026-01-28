# Juan Tracker

Proyecto Flutter Android-first con Riverpod 3 y estructura limpia mínima.

## Ejecutar en Android

1. Conecta un dispositivo Android o inicia un emulador.
2. Ejecuta:

```bash
flutter run -d android
```

## Ejecutar en Web (local)

```bash
flutter run -d chrome
```

## Codegen (Drift)

Si editas tablas o la clase `@DriftDatabase`, genera los archivos:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Pasos manuales (Android)

- Revisa permisos de camara/microfono si activas OCR o voz.
- Si usas timers con notificaciones, valida permisos y servicios en Android.

## Build web (release)

```bash
flutter build web --release
```

El artefacto final queda en `build/web`.
# Juan-Tracker
