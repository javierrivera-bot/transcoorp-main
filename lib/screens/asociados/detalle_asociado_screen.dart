import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/afiliacion/afiliacion.dart';
import 'package:transcoorp/models/asociado/asociado.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/afiliaciones/detalle_afiliacion_screen.dart';
import 'package:transcoorp/screens/afiliaciones/formulario_afiliacion_screen.dart';
import 'package:transcoorp/screens/afiliaciones/listado_afiliaciones_screen.dart';
import 'package:transcoorp/screens/asociados/formulario_asociado_screen.dart';
import 'package:transcoorp/services/remote/afiliacion_service.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/asociado_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/boton_principal.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';

class DetalleAsociadoScreen extends StatefulWidget {
  const DetalleAsociadoScreen({super.key, required this.asociado});

  final Asociado asociado;

  @override
  State<DetalleAsociadoScreen> createState() => _DetalleAsociadoScreenState();
}

class _DetalleAsociadoScreenState extends State<DetalleAsociadoScreen> {
  final AsociadoService _servicio = AsociadoService();
  final AfiliacionService _afiliaciones = AfiliacionService();

  late Asociado _asociado = widget.asociado;
  List<Afiliacion>? _vehiculos;
  String? _errorVehiculos;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  Future<void> _refrescar() async {
    try {
      final asociado = await _servicio.obtenerPorId(_asociado.identificacion);
      if (mounted) setState(() => _asociado = asociado);
    } on ApiException catch (_) {}
    await _cargarVehiculos();
  }

