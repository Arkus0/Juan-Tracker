# Baseline de Rendimiento Android

Este flujo deja una medicion reproducible para arranque y un paso claro para analizar jank.

## 1) Startup trace (automatica)

```powershell
pwsh ./scripts/perf_android_profile.ps1
```

Opcional con dispositivo especifico:

```powershell
pwsh ./scripts/perf_android_profile.ps1 -DeviceId emulator-5554
```

Salida esperada:

- Log en `build/perf/startup_run_YYYYMMDD_HHMMSS.log`
- JSON (si Flutter lo genera) en `build/perf/start_up_info_YYYYMMDD_HHMMSS.json`

## 2) Jank y frame drops (manual)

1. Ejecutar:

```powershell
flutter run -d <device_id> --profile --trace-skia
```

2. Abrir DevTools > Performance.
3. Recorrer siempre las mismas 3 rutas para comparar:
   - Diario (`/nutrition/diary`)
   - Busqueda de alimentos (`/nutrition/foods`)
   - Entrenamiento (`/training`)
4. Guardar timeline y capturar:
   - Frame build/raster p95 y p99
   - Numero de janky frames
   - Duracion de operaciones costosas visibles

## 3) Regla de comparacion

- Mismo dispositivo/emulador
- Mismo modo (`--profile`)
- Mismo recorrido en app
- Misma version de datos locales cuando sea posible

## 4) KPI minimo sugerido

- Startup: reducir tiempo total de primer frame vs baseline
- Scroll/listas: bajar janky frames en pantallas top (Diario, Foods)
- Interaccion: evitar bloqueos > 100 ms en acciones frecuentes

