# Revec QR

Aplicacion Flutter para registro de visitas a equipos de trabajo mediante codigos QR o de barras, pensada para tecnicos de campo y supervisores. Incluye manejo de roles simulado, almacenamiento offline con Hive, captura de ubicacion y un flujo de escaneo enriquecido.

## Credenciales de prueba

| Rol                      | Correo                | Password   |
|--------------------------|-----------------------|------------|
| Técnico (Norte)          | tecnico@revec.com     | qrtech123  |
| Técnica (Sur)            | tecnico.sur@revec.com | qrtech456  |
| Supervisor               | supervisor@revec.com  | qradmin123 |

## QR de prueba
En `docs/qr-codes/` se incluyen QR listos para escanear:
- TM-001: ![TM-001](docs/qr-codes/TM-001.png)
- TM-002: ![TM-002](docs/qr-codes/TM-002.png)
- TM-003: ![TM-003](docs/qr-codes/TM-003.png)

## Requisitos
- Flutter 3.24 (SDK >= 3.8) con soporte para Material 3.
- Dispositivo o emulador con camara funcional para probar el escaneo.
- Permisos de ubicacion habilitados para captar coordenadas.

## Ejecucion
```bash
flutter pub get
flutter run
```

> Sugerencia: al ejecutar en emuladores sin camara fisica, use la opcion de emulacion de codigo de barras disponible en Android Studio o comparta la pantalla con un QR generado.

## Tests y calidad
```bash
flutter analyze
flutter test
```

## Arquitectura y decisiones principales
- **Estado y dependencias:** Riverpod 2.6 con `ProviderScope`, `AsyncNotifier` y overrides por feature.
- **Capas por dominio:** `features/auth` (sesion simulada), `features/visits` (visitas) divididas en `data/domain/presentation`.
- **Persistencia offline:** Hive (`VisitLocalDataSource`, `SessionLocalDataSource`) + `Hive.initFlutter()` en `bootstrap`.
- **Ruteo:** `MaterialApp` con `AppRoutes` (splash -> login -> dashboard -> scanner).
- **Sesion persistente:** login simulado con credenciales locales, almacenamiento en Hive y restauracion automatica.
- **Observabilidad y errores:** `logger` centralizado via Riverpod (`loggerProvider`) que registra advertencias y excepciones en controladores clave.
- **UI/UX:** Material 3, tema personalizado, overlays de escaneo, historial con busqueda, filtros y detalles ampliados.

## Funcionalidades implementadas
- Seleccion de rol mediante login simulado y sesion persistente (tecnico / supervisor).
- Registro de visitas con flujo de escaneo (mobile_scanner), manejo de permisos de camara y geolocalizacion (geolocator + permission_handler).
- Almacenamiento offline de visitas (Hive) con nota opcional, fecha/hora y coordenadas.
- Historial con filtros por periodo (hoy, ultimos 7 dias), filtro por tecnico (supervisor), barra de busqueda y detalles expandibles.
- Mapa embebido (flutter_map + OpenStreetMap) en el detalle de visita cuando existen coordenadas validas.
- Observador Riverpod (`AppProviderObserver`) para trazabilidad durante desarrollo.
- Pruebas unitarias basicas (`session_controller_test`, `visit_registration_controller_test`).

## Limitaciones y mejoras futuras
- Exportacion/backup de visitas a formatos externos.
- Manejo de multiples fotografias o adjuntos por visita.
- Internacionalizacion de textos y soporte completo para modo oscuro.
- Envio de logs a un servicio externo (actualmente se registran localmente).

## Tiempo estimado dedicado
- Aproximadamente 12 horas efectivas (distribuidas en analisis, implementacion, estilos y pruebas).
