# Guion de exposición — TRANSCOOP / SITRAMIX

> **Cómo usarlo:** el texto entre «comillas» es lo que se dice en voz alta. La línea **Mostrar:** indica qué archivo abrir en pantalla. El tiempo total estimado es de **18–20 minutos**.
>

---

## 1. Apertura — qué construimos y para quién (1 min)

«Buenos días. Voy a presentar TRANSCOOP, una aplicación móvil en Flutter para una cooperativa de transporte mixto. La app se conecta a la API SITRAMIX y sirve a tres perfiles: gerencia y asistencia, que pueden sancionar; administradores, que gestionan el sistema; y asociados, que consultan sus vehículos, sus viajes y el catálogo de rutas.

El objetivo fue cubrir la operación completa: acceso seguro, gestión de asociados, conductores, vehículos, afiliaciones, sanciones, mantenimientos, tarifas, despachos, planillas con descarga en PDF y un portal del asociado.»

**Mostrar:** `README.md` (tabla de roles y lista de módulos) y `pubspec.yaml`.

«Tecnológicamente usamos Dart 3.8, Material 3, `http` para la API, `flutter_secure_storage` para credenciales, `pdf` y `printing` para los comprobantes, y `google_fonts` para la tipografía.»

---

## 2. Arquitectura general (2 min)

**Mostrar:** el árbol de `lib/`.

«El código está separado en capas, de abajo hacia arriba:

- **`config/`**: un solo punto de configuración, la URL base de la API.
- **`domain/`**: lógica pura, sin Flutter: validaciones de contraseña, formato de fechas y moneda, catálogo local de rutas y el tema.
- **`models/`**: los DTO. Cada modelo tiene un `factory fromJson` y getters calculados.
- **`services/`**: remoto para HTTP, local para sesión y preferencias, y documentos para el PDF.
- **`routes/`**: navegación con nombre.
- **`screens/` y `widgets/`**: la interfaz, organizada por módulo.

La regla es que la UI no llama directamente a `http`: siempre pasa por un servicio. Y el servicio no conoce pantallas: devuelve modelos o excepciones. Eso hace que cada capa se pueda cambiar sin romper las demás.»

**Puntos clave para defender:**
- Las clases `abstract final` se usan como contenedores de métodos estáticos (`Json`, `Fechas`, `Formato`, `Auth`, `ApiService` helpers).
- El estado reactivo se resuelve con `ValueNotifier` (tema, cambios de datos) y `ValueListenableBuilder`, sin paquetes de estado externos.

---

## 3. Arranque, tema y sesión caducada (1.5 min)

**Mostrar:** `lib/main.dart`.

«El `main()` hace tres cosas antes de pintar: espera a Flutter, carga el tema guardado con `PreferenciaTema.cargar()`, y registra un callback global: `ApiService.alSesionInvalida = ControlSesion.expirar`. Después lanza `MainApp`.

Ese callback es la pieza elegante del arranque: cuando cualquier petición recibe un 401, `ApiService._send` lo dispara. `ControlSesion.expirar()` cierra la sesión, limpia credenciales y navega al login con `pushNamedAndRemoveUntil`, usando `AppRoutes.navegador`, una `GlobalKey` que permite navegar sin tener un `BuildContext`.»

«`MainApp` envuelve todo en un `ValueListenableBuilder<ThemeMode>`: si el usuario cambia de tema, toda la app se repinta. También fijamos locale `es_CO` para fechas y moneda, y ajustamos el color de la barra del sistema según modo claro u oscuro.»

**Mostrar:** `lib/theme/preferencia_tema.dart` y `lib/theme/colores_app.dart`.

«La preferencia de tema se guarda en almacenamiento seguro como `'0'` o `'1'`. La paleta vive en `ColoresApp`, una extensión de `ThemeExtension`, y se consume con `context.colores`.»

---

## 4. Capa de dominio (1.5 min)

**Mostrar:** `lib/domain/auth.dart`, `fechas.dart`, `formatos.dart`, `rutas.dart`.

«En dominio está la lógica que no depende de la interfaz, por eso es la más fácil de probar:

- `Auth` valida usuario, contraseña, correo y OTP de 6 dígitos, y calcula un `nivelSeguridad` de 0 a 3 con etiquetas Básica, Media y Segura.
- `Fechas` centraliza todos los formatos: fecha larga, corta, ISO para la API, hora de 12 horas y cálculo de vencimientos.
- `Formato` da moneda con prefijo `$ ` y separador de miles, iniciales y capitalización de nombres.
- `CatalogoRutas` mantiene cuatro rutas constantes con búsqueda por código, nombre u origen-destino. Estas rutas son locales porque la API guarda la ruta como texto dentro de cada despacho.»

---

## 5. Modelos y contrato con la API (2 min)

