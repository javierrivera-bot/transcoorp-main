import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/sancion/sancion.dart';
import 'package:transcoorp/screens/sanciones/listado_sanciones_screen.dart';
import 'package:transcoorp/services/local/gestor_sesion.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/sancion_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';

class DetalleSancionScreen extends StatefulWidget {
  const DetalleSancionScreen({super.key, required this.sancion});

  final Sancion sancion;

  @override
  State<DetalleSancionScreen> createState() => _DetalleSancionScreenState();
}

class _DetalleSancionScreenState extends State<DetalleSancionScreen> {
  final SancionService _servicio = SancionService();

  late Sancion _sancion = widget.sancion;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  Future<void> _refrescar() async {
    try {
      final actual = await _servicio.obtenerPorId(_sancion.id);
      if (mounted) setState(() => _sancion = actual);
    } on ApiException catch (_) {}
  }

  Future<void> _anular() async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Anular sanción',
      mensaje:
          'El conductor quedará habilitado nuevamente si no tiene otras sanciones. El registro se conservará en el historial como anulado.',
      textoConfirmar: 'Anular sanción',
      peligrosa: true,
      icono: Icons.undo,
    );
    if (!confirmado || !mounted) return;

    setState(() => _procesando = true);
    try {
      final actualizada = await _servicio.anular(_sancion);
      if (!mounted) return;
      setState(() => _sancion = actualizada);
      mostrarExito(context, 'Sanción anulada.');
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final s = _sancion;
    final puedeAnular = (GestorSesion.actual?.puedeSancionar ?? false) &&
        s.estado == EstadoSancion.activa &&
        s.estadoVista != EstadoSancionVista.finalizada;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Detalle de sanción',
        subtitulo: 'Registro N.° ${s.id}',
      ),
      body: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (s.vigente) ...[
              Aviso(
                titulo: 'Sanción vigente',
                mensaje:
                    'El conductor no puede ser asignado a operaciones hasta el ${Fechas.corta(s.fechaFin)} (${Fechas.diasHasta(s.fechaFin) + 1} días restantes).',
                tono: TonoEstado.peligro,
                icono: Icons.block,
              ),
              const SizedBox(height: 12),
            ],
            TarjetaBase(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  AvatarIniciales(
                    texto: Formato.iniciales(s.nombresConductor),
                    tamano: 56,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ChipSancion(sancion: s),
                        const SizedBox(height: 6),
                        Text(
                          s.nombresConductor.isEmpty
                              ? 'Conductor'
                              : s.nombresConductor,
                          style: AppTheme.montserrat(
                            size: 17,
                            weight: FontWeight.w700,
                            color: c.textoOscuro,
                          ),
                        ),
                        Text(
                          'C.C. ${s.identificacionConductor}',
                          style: AppTheme.inter(size: 12.5, color: c.textoSutil),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SeccionDetalle(
              titulo: 'Periodo de sanción',
              icono: Icons.date_range,
              children: [
                GrillaDatos(
                  datos: [
                    FilaDato(
                      etiqueta: 'Fecha inicial',
                      valor: Fechas.corta(s.fechaInicio),
                      destacado: true,
                    ),
                    FilaDato(
                      etiqueta: 'Fecha final',
                      valor: Fechas.corta(s.fechaFin),
                      destacado: true,
                    ),
                  ],
                ),
                FilaDato(
                  icono: Icons.timelapse,
                  etiqueta: 'Duración',
                  valor:
                      '${s.duracionDias} ${s.duracionDias == 1 ? 'día' : 'días'}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SeccionDetalle(
              titulo: 'Motivo',
              icono: Icons.description_outlined,
              children: [
                FilaDato(etiqueta: 'Motivo de la sanción', valor: s.motivo),
                FilaDato(
                  etiqueta: 'Observaciones',
                  valor: s.observaciones ?? 'Sin observaciones',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SeccionDetalle(
              titulo: 'Trazabilidad',
              icono: Icons.manage_history,
              children: [
                FilaDato(
                  icono: Icons.person_pin_outlined,
                  etiqueta: 'Registrada por',
                  valor: s.registradoPor ?? 'Gerencia / Asistencia administrativa',
                ),
                GrillaDatos(
                  datos: [
                    FilaDato(
                      etiqueta: 'Fecha de registro',
                      valor: Fechas.fechaHora(s.fechaRegistro),
                    ),
                    FilaDato(
                      etiqueta: 'Última actualización',
                      valor: Fechas.fechaHora(
                        s.ultimaActualizacion ?? s.fechaRegistro,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: puedeAnular
          ? PieAcciones(
              children: [
                BotonSecundario(
                  texto: 'Anular sanción',
                  icono: Icons.undo,
                  peligro: true,
                  alPresionar: _procesando ? null : _anular,
                ),
              ],
            )
          : null,
    );
  }
}
