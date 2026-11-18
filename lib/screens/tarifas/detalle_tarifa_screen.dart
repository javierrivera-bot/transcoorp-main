import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/tarifa/tarifa.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/tarifa_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';

class DetalleTarifaScreen extends StatefulWidget {
  const DetalleTarifaScreen({super.key, required this.tarifa});

  final Tarifa tarifa;

  @override
  State<DetalleTarifaScreen> createState() => _DetalleTarifaScreenState();
}

class _DetalleTarifaScreenState extends State<DetalleTarifaScreen> {
  final TarifaService _servicio = TarifaService();

  late Tarifa _tarifa = widget.tarifa;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  Future<void> _refrescar() async {
    try {
      final actual = await _servicio.obtenerPorId(_tarifa.id);
      if (mounted) setState(() => _tarifa = actual);
    } on ApiException catch (_) {}
  }

  Future<void> _inactivar() async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Inactivar tarifa',
      mensaje:
          '${_tarifa.nombre} (${Formato.moneda(_tarifa.total)}) dejará de estar disponible para generar nuevas planillas. Las planillas existentes no se modifican.',
      textoConfirmar: 'Inactivar',
      peligrosa: true,
      icono: Icons.block,
    );
    if (!confirmado || !mounted) return;

    setState(() => _procesando = true);
    try {
      await _servicio.inactivar(_tarifa.id);
      if (!mounted) return;
      mostrarExito(context, '${_tarifa.nombre} inactivada.');
      await _refrescar();
      if (mounted && _tarifa.activo) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final t = _tarifa;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(titulo: 'Detalle de tarifa', subtitulo: t.nombre),
      body: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TarjetaBase(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  ChipEstado.activo(
                    t.activo,
                    textoActivo: 'Tarifa activa',
                    textoInactivo: 'Tarifa inactiva',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Valor total por planilla',
                    style: AppTheme.inter(size: 13, color: c.textoSutil),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formato.moneda(t.total),
                    style: AppTheme.montserrat(
                      size: 32,
                      weight: FontWeight.w800,
                      color: c.primarioOscuro,
                    ),
                  ),
                ],
              ),
            ),
            if (!t.activo) ...[
              const SizedBox(height: 12),
              const Aviso(
                titulo: 'No disponible para nuevas planillas',
                mensaje:
                    'Esta tarifa fue inactivada y se conserva únicamente como referencia histórica.',
                tono: TonoEstado.neutro,
              ),
            ],
            const SizedBox(height: 16),
            SeccionDetalle(
              titulo: 'Componentes de la tarifa',
              icono: Icons.pie_chart_outline,
              children: [
                FilaDato(
                  icono: Icons.receipt_outlined,
                  etiqueta: 'Aportes gastos varios',
                  valor: Formato.moneda(t.aportesGastosVarios),
                ),
                FilaDato(
                  icono: Icons.savings_outlined,
                  etiqueta: 'Fondo de reposición',
                  valor: Formato.moneda(t.fondoReposicion),
                ),
                FilaDato(
                  icono: Icons.volunteer_activism_outlined,
                  etiqueta: 'Aporte social del socio',
                  valor: Formato.moneda(t.aporteSocialSocio),
                ),
                FilaDato(
                  icono: Icons.functions,
                  etiqueta: 'Total',
                  valor: Formato.moneda(t.total),
                  destacado: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            PieTrazabilidad(
              registro: Fechas.corta(t.fechaRegistro),
              actualizacion: Fechas.corta(t.ultimaActualizacion ?? t.fechaRegistro),
            ),
          ],
        ),
      ),
      bottomNavigationBar: t.activo
          ? PieAcciones(
              children: [
                BotonSecundario(
                  texto: 'Inactivar tarifa',
                  icono: Icons.block,
                  peligro: true,
                  alPresionar: _procesando ? null : _inactivar,
                ),
              ],
            )
          : null,
    );
  }
}