**Mostrar:** `lib/models/comun/json.dart` y `pagina.dart`.

«Toda la app habla con el backend a través de dos helpers. `Json` desenvuelve las respuestas, que pueden venir en `data` o en `items`, y convierte valores con tolerancia a tipos: `texto`, `entero`, `decimal`, `booleano`, `fecha`, `objeto`. `Pagina<T>` encapsula los ítems más la información de paginación y calcula `hayMas`.»

**Mostrar:** `lib/models/sesion/sesion.dart`.

«El modelo de sesión tiene un detalle destacable: `Sesion._expiracion` decodifica el payload del JWT en base64 para leer el claim `exp`, y si no está, admite `expiraEn` en milisegundos, segundos o duración. De ahí sale el getter `valida`, que es el que se comprueba antes de cada petición.»

«El resto de modelos —`Asociado`, `Conductor`, `Vehiculo`, `Afiliacion`, `Despacho`, `Sancion`, `Tarifa`, `Planilla`, `Mantenimiento`— siguen el mismo patrón: `fromJson` usando los helpers `Json.*` y getters calculados como `licenciaVencida`, `soatVencido`, `codigo` o `estadoVista`. Los DTO de entrada, como `LoginRequest` y `CambiarPasswordRequest`, solo implementan `toJson`.»

---

## 6. Capa de servicios (2.5 min)

**Mostrar:** `lib/services/remote/api_service.dart`.

«`ApiService` es el cliente HTTP. Construye cabeceras, normaliza la URL, descarta parámetros de query vacíos y aplica un timeout de 20 segundos. Su método `_send` es el corazón: traduce errores de red, timeout y JSON inválido a `ApiException`, y extrae mensajes de error del cuerpo de la respuesta —lista `errors` o claves `mensaje`, `message`, `detail`, `title`—. Si la petición era autenticada y devuelve 401, dispara el callback de sesión expirada.»

**Mostrar:** `lib/services/remote/servicio_base.dart` y `cabeceras_autenticadas.dart`.

«`ServicioBase` da el patrón CRUD a todos los servicios: `paginar`, `obtener`, `crear`, `actualizar`, `eliminar` y `contar`. Cada servicio hijo solo define su ruta y cómo convertir el JSON. `cabecerasAutenticadas()` añade el `Bearer token` y, si la sesión no es válida, bloquea la petición antes de enviarla.»

**Mostrar:** una muestra de servicios: `login_service.dart`, `planilla_service.dart`, `recuperacion_service.dart`.

«Hay una excepción honesta: `RecuperacionService` está marcado como `simulado`, con el código de demostración `123456`, porque la API no expone recuperación por correo. Todo lo demás sí es real: incluido `generarMasivas`, `anular` y `registrarPago` en planillas.»

**Mostrar:** `lib/services/local/secure_storage_service.dart`, `gestor_sesion.dart`, `services/local/cambios_datos.dart` y `services/documentos/pdf_planilla.dart`.

«En local, `SecureStorageService` guarda la sesión y el tema. `GestorSesion` mantiene la sesión en memoria y decide si persiste según "recordar sesión"; `CambiosDatos` es un `ValueNotifier` que avisa a las pantallas cuando se registra un conductor. Y `PdfPlanilla.generar` arma la planilla en A4 con logo, datos de operación, vehículo, conductor, liquidación y firmas; `compartir` la envía con el paquete `printing`.»

---

## 7. Navegación y flujo de acceso (2 min)

**Mostrar:** `lib/routes/app_routes.dart`.

«Solo hay seis rutas con nombre: splash, login, recuperar, verificar OTP, nueva contraseña e inicio. `AppRoutes.generar` es el único lugar que las construye, y `abrir()` navega al resto de pantallas —formularios y detalles— sin declararlas. Así el grafo de navegación queda centrado.»

**Mostrar:** `screens/inicio/splash_screen.dart`, `screens/auth/login_screen.dart`, `verificar_otp_screen.dart`, `nueva_contrasena_screen.dart`.

«El flujo de acceso es: el splash espera 1,4 segundos mientras restaura la sesión y decide entre inicio y login. En login, si la API indica `requiereCambioPassword`, se fuerza el cambio antes de entrar. La recuperación de contraseña usa seis cajas con auto-avance, temporizador de cinco minutos y el código demo. La pantalla de nueva contraseña muestra una barra de seguridad de tres niveles y tiene tres caminos: cambio voluntario desde el perfil, cambio obligatorio tras el login y recuperación.»

«Dentro de la app, `InicioScreen` es un `IndexedStack` que muestra pestañas distintas para asociados y para administración, cargando cada página solo la primera vez que se visita. Desde el perfil se cierra sesión y se cambia el tema.»

---

## 8. Módulos funcionales y patrones de pantalla (3.5 min)

