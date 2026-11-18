import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/planilla/planilla.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/planillas/detalle_planilla_screen.dart';
import 'package:transcoorp/screens/planillas/generar_planillas_screen.dart';
import 'package:transcoorp/screens/planillas/listado_pagos_screen.dart';
import 'package:transcoorp/services/remote/planilla_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/filtros.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';
import 'package:transcoorp/widgets/vista_paginada.dart';

TonoEstado tonoPlanilla(String estado) => switch (estado) {
  EstadoPlanilla.activa => TonoEstado.exito,
  EstadoPlanilla.finalizada => TonoEstado.info,
  EstadoPlanilla.anulada => TonoEstado.peligro,
  _ => TonoEstado.neutro,
};

class ListadoPlanillasScreen extends StatefulWidget {
  const ListadoPlanillasScreen({super.key, this.alVolver});

  final VoidCallback? alVolver;

  @override
  State<ListadoPlanillasScreen> createState() => _ListadoPlanillasScreenState();
}

class _ListadoPlanillasScreenState extends State<ListadoPlanillasScreen> {
  final PlanillaService _servicio = PlanillaService();
  late final ControladorPaginado<Planilla> _controlador =
      ControladorPaginado(_cargar);

  String _vehiculo = '';
  DateTime? _fecha;
  String? _estado;

  @override
  void initState() {
    super.initState();
    _controlador.recargar();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<Pagina<Planilla>> _cargar(int pagina) => _servicio.listar(
    pagina: pagina,
    fecha: _fecha,
    vehiculo: _vehiculo,
    estado: _estado,
  );

  Future<void> _generar() async {
    final generadas = await abrir<bool>(context, const GenerarPlanillasScreen());
    if (generadas == true && mounted) _controlador.recargar();
  }

  Future<void> _verDetalle(Planilla planilla) async {
    await abrir(context, DetallePlanillaScreen(planilla: planilla));
    if (mounted) _controlador.recargar();
  }

  void _limpiar() {
    setState(() {
      _fecha = null;
      _estado = null;
    });
    _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final hayFiltros = _fecha != null || _estado != null || _vehiculo.isNotEmpty;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Planillas',
        subtitulo: 'Control y autorización de operación',
        alVolver: widget.alVolver,
        acciones: [
          IconButton(
            tooltip: 'Pagos de planillas',
            icon: Icon(Icons.receipt_long_outlined, color: c.primarioOscuro),
            onPressed: () => abrir(context, const ListadoPagosScreen()),
          ),
          AccionEncabezado(
            icono: Icons.post_add,
            tooltip: 'Generar planillas',
            alPresionar: _generar,
          ),
        ],
      ),
      body: PantallaLista(
        filtros: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoBusqueda(
              hint: 'Buscar por placa del vehículo',
              mayusculas: true,
              alBuscar: (texto) {
                _vehiculo = texto.toUpperCase();
                _controlador.recargar();
              },
            ),
            const SizedBox(height: 12),
            BarraFiltros<String?>(
              seleccionado: _estado,
              alCambiar: (valor) {
                setState(() => _estado = valor);
                _controlador.recargar();
              },
              extra: [
                FiltroFecha(
                  etiqueta: 'Fecha',
                  valor: _fecha,
                  alCambiar: (fecha) {
                    setState(() => _fecha = fecha);
                    _controlador.recargar();
                  },
                ),
              ],
              opciones: const [
                OpcionFiltro(null, 'Todas'),
                OpcionFiltro(EstadoPlanilla.activa, 'Activas'),
                OpcionFiltro(EstadoPlanilla.finalizada, 'Finalizadas'),
                OpcionFiltro(EstadoPlanilla.anulada, 'Anuladas'),
              ],
            ),
          ],
        ),
        lista: VistaPaginada<Planilla>(
          controlador: _controlador,
          constructor: (context, planilla) => _TarjetaPlanilla(
            planilla: planilla,
            alTocar: () => _verDetalle(planilla),
          ),
          vacio: hayFiltros
              ? EstadoVacio(
                  icono: Icons.search_off,
                  titulo: 'Sin planillas para estos filtros',
                  mensaje: 'Prueba con otra fecha, estado o placa.',
                  textoAccion: 'Limpiar filtros',
                  iconoAccion: Icons.filter_alt_off_outlined,
                  alAccion: _limpiar,
                )
              : EstadoVacio(
                  icono: Icons.description_outlined,
                  titulo: 'Aún no hay planillas',
                  mensaje: 'Genera planillas para uno o varios vehículos en una sola operación.',
                  textoAccion: 'Generar planillas',
                  iconoAccion: Icons.post_add,
                  alAccion: _generar,
                ),
        ),
      ),
    );
  }
}

class _TarjetaPlanilla extends StatelessWidget {
  const _TarjetaPlanilla({required this.planilla, required this.alTocar});

  final Planilla planilla;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final p = planilla;

    return TarjetaBase(
      alTocar: alTocar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconoCaja(icono: Icons.description_outlined, tamano: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.codigo,
                      style: AppTheme.montserrat(
                        size: 15,
                        weight: FontWeight.w700,
                        color: c.textoOscuro,
                      ),
                    ),
                    Text(
                      '${Fechas.media(p.fecha)} · ${Fechas.horaTexto(p.hora)}',
                      style: AppTheme.inter(size: 12, color: c.textoSutil),
                    ),
                  ],
                ),
              ),
              ChipEstado(
                texto: Formato.capitalizar(p.estado),
                tono: tonoPlanilla(p.estado),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              PlacaVehiculo(placa: p.placaVehiculo),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  Formato.valorO(p.nombreConductor, 'Sin conductor'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(
                    size: 13,
                    weight: FontWeight.w500,
                    color: c.textoGris,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ChipEstado(
                texto: TipoPlanilla.etiqueta(p.tipo),
                tono: TonoEstado.info,
                icono: Icons.local_offer_outlined,
              ),
              const SizedBox(width: 6),
              ChipEstado(
                texto: p.pagada ? 'Pagada' : 'Pago pendiente',
                tono: p.pagada ? TonoEstado.exito : TonoEstado.alerta,
                icono: p.pagada ? Icons.check : Icons.schedule,
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: c.textoSutil),
            ],
          ),
        ],
      ),
    );
  }
}
