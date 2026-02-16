# Estrategia de Tamaño Android (Release)

Objetivo: reducir peso de descarga para usuarios Android sin cambiar features.

## 1) Generar APKs por ABI (recomendado para distribución directa)

```powershell
pwsh ./scripts/build_android_split_release.ps1
```

El script genera:

- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

Cada APK incluye solo la arquitectura necesaria, por lo que es bastante más
pequeño que el universal.

## 2) Medir tamaño real arm64 con desglose

```powershell
pwsh ./scripts/build_android_split_release.ps1 -AnalyzeArm64
```

Esto ejecuta además:

```powershell
flutter build apk --release --target-platform android-arm64 --analyze-size
```

y deja el JSON para DevTools en `~/.flutter-devtools/`.

## 3) Recomendación de distribución

- Play Store: usar `AAB` (`flutter build appbundle --release`).
- Entrega manual (QA/beta fuera de Play): usar APK split por ABI.

## 4) KPI de esta optimización

- KPI principal: tamaño del paquete descargado por usuario.
- Esperado: reducción significativa frente a `app-release.apk` universal.

## Baseline actual (15 Feb 2026)

- `app-release.apk` universal: `115.7 MB`
- `app-arm64-v8a-release.apk`: `86.2 MB`
- `app-armeabi-v7a-release.apk`: `79.0 MB`
- `app-x86_64-release.apk`: `89.3 MB`
- `app-release.aab`: `116.9 MB` (Play distribuye splits por dispositivo)
