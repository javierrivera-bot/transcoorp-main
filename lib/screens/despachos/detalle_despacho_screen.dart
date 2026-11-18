import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/domain/rutas.dart';
import 'package:transcoorp/models/despacho/despacho.dart';
import 'package:transcoorp/services/local/gestor_sesion.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/despacho_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';

class DetalleDespachoScreen extends StatefulWidget {
  const DetalleDespachoScreen({super.key, required this.despacho});

  final Despacho despacho;

  @override
  State<DetalleDespachoScreen> createState() => _DetalleDespachoScreenState();
}

class _DetalleDespachoScreenState extends State<DetalleDespachoScreen> {
  final DespachoService _servicio = DespachoService();

  late Despacho _despacho = widget.despacho;
  bool _procesando = false;

  bool get _esAdministrativo => GestorSesion.actual?.esAdministrativo ?? false;

  @override
  void initState() {
    super.initState();
    if (_esAdministrativo) _refrescar();
  }

  Future<void> _refrescar() async {
    try {
      final actual = await _servicio.obtenerPorId(_despacho.id);
      if (mounted) setState(() => _despacho = actual);
    } on ApiException catch (_) {}
  }

  Future<void> _cancelar() async {
    final motivo = await solicitarMotivo(
      context,
      titulo: 'Cancelar despacho',
      mensaje:
          'El despacho ${_despacho.codigo} quedará cancelado y se conservará en el historial.',
      etiqueta: 'Motivo de la cancelación',
      textoConfirmar: 'Cancelar despacho',
    );
    if (motivo == null || !mounted) return;

    setState(() => _procesando = true);
    try {
      await _servicio.cancelar(_despacho.id, motivo);
      if (!mounted) return;
      mostrarExito(context, 'Despacho cancelado.');
      await _refrescar();
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final d = _despacho;
    final ruta = CatalogoRutas.buscar(d.ruta);

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(titulo: 'Detalle del despacho', subtitulo: d.codigo),
      body: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TarjetaBase(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  PlacaVehiculo(placa: d.placaVehiculo, grande: true),
                  const SizedBox(height: 10),
                  Text(
                    ruta?.trayecto ?? d.ruta,
                    textAlign: TextAlign.center,
                    style: AppTheme.montserrat(
                      size: 17,
                      weight: FontWeight.w700,
                      color: c.textoOscuro,
                    ),
                  ),
                  if (ruta != null)
                    Text(
                      '${ruta.nombre} · ${ruta.servicio}',
                      textAlign: TextAlign.center,
                      style: AppTheme.inter(size: 12.5, color: c.textoSutil),
                    ),
                  const SizedBox(height: 10),
                  d.cancelado
                      ? const ChipEstado(texto: 'Cancelado', tono: TonoEstado.peligro)
                      : const ChipEstado(texto: 'Despachado', tono: TonoEstado.exito),
                ],
              ),
            ),
            if (d.cancelado) ...[
              const SizedBox(height: 12),
              Aviso(
                titulo: 'Despacho cancelado',
                mensaje:
                    '${Formato.valorO(d.motivoCancelacion, 'Sin motivo registrado')}\n${d.canceladoPor == null ? '' : 'Por ${d.canceladoPor} · '}${Fechas.fechaHora(d.fechaCancelacion)}',
                tono: TonoEstado.peligro,
              ),
            ],
            const SizedBox(height: 16),
            SeccionDetalle(
              titulo: 'Datos del despacho',
              icono: Icons.departure_board_outlined,
              children: [
                GrillaDatos(
                  datos: [
                    FilaDato(etiqueta: 'ID', valor: '${d.id}'),
                    FilaDato(etiqueta: 'Vehículo', valor: d.placaVehiculo),
                    FilaDato(etiqueta: 'Fecha', valor: Fechas.corta(d.fecha)),
                    FilaDato(etiqueta: 'Hora', valor: Fechas.horaTexto(d.hora)),
                  ],
                ),
                FilaDato(
                  icono: Icons.alt_route,
                  etiqueta: 'Ruta',
                  valor: ruta?.etiqueta ?? d.ruta,
                ),
                FilaDato(
                  icono: Icons.groups_outlined,
                  etiqueta: 'Número de pasajeros',
                  valor: '${d.numeroPasajeros}',
                  destacado: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SeccionDetalle(
              titulo: 'Trazabilidad',
              icono: Icons.manage_history,
              children: [
                FilaDato(
                  icono: Icons.person_outline,
                  etiqueta: 'Registrado por',
                  valor: Formato.valorO(d.registradoPor, 'Sistema'),
                ),
                FilaDato(
                  icono: Icons.event_note_outlined,
                  etiqueta: 'Fecha de registro',
                  valor: Fechas.fechaHora(d.fechaRegistro),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _esAdministrativo && !d.cancelado
          ? PieAcciones(
              children: [
                BotonSecundario(
                  texto: 'Cancelar despacho',
                  icono: Icons.cancel_outlined,
                  peligro: true,
                  alPresionar: _procesando ? null : _cancelar,
                ),
              ],
            )
          : null,
    );
  }
}
