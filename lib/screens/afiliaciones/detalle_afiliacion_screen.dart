import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/afiliacion/afiliacion.dart';
import 'package:transcoorp/models/asociado/asociado.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/afiliaciones/formulario_afiliacion_screen.dart';
import 'package:transcoorp/screens/afiliaciones/listado_afiliaciones_screen.dart';
import 'package:transcoorp/services/remote/afiliacion_service.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/asociado_service.dart';
import 'package:transcoorp/services/remote/vehiculo_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/boton_principal.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';

class DetalleAfiliacionScreen extends StatefulWidget {
  const DetalleAfiliacionScreen({super.key, required this.afiliacion});

  final Afiliacion afiliacion;

  @override
  State<DetalleAfiliacionScreen> createState() =>
      _DetalleAfiliacionScreenState();
}

class _DetalleAfiliacionScreenState extends State<DetalleAfiliacionScreen> {
  final AfiliacionService _servicio = AfiliacionService();

  late Afiliacion _afiliacion = widget.afiliacion;
  Asociado? _asociado;
  Vehiculo? _vehiculo;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarRelacionados();
  }

  Future<void> _cargarRelacionados() async {
    try {
      final actual = await _servicio.obtenerPorId(_afiliacion.id);
      if (mounted) setState(() => _afiliacion = actual);
    } catch (_) {}
    try {
      final asociado = await AsociadoService().obtenerPorId(
        _afiliacion.identificacionAsociado,
      );
      if (mounted) setState(() => _asociado = asociado);
    } catch (_) {}
    try {
      final vehiculo = await VehiculoService().obtenerPorPlaca(
        _afiliacion.placaVehiculo,
      );
      if (mounted) setState(() => _vehiculo = vehiculo);
    } catch (_) {}
  }

  Future<void> _editar() async {
    final actualizada = await abrir<Afiliacion>(
      context,
      FormularioAfiliacionScreen(afiliacion: _afiliacion),
    );
    if (actualizada == null || !mounted) return;
    setState(() => _afiliacion = actualizada);
    mostrarExito(context, 'Afiliación actualizada.');
  }

  Future<void> _finalizar() async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Finalizar afiliación',
      mensaje:
          'La afiliación del vehículo ${_afiliacion.placaVehiculo} terminará con fecha de hoy (${Fechas.corta(Fechas.hoy)}).',
      textoConfirmar: 'Finalizar',
      icono: Icons.event_busy_outlined,
    );
    if (!confirmado || !mounted) return;
    await _ejecutar(
      () async {
        final actualizada = await _servicio.finalizar(_afiliacion, Fechas.hoy);
        if (mounted) setState(() => _afiliacion = actualizada);
      },
      'Afiliación finalizada.',
    );
  }

  Future<void> _desafiliar() async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Desafiliar vehículo',
      mensaje:
          'Se removerá el vínculo entre el asociado y el vehículo ${_afiliacion.placaVehiculo}. Esta acción quedará registrada en el historial.',
      textoConfirmar: 'Desafiliar',
      peligrosa: true,
      icono: Icons.link_off,
    );
    if (!confirmado || !mounted) return;
    await _ejecutar(
      () async {
        await _servicio.desafiliar(_afiliacion.id, Fechas.hoy);
        if (mounted) Navigator.pop(context, true);
      },
      'Vehículo desafiliado correctamente.',
    );
  }

  Future<void> _ejecutar(Future<void> Function() accion, String exito) async {
    setState(() => _procesando = true);
    try {
      await accion();
      if (mounted) mostrarExito(context, exito);
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final a = _afiliacion;
    final vigente = a.estado != EstadoAfiliacion.finalizada &&
        a.estado != EstadoAfiliacion.inactiva;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Detalle de afiliación',
        subtitulo: 'Registro N.° ${a.id}',
      ),
      body: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TarjetaBase(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  PlacaVehiculo(placa: a.placaVehiculo, grande: true),
                  const SizedBox(height: 10),
                  Text(
                    _vehiculo == null
                        ? 'Vehículo afiliado'
                        : '${_vehiculo!.tipo ?? 'Vehículo'} · ${_vehiculo!.descripcion}',
                    textAlign: TextAlign.center,
                    style: AppTheme.inter(size: 13, color: c.textoSutil),
                  ),
                  const SizedBox(height: 10),
                  ChipEstado(
                    texto: Formato.capitalizar(a.estado),
                    tono: tonoAfiliacion(a.estado),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SeccionDetalle(
              titulo: 'Datos del vínculo',
              icono: Icons.handshake_outlined,
              children: [
                FilaDato(
                  icono: Icons.tag,
                  etiqueta: 'ID de afiliación',
                  valor: '${a.id}',
                ),
                FilaDato(
                  icono: Icons.person_outline,
                  etiqueta: 'Asociado',
                  valor: _asociado == null
                      ? 'C.C. ${a.identificacionAsociado}'
                      : '${_asociado!.nombres} · C.C. ${a.identificacionAsociado}',
                ),
                FilaDato(
                  icono: Icons.directions_car_outlined,
                  etiqueta: 'Vehículo',
                  valor: a.placaVehiculo,
                ),
                GrillaDatos(
                  datos: [
                    FilaDato(
                      etiqueta: 'Fecha de afiliación',
                      valor: Fechas.corta(a.fechaAfiliacion),
                    ),
                    FilaDato(
                      etiqueta: 'Fecha de fin',
                      valor: a.fechaFin == null
                          ? 'Vigente'
                          : Fechas.corta(a.fechaFin),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            PieTrazabilidad(
              registro: Fechas.fechaHora(a.fechaRegistro),
              actualizacion: Fechas.fechaHora(
                a.ultimaActualizacion ?? a.fechaRegistro,
              ),
            ),
            if (vigente) ...[
              const SizedBox(height: 20),
              BotonSecundario(
                texto: 'Desafiliar vehículo',
                icono: Icons.link_off,
                peligro: true,
                alPresionar: _procesando ? null : _desafiliar,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: PieAcciones(
        children: [
          BotonSecundario(
            texto: 'Finalizar',
            icono: Icons.event_busy_outlined,
            alPresionar: _procesando || !vigente ? null : _finalizar,
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
}
