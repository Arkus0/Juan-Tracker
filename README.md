# Juan Tracker

[![Android CI](https://github.com/Arkus0/Juan-Tracker/actions/workflows/android-ci.yml/badge.svg)](https://github.com/Arkus0/Juan-Tracker/actions/workflows/android-ci.yml) [![Preview Web](https://github.com/Arkus0/Juan-Tracker/actions/workflows/preview-web.yml/badge.svg)](https://github.com/Arkus0/Juan-Tracker/actions/workflows/preview-web.yml)

Proyecto Flutter Android-first para tracking personal de nutrición y entrenamiento, con Riverpod 3 y una arquitectura limpia mínima. ✅

## TL;DR
App Android-first para registrar comida y entrenamientos, analizar progreso y usar OCR/voz para entrada rápida.

---

## Características
- Diario de alimentos con búsqueda, porciones y soporte para recetas; totales calóricos diarios y objetivos (TDEE). 🔢
- Registro de peso corporal con historial y gráficos. ⚖️
- Resumen de metas calóricas (TDEE) y seguimiento de macronutrientes. 🥗
- Rutinas y sesiones de entrenamiento con registro de ejercicios, series (peso, repeticiones, RPE) y deshacer última serie. 🏋️‍♂️
- Entrada por voz para agilizar registro de sets y pesos. 🗣️
- Importación de rutinas vía OCR (ML Kit) desde imágenes/PDF. 📸
- Temporizador de descanso y notificaciones locales durante sesiones. ⏱️🔔
- Análisis visual con gráficos y calendario para revisar progreso. 📈
- Persistencia local con Drift (SQLite) y state management con Riverpod. 🗄️

## Flujo de uso (ejemplo)
1. Abre la app (pantalla inicial `EntryScreen` → `HomeScreen`).
2. En `Diario` añade alimentos o registra peso (`DiaryScreen`).
3. Selecciona `ENTRENAR` y elige una rutina o crea una sesión libre (`TrainingHomeScreen`).
4. Inicia `TrainingSessionScreen`, registra series manualmente o por voz, usa el temporizador de descanso.
5. Revisa el historial y gráficos en la sección de análisis.

---

## Instalación
- Requisitos: Flutter 3.10.7 (comprueba con `flutter --version`).
- Instala dependencias:

```bash
flutter pub get
```

## Ejecutar
### Android
1. Conecta un dispositivo Android o inicia un emulador.
2. Ejecuta:

```bash
flutter run -d android
```

### Web (local)

```bash
flutter run -d chrome
```

## Codegen (Drift)
- Generar código tras modificar tablas o anotaciones:

```bash
dart run build_runner build --delete-conflicting-outputs
```

- Modo watch (desarrollo):

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Tests y calidad
- Ejecutar tests unitarios y de widgets:

```bash
flutter test
```

- Analizar y formatear antes de commitear:

```bash
flutter analyze

dart format lib/ test/
```

- Checklist recomendado antes de abrir un PR: `flutter analyze`, `flutter test`, `dart format`, `dart run build_runner build --delete-conflicting-outputs`.

## Contribuir
Lee `CONTRIBUTING.md` para el flujo de contribución, checklist y buenas prácticas. 🙌

## Documentación
- Documentación de diseño y porting: `docs/PORTING_SPEC.md` y `docs/TRAINING_MVP_NOTES.md`.
- Información técnica y pautas para agentes: `AGENTS.md`.

---

## Pasos manuales (Android)
- Revisa permisos de cámara/microfono si activas OCR o voz.
- Si usas temporizadores con notificaciones, valida permisos y servicios en Android.

## Build web (release)

```bash
flutter build web --release
```

El artefacto final queda en `build/web`.

---

## Licencia
Este proyecto está bajo la licencia **MIT** — ver el archivo `LICENSE` en la raíz del repositorio.

---

*Última actualización: Enero 2026*