**Mostrar:** `lib/widgets/vista_paginada.dart` y, de forma rápida, un listado, un formulario y un detalle de cualquier módulo.

«Casi todas las pantallas siguen la misma receta: un `Scaffold` con `EncabezadoModulo` —título, subtítulo y botón de alta—, después `PantallaLista`, que junta filtros y `VistaPaginada`. El controlador se crea en `initState`, se recarga al entrar y se libera en `dispose`. La búsqueda tiene debounce de 450 ms, las píldoras de `BarraFiltros` cambian el criterio y `FiltroFecha` abre el selector de fechas. Cuando volvemos de un formulario con `abrir(...)`, la lista se recarga solo si la pantalla devolvió un resultado.»

«Los formularios usan `GlobalKey<FormState>`, validadores centralizados en `Validar` y formateadores en `Formateadores` —mayúsculas, solo dígitos, miles—. Los detalles repiten `_refrescar()`, bloques `SeccionDetalle` y `GrillaDatos`, y acciones con `confirmarAccion`, `solicitarMotivo` o `mostrarInformacion`. Algunos listados, como el de asociados y conductores, detectan una identificación de tres o más dígitos y consultan directamente por ID en vez de listar.»

«Módulos con CRUD completo —listado, formulario y detalle—: Afiliaciones, Asociados, Conductores, Despachos, Sanciones, Tarifas y Vehículos. Tres no siguen ese patrón: Mantenimiento registra la salida en un bottom sheet; Planillas hace la generación masiva y el pago también en hojas modales; y Rutas es un catálogo local de solo lectura.»

«Hay una regla de negocio repetida a propósito en tres sitios —`_bloqueo` en Despachos y en Generar planillas, y `_motivoBloqueo` en Vehículos—: no se puede operar con un vehículo sin conductor, con conductor sancionado, con licencia vencida o con SOAT y TRM vencidos. La validamos en la presentación para deshabilitar opciones y se vuelve a comprobar al guardar. Y los permisos salen de `GestorSesion.actual`: solo quien tiene `puedeSancionar` ve el alta de sanciones y las acciones de anulación.»

«Los dos portales quedan claros: el dashboard administrativo tiene diez accesos y métricas en `TarjetaBienvenida`; el del asociado muestra sus vehículos, sus viajes del mes y el catálogo de rutas. `InicioScreen` decide qué pestañas mostrar con `IndexedStack` y crea cada página solo la primera vez que se visita.»

---

## 9. Componentes reutilizables y tema (2 min)

**Mostrar:** `lib/widgets/` (abrir `vista_paginada.dart`, `campos_formulario.dart`, `dialogos.dart`, `seccion_detalle.dart`).

«Los 18 archivos de `widgets/` son la librería interna de la app. Los agrupo en cinco bloques:

1. **Estructura**: `EncabezadoModulo`, `EncabezadoSeguridad` y `ContenidoCentrado` —que vive en `marco_pantalla.dart` pese al nombre— y limita el ancho a 520 píxeles en tablet.
2. **Listado y filtros**: `VistaPaginada`, `ControladorPaginado`, `PantallaLista`, `CampoBusqueda`, `BarraFiltros`, `FiltroFecha` y `ContadorResultados`.
3. **Formularios**: `CampoTexto`, `CampoFecha`, `CampoHora`, `CampoSelector`, `InterruptorCampo`, `Validar` y `Formateadores`, más `decoracionCampo` y `MensajeError`.
4. **Estados y modales**: `EstadoCarga`, `EstadoVacio`, `EstadoError`, `confirmarAccion`, `solicitarMotivo`, `mostrarExito` y `mostrarError`.
5. **Visuales**: `TarjetaBase`, `AvatarIniciales`, `PlacaVehiculo`, `ChipEstado`, `TarjetaBienvenida`, `TarjetaDespacho` —reutilizada en cuatro pantallas— y `SeccionDetalle` con `FilaDato`, `GrillaDatos`, `Aviso` y `PieTrazabilidad`.

«Así, si mañana cambiamos el diseño de un botón o de un estado vacío, se cambia en un solo archivo.»

**Mostrar:** `lib/theme/colores_app.dart` y `lib/domain/app_theme.dart`.

«El tema es una `ThemeExtension` con paleta clara y oscura, `copyWith`, `lerp` y el getter `context.colores`, con fallback según el `brightness`. `AppTheme` aporta las fuentes Montserrat e Inter y las sombras suaves.»

«Como deuda consciente: `LoginScreen` y `NuevaContrasenaScreen` mantienen decoración propia en lugar de usar estos componentes, y algunos widgets siguen usando `AppColors` fijo en vez de `context.colores`. Es lo primero que unificaría.»

---

## 10. Pruebas y calidad (1 min)

**Mostrar:** `test/` y ejecutar `flutter analyze`.

