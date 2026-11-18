import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/planilla/planilla.dart';
import 'package:transcoorp/models/tarifa/tarifa.dart';
import 'package:transcoorp/screens/planillas/listado_planillas_screen.dart';
import 'package:transcoorp/screens/planillas/registro_pago_sheet.dart';
import 'package:transcoorp/services/documentos/pdf_planilla.dart';
import 'package:transcoorp/services/local/gestor_sesion.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/planilla_service.dart';
import 'package:transcoorp/services/remote/tarifa_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/boton_principal.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';

class DetallePlanillaScreen extends StatefulWidget {
  const DetallePlanillaScreen({super.key, required this.planilla});

  final Planilla planilla;

  @override
  State<DetallePlanillaScreen> createState() => _DetallePlanillaScreenState();
}

class _DetallePlanillaScreenState extends State<DetallePlanillaScreen> {
  final PlanillaService _servicio = PlanillaService();

  late Planilla _planilla = widget.planilla;
  Tarifa? _tarifa;
  bool _procesando = false;
  bool _generandoPdf = false;

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  Future<void> _refrescar() async {
    try {
      final actual = await _servicio.obtenerPorNumero(_planilla.numero);
      if (mounted) setState(() => _planilla = actual);
    } on ApiException catch (_) {}
    final tarifaId = _planilla.tarifaId;
    if (tarifaId != null && _tarifa == null) {
      try {
        final tarifa = await TarifaService().obtenerPorId(tarifaId);
        if (mounted) setState(() => _tarifa = tarifa);
      } on ApiException catch (_) {}
    }
  }

  Future<void> _descargarPdf() async {
    setState(() => _generandoPdf = true);
    try {
      await PdfPlanilla.compartir(
        _planilla,
        tarifa: _tarifa,
        empresa: GestorSesion.actual?.empresa,
      );
    } catch (_) {
      if (mounted) mostrarError(context, 'No fue posible generar el PDF de la planilla.');
    } finally {
      if (mounted) setState(() => _generandoPdf = false);
    }
  }

  Future<void> _registrarPago() async {
    final pago = await mostrarRegistroPago(
      context,
      numeroPlanilla: _planilla.numero,
    );
    if (pago == null || !mounted) return;
    mostrarExito(
      context,
      'Pago de ${Formato.moneda(pago.valorPagado)} registrado para ${_planilla.codigo}.',
    );
    _refrescar();
  }

  Future<void> _anular() async {
    final motivo = await solicitarMotivo(
      context,
      titulo: 'Anular planilla',
      mensaje:
          'La planilla ${_planilla.codigo} quedará anulada y no podrá usarse para operar. Indica el motivo.',
      etiqueta: 'Motivo de la anulación',
      textoConfirmar: 'Anular',
    );
    if (motivo == null || !mounted) return;

    setState(() => _procesando = true);
    try {
      await _servicio.anular(_planilla.numero, motivo);
      if (!mounted) return;
      mostrarExito(context, 'Planilla ${_planilla.codigo} anulada.');
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
    final p = _planilla;
    final puedePagar = !p.pagada && !p.anulada;
    final puedeAnular = p.estado == EstadoPlanilla.activa;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Detalle de planilla',
        subtitulo: p.codigo,
        acciones: [
          if (puedeAnular)
            PopupMenuButton<String>(
              tooltip: 'Más opciones',
              icon: Icon(Icons.more_vert, color: c.primarioOscuro),
              onSelected: (_) => _anular(),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'anular',
                  child: ListTile(
                    leading: Icon(Icons.block, color: AppColors.rojoAlerta),
                    title: Text('Anular planilla'),
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
              TarjetaBase(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const IconoCaja(icono: Icons.description_outlined, tamano: 56),
                    const SizedBox(height: 10),
                    Text(
                      p.codigo,
                      style: AppTheme.montserrat(
                        size: 22,
                        weight: FontWeight.w800,
                        color: c.primarioOscuro,
                      ),
                    ),
                    Text(
                      '${Fechas.fechaLargaSegura(p.fecha)} · ${Fechas.horaTexto(p.hora)}',
                      style: AppTheme.inter(size: 12.5, color: c.textoSutil),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        ChipEstado(
                          texto: Formato.capitalizar(p.estado),
                          tono: tonoPlanilla(p.estado),
                        ),
                        ChipEstado(
                          texto: p.pagada ? 'Pagada' : 'Pago pendiente',
                          tono: p.pagada ? TonoEstado.exito : TonoEstado.alerta,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (p.anulada) ...[
                const SizedBox(height: 12),
                const Aviso(
                  titulo: 'Planilla anulada',
                  mensaje: 'Este documento no autoriza la operación del vehículo.',
                  tono: TonoEstado.peligro,
                  icono: Icons.block,
                ),
              ],
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Operación',
                icono: Icons.route_outlined,
                children: [
                  GrillaDatos(
                    datos: [
                      FilaDato(etiqueta: 'Número', valor: '${p.numero}'),
                      FilaDato(etiqueta: 'Tipo', valor: TipoPlanilla.etiqueta(p.tipo)),
                      FilaDato(etiqueta: 'Fecha', valor: Fechas.corta(p.fecha)),
                      FilaDato(etiqueta: 'Hora', valor: Fechas.horaTexto(p.hora)),
                    ],
                  ),
                  FilaDato(
                    icono: Icons.directions_car_outlined,
                    etiqueta: 'Vehículo',
                    valor: p.placaVehiculo,
                  ),
                  FilaDato(
                    icono: Icons.badge_outlined,
                    etiqueta: p.identificacionConductor == null
                        ? 'Conductor'
                        : 'Conductor · C.C. ${p.identificacionConductor}',
                    valor: Formato.valorO(p.nombreConductor, 'Sin conductor asignado'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Tarifa y pago',
                icono: Icons.payments_outlined,
                children: [
                  FilaDato(
                    icono: Icons.sell_outlined,
                    etiqueta: 'Tarifa aplicada',
                    valor: _tarifa != null
                        ? '${_tarifa!.nombre} · ${Formato.moneda(_tarifa!.total)}'
                        : p.tarifaId == null
                        ? 'Sin tarifa'
                        : 'Tarifa N.° ${p.tarifaId}',
                  ),
                  GrillaDatos(
                    datos: [
                      FilaDato(
                        etiqueta: 'Valor pagado',
                        valor: Formato.moneda(p.valorPagado),
                        destacado: true,
                      ),
                      FilaDato(
                        etiqueta: 'Fecha de pago',
                        valor: p.fechaPago == null
                            ? 'Pendiente'
                            : Fechas.corta(p.fechaPago),
                      ),
                    ],
                  ),
                  if (p.registradoPorPago != null)
                    FilaDato(
                      icono: Icons.person_pin_outlined,
                      etiqueta: 'Pago registrado por',
                      valor: p.registradoPorPago!,
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
                    etiqueta: 'Registrada por',
                    valor: Formato.valorO(p.registradoPor, 'Sistema'),
                  ),
                  FilaDato(
                    icono: Icons.event_note_outlined,
                    etiqueta: 'Fecha de registro',
                    valor: Fechas.fechaHora(p.fechaRegistro),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PieAcciones(
        children: [
          BotonSecundario(
            texto: 'Descargar PDF',
            icono: Icons.picture_as_pdf_outlined,
            alPresionar: _generandoPdf ? null : _descargarPdf,
          ),
          if (puedePagar)
            BotonPrincipal(
              texto: 'Registrar pago',
              alPresionar: _registrarPago,
              cargando: _procesando,
            ),
        ],
      ),
    );
  }
}
