# TRANSCOOP · Sistema Integral de Transporte Mixto

Aplicación móvil en Flutter para la gestión de una cooperativa de transporte mixto. Consume la API SITRAMIX (`https://api.sitram.cecar.cloud`).

## Requisitos

- Flutter estable con Dart `^3.8.0`
- Android Studio o VS Code con un emulador o un dispositivo físico

## Ejecución

```bash
flutter pub get
flutter run
```

Para apuntar a otra instancia de la API:

```bash
flutter run --dart-define=API_BASE_URL=https://mi-servidor.com
```

Generar el instalador de Android:

```bash
flutter build apk --release
```

## Roles

| Rol | Acceso |
|---|---|
| GERENTE / ASISTENTE | Panel administrativo completo. Únicos perfiles autorizados para sancionar conductores. |
| ADMIN | Panel administrativo. |
| ASOCIADO | Portal del asociado: sus vehículos, sus viajes y el catálogo de rutas. |

La API no expone un rol de conductor. La información de los conductores la gestionan los perfiles administrativos.

## Módulos

- **Acceso:** splash con validación de sesión, inicio de sesión, recuperación de contraseña con OTP, cambio de contraseña temporal y voluntario, y cierre de sesión.
- **Dashboard:** indicadores en tiempo real, alerta de conductores sancionados, accesos a todos los módulos y despachos recientes.
- **Asociados:** listado paginado con búsqueda y filtros, registro con afiliación del vehículo, detalle, edición, desafiliación y generación de acceso a la app.
- **Afiliaciones:** listado con filtros, registro, detalle, edición, finalización y desafiliación.
- **Conductores:** listado, registro, detalle con la licencia como sección independiente, edición e historial de sanciones.
- **Sanciones:** registro con confirmación, estados Programada, Vigente, Finalizada y Anulada, detalle, anulación y bloqueo de asignaciones.
- **Vehículos:** listado por placa y tipo, registro, detalle por bloques, edición y control de vigencias de SOAT y TRM.
- **Mantenimiento:** ingreso a taller, registro de salida e historial por vehículo.
- **Tarifas:** listado, registro con total calculado, detalle e inactivación con confirmación.
- **Planillas:** listado con filtros, generación masiva, detalle, anulación con motivo, registro de pago y descarga en PDF.
- **Despachos:** listado con filtros, registro con validación de capacidad, detalle y cancelación.
- **Rutas:** catálogo con búsqueda por origen, destino y estado.
- **Mi cuenta:** vehículos afiliados y viajes del asociado filtrados por periodo y placa.

## Estados de interfaz

Cada módulo maneja los estados de carga, sin resultados (con una acción para limpiar filtros o registrar), error con reintento, éxito, confirmación antes de las acciones sensibles, sesión no válida (con redirección al login y limpieza de credenciales) y conductor sancionado (con indicador visible y bloqueo de la asignación).

## Estructura

```
lib/
├── config/        Configuración de la API
├── domain/        Tema, formatos, fechas, validaciones y catálogo de rutas
├── models/        Modelos por recurso de la API
├── routes/        Rutas con nombre y navegación
├── screens/       Pantallas organizadas por módulo
├── services/
│   ├── documentos/  Generación de PDF
│   ├── local/       Sesión y preferencias en almacenamiento seguro
│   └── remote/      Clientes HTTP por recurso
├── theme/         Paleta clara y oscura
└── widgets/       Componentes reutilizables
```

## Notas

- La recuperación de contraseña por correo funciona en modo demostración, porque la API no expone ese servicio. El código de prueba es `123456`.
- El catálogo de rutas es local, porque la API registra la ruta como texto dentro de cada despacho.