«Hay 8 archivos de prueba con 49 casos, todos unitarios: no usamos `testWidgets`, porque probamos la lógica pura sobre la que se apoya la interfaz. Se reparten en 9 pruebas de los helpers `Json`, 3 de `Pagina`, 7 de `Sesion` —incluido el JWT y los roles—, 9 de fechas, 7 de formatos, 7 de validaciones de `Auth`, 1 del bus `CambiosDatos` y 6 del `ControladorPaginado`.»

«Estas últimas son las más interesantes: simulan una carrera entre `cargarMas()` y `recargar()` con un `Completer` y comprueban que se descarte la respuesta obsoleta. Además, `flutter analyze` termina sin advertencias y el código no tiene comentarios: la documentación son los nombres y este guion.»

---

## 11. Cierre (1 min)

«Para resumir: una app Flutter organizada por capas, con un contrato JSON tolerante, errores de API traducidos a mensajes en español, sesión que se renueva y expira de forma centralizada, paginación reutilizable y un entregable visible como es la planilla en PDF.»

«Si tuviera que seguir mejorando, centralizaría en dominio la regla de bloqueo de vehículos, que hoy se repite en tres formularios; unificaría el estilo de login y nueva contraseña con el resto de widgets; y añadiría pruebas de widgets para los estados de vista. Gracias, quedo abierto a preguntas.»

---

## Anexo — posibles preguntas y respuestas

| Pregunta | Respuesta corta |
|---|---|
| ¿Por qué no hay comentarios en el código? | Los quitamos a propósito: los nombres de métodos y variables son descriptivos y la explicación vive en este guion, así que no puede quedar documentación desactualizada. |
| ¿Qué pasa si la sesión caduca a mitad de una petición? | `ApiService._send` detecta el 401, llama a `ControlSesion.expirar`, limpia la sesión y manda al login; `cabecerasAutenticadas` también bloquea peticiones nuevas con token inválido. |
| ¿Cómo se hace la paginación? | `ServicioBase.paginar` envía `page` y `pageSize`; `Pagina.desdeRespuesta` normaliza la respuesta; `ControladorPaginado` carga más al acercarse al final y evita duplicados. |
| ¿La recuperación de contraseña es real? | No: está marcada como simulada porque la API no expone ese servicio; el código de prueba es `123456`. |
| ¿Por qué las rutas son locales? | Porque la API guarda la ruta como texto dentro de cada despacho, no como entidad consultable. |
| ¿De dónde sale el total de una tarifa? | Si el backend no lo envía, el modelo lo calcula sumando aportes, fondo de reposición y aporte social. |
| ¿Cómo se genera el PDF? | `PdfPlanilla.generar` construye el documento con el paquete `pdf` y `compartir` usa `printing` para compartirlo. |
| ¿Por qué no todas las pantallas son rutas con nombre? | Solo las seis pantallas de entrada lo son. El resto se abre con `abrir<T>(context, pantalla)`, que permite recibir el resultado y recargar la lista; así el grafo queda centralizado en `AppRoutes`. |
| ¿Qué impide asignar un vehículo? | La regla de `_bloqueo` / `_motivoBloqueo`: sin conductor, conductor sancionado, licencia vencida o SOAT y TRM vencidos. Se deshabilita la opción y se vuelve a validar al guardar. |
| ¿Por qué no hay pruebas de interfaz? | Las 49 pruebas son unitarias y cubren dominio, modelos, sesión y paginación, que es donde vive la lógica. La UI se comprueba manualmente mediante `EstadoCarga`, `EstadoVacio` y `EstadoError`. |
| ¿Cómo evitamos duplicar filas al paginar rápido? | `ControladorPaginado` usa una versión interna: `recargar()` la incrementa y descarta la respuesta de una petición anterior. Hay un test que simula esa carrera. |

---

## Mapa rápido de archivos para mostrar en pantalla

| Concepto | Archivo |
|---|---|
| Arranque y sesión global | `lib/main.dart` |
| API y errores | `lib/services/remote/api_service.dart` |
| CRUD y paginación | `lib/services/remote/servicio_base.dart` |
| Token Bearer | `lib/services/remote/cabeceras_autenticadas.dart` |
| Sesión local | `lib/services/local/gestor_sesion.dart` |
| Parseo JSON | `lib/models/comun/json.dart` |
| Paginación | `lib/models/comun/pagina.dart`, `lib/widgets/vista_paginada.dart` |
| JWT y roles | `lib/models/sesion/sesion.dart` |
| Rutas | `lib/routes/app_routes.dart` |
| Tema | `lib/theme/colores_app.dart`, `lib/domain/app_theme.dart` |
| PDF | `lib/services/documentos/pdf_planilla.dart` |
| Pruebas | `test/domain/`, `test/models/`, `test/services/`, `test/widgets/` |