  Future<void> _cargarVehiculos() async {
    setState(() => _errorVehiculos = null);
    try {
      final pagina = await _afiliaciones.listar(
        asociado: _asociado.identificacion,
        tamano: 50,
      );
      if (!mounted) return;
      setState(() {
        _vehiculos = pagina.items
            .where((a) => a.identificacionAsociado == _asociado.identificacion)
            .toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorVehiculos = e.message);
    }
  }

  Future<void> _editar() async {
    final actualizado = await abrir<Asociado>(
      context,
      FormularioAsociadoScreen(asociado: _asociado),
    );
    if (actualizado == null || !mounted) return;
    setState(() => _asociado = actualizado);
    mostrarExito(context, 'Información del asociado actualizada.');
  }

  Future<void> _cambiarEstado() async {
    final desafiliar = _asociado.activo;
    final confirmado = await confirmarAccion(
      context,
      titulo: desafiliar ? 'Desafiliar asociado' : 'Reactivar asociado',
      mensaje: desafiliar
          ? '${_asociado.nombres} quedará inactivo y no podrá operar vehículos en la cooperativa. El historial se conserva.'
          : '${_asociado.nombres} volverá a estar activo en la cooperativa.',
      textoConfirmar: desafiliar ? 'Desafiliar' : 'Reactivar',
      peligrosa: desafiliar,
      icono: desafiliar ? Icons.person_off_outlined : Icons.person_add_alt,
    );
    if (!confirmado || !mounted) return;

    setState(() => _procesando = true);
    try {
      final actualizado = desafiliar
          ? await _servicio.desafiliar(_asociado.identificacion)
          : await _servicio.reactivar(_asociado.identificacion);
      if (!mounted) return;
      setState(() => _asociado = actualizado);
      mostrarExito(
        context,
        desafiliar ? 'Asociado desafiliado.' : 'Asociado reactivado.',
      );
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _generarAcceso() async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Generar acceso a la app',
      mensaje:
          'Se creará una contraseña temporal para que el asociado consulte sus vehículos y viajes. Deberá cambiarla en su primer ingreso.',
      textoConfirmar: 'Generar',
      icono: Icons.key_outlined,
    );
    if (!confirmado || !mounted) return;

    try {
      final credencial = await _servicio.generarCredencial(
        _asociado.identificacion,
      );
      if (!mounted) return;
      await mostrarInformacion(
        context,
        titulo: 'Acceso generado',
        icono: Icons.key_outlined,
        contenido: _ContenidoCredencial(credencial: credencial),
      );
      _refrescar();
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    }
  }

  Future<void> _nuevaAfiliacion() async {
    final creada = await abrir<Afiliacion>(
      context,
      FormularioAfiliacionScreen(identificacionAsociado: _asociado.identificacion),
    );
    if (creada == null || !mounted) return;
    mostrarExito(context, 'Vehículo ${creada.placaVehiculo} afiliado.');
    _cargarVehiculos();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final a = _asociado;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Detalle del asociado',
        subtitulo: 'C.C. ${a.identificacion}',
        acciones: [
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            icon: Icon(Icons.more_vert, color: c.primarioOscuro),
            onSelected: (valor) {
              if (valor == 'acceso') _generarAcceso();
              if (valor == 'afiliaciones') {
                abrir(
                  context,
                  ListadoAfiliacionesScreen(asociado: a.identificacion),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'acceso',
                child: ListTile(
                  leading: Icon(Icons.key_outlined),
                  title: Text('Generar acceso a la app'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'afiliaciones',
                child: ListTile(
                  leading: Icon(Icons.handshake_outlined),
                  title: Text('Historial de afiliaciones'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: ContenidoCentrado(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _cabecera(c, a),
              if (!a.activo) ...[
                const SizedBox(height: 12),
                const Aviso(
                  titulo: 'Asociado desafiliado',
                  mensaje:
                      'Se encuentra inactivo. Puedes reactivarlo desde las acciones inferiores.',
                  tono: TonoEstado.alerta,
                ),
              ],
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Información personal',
                icono: Icons.person_outline,
                children: [
                  FilaDato(
                    icono: Icons.badge_outlined,
                    etiqueta: 'Identificación',
                    valor: a.identificacion,
                  ),
                  FilaDato(
                    icono: Icons.person_outline,
                    etiqueta: 'Nombres y apellidos',
                    valor: a.nombres,
                  ),
                  FilaDato(
                    icono: Icons.phone_outlined,
                    etiqueta: 'Celular',
                    valor: Formato.valorO(a.celular),
                  ),
                  FilaDato(
                    icono: Icons.mail_outline,
                    etiqueta: 'Correo electrónico',
                    valor: Formato.valorO(a.correo),
                  ),
                  FilaDato(
                    icono: Icons.cake_outlined,
                    etiqueta: 'Fecha de nacimiento',
                    valor: a.fechaNacimiento == null
                        ? 'No registrada'
                        : '${Fechas.corta(a.fechaNacimiento)} · ${_edad(a.fechaNacimiento!)} años',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Vinculación',
                icono: Icons.apartment_outlined,
                children: [
                  GrillaDatos(
                    datos: [
                      FilaDato(
                        etiqueta: 'Fecha de ingreso',
                        valor: Fechas.corta(a.fechaIngreso),
                      ),
                      FilaDato(
                        etiqueta: 'Estado',
                        valor: a.activo ? 'Activo' : 'Inactivo',
                      ),
                    ],
                  ),
                  FilaDato(
                    icono: Icons.phone_android,
                    etiqueta: 'Acceso a la app',
                    valor: a.username == null
                        ? 'Sin credenciales generadas'
                        : '${a.username} · ${Formato.capitalizar(a.estadoCredencial ?? '')}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _seccionVehiculos(c),
              const SizedBox(height: 16),
              PieTrazabilidad(
                registro: Fechas.corta(a.fechaRegistro),
                actualizacion: Fechas.corta(
                  a.ultimaActualizacion ?? a.fechaRegistro,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PieAcciones(
        children: [
          BotonSecundario(
            texto: a.activo ? 'Desafiliar' : 'Reactivar',
            icono: a.activo ? Icons.person_off_outlined : Icons.person_add_alt,
            peligro: a.activo,
            alPresionar: _procesando ? null : _cambiarEstado,
          ),
          BotonPrincipal(
            texto: 'Editar',
            alPresionar: _editar,
            cargando: _procesando,
          ),
        ],
      ),
    );
  }

  int _edad(DateTime nacimiento) {
    final hoy = DateTime.now();
    var edad = hoy.year - nacimiento.year;
    if (hoy.month < nacimiento.month ||
        (hoy.month == nacimiento.month && hoy.day < nacimiento.day)) {
      edad--;
    }
    return edad;
  }

  Widget _cabecera(ColoresApp c, Asociado a) {
    return TarjetaBase(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          AvatarIniciales(texto: a.iniciales, tamano: 60),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChipEstado.activo(a.activo),
                const SizedBox(height: 6),
                Text(
                  a.nombres,
                  style: AppTheme.montserrat(
                    size: 18,
                    weight: FontWeight.w700,
                    color: c.textoOscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.fechaIngreso == null
                      ? 'Asociado de la cooperativa'
                      : 'Socio desde ${Fechas.media(a.fechaIngreso)}',
                  style: AppTheme.inter(size: 12.5, color: c.textoSutil),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionVehiculos(ColoresApp c) {
    final vehiculos = _vehiculos;
    final List<Widget> contenido;

    if (_errorVehiculos != null) {
      contenido = [
        Text(
          _errorVehiculos!,
          style: AppTheme.inter(size: 13, color: AppColors.rojoAlerta),
        ),
        TextButton.icon(
          onPressed: _cargarVehiculos,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Reintentar'),
        ),
      ];
    } else if (vehiculos == null) {
      contenido = const [
        Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ];
    } else if (vehiculos.isEmpty) {
      contenido = [
        Text(
          'Este asociado no tiene vehículos afiliados.',
          style: AppTheme.inter(size: 13, color: c.textoSecundario),
        ),
      ];
    } else {
      contenido = [
        for (final afiliacion in vehiculos)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await abrir(
                context,
                DetalleAfiliacionScreen(afiliacion: afiliacion),
              );
              if (mounted) _cargarVehiculos();
            },
            child: FilaDato(
              icono: Icons.directions_car_outlined,
              etiqueta: 'Afiliado desde ${Fechas.corta(afiliacion.fechaAfiliacion)}',
              valor: afiliacion.placaVehiculo,
              complemento: ChipEstado(
                texto: Formato.capitalizar(afiliacion.estado),
                tono: afiliacion.activa ? TonoEstado.exito : TonoEstado.neutro,
              ),
            ),
          ),
      ];
    }

    return SeccionDetalle(
      titulo: 'Vehículos afiliados',
      icono: Icons.directions_car_outlined,
      etiqueta: _asociado.activo
          ? TextButton.icon(
              onPressed: _nuevaAfiliacion,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Afiliar'),
            )
          : null,
      children: contenido,
    );
  }
}

class _ContenidoCredencial extends StatelessWidget {
  const _ContenidoCredencial({required this.credencial});

  final CredencialTemporal credencial;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    Widget fila(String etiqueta, String valor) => FilaDato(
      etiqueta: etiqueta,
      valor: valor,
      destacado: true,
      complemento: IconButton(
        tooltip: 'Copiar',
        icon: Icon(Icons.copy, size: 18, color: c.primario),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: valor));
          mostrarExito(context, '$etiqueta copiado.');
        },
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Comparte estos datos de forma privada con el asociado.',
          textAlign: TextAlign.center,
          style: AppTheme.inter(size: 13, color: c.textoSecundario),
        ),
        const SizedBox(height: 14),
        fila('Usuario', credencial.username),
        const SizedBox(height: 8),
        fila('Contraseña temporal', credencial.password),
        if (credencial.expira != null) ...[
          const SizedBox(height: 10),
          Text(
            'Vence: ${Fechas.fechaHora(credencial.expira)}',
            textAlign: TextAlign.center,
            style: AppTheme.inter(size: 12, color: c.textoSutil),
          ),
        ],
      ],
    );
  }
}
