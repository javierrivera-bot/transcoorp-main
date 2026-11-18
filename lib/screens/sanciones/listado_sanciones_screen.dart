import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/sancion/sancion.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/sanciones/detalle_sancion_screen.dart';
import 'package:transcoorp/screens/sanciones/formulario_sancion_screen.dart';
import 'package:transcoorp/services/local/gestor_sesion.dart';
import 'package:transcoorp/services/remote/sancion_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/filtros.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';
import 'package:transcoorp/widgets/vista_paginada.dart';

class ChipSancion extends StatelessWidget {
  const ChipSancion({super.key, required this.sancion});

  final Sancion sancion;

  @override
  Widget build(BuildContext context) {
    return switch (sancion.estadoVista) {
      EstadoSancionVista.vigente => const ChipEstado(
        texto: 'Vigente',
        tono: TonoEstado.peligro,
        icono: Icons.block,
      ),
      EstadoSancionVista.programada => const ChipEstado(
        texto: 'Programada',
        tono: TonoEstado.alerta,
        icono: Icons.schedule,
      ),
      EstadoSancionVista.finalizada => const ChipEstado(
        texto: 'Finalizada',
        tono: TonoEstado.neutro,
        icono: Icons.check,
      ),
      EstadoSancionVista.anulada => const ChipEstado(
        texto: 'Anulada',
        tono: TonoEstado.info,
        icono: Icons.undo,
      ),
    };
  }
}

class ListadoSancionesScreen extends StatefulWidget {
  const ListadoSancionesScreen({super.key, this.conductor});

  final String? conductor;

  @override
  State<ListadoSancionesScreen> createState() => _ListadoSancionesScreenState();
}

class _ListadoSancionesScreenState extends State<ListadoSancionesScreen> {
  final SancionService _servicio = SancionService();
  late final ControladorPaginado<Sancion> _controlador =
      ControladorPaginado(_cargar);

  late String _conductor = widget.conductor ?? '';
  String? _estado;

  bool get _puedeSancionar => GestorSesion.actual?.puedeSancionar ?? false;

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

  Future<Pagina<Sancion>> _cargar(int pagina) async {
    final resultado = await _servicio.listar(
      pagina: pagina,
      conductor: _conductor,
      estado: _estado,
    );
    if (widget.conductor == null) return resultado;
    final items = resultado.items
        .where((s) => s.identificacionConductor == widget.conductor)
        .toList();
    return Pagina(
      items: items,
      pagina: resultado.pagina,
      totalPaginas: resultado.totalPaginas,
      totalItems: resultado.totalItems,
    );
  }

  Future<void> _registrar() async {
    final registrada = await abrir<Sancion>(
      context,
      const FormularioSancionScreen(),
    );
    if (registrada == null || !mounted) return;
    mostrarExito(
      context,
      'Sanción registrada para ${registrada.nombresConductor.isEmpty ? 'el conductor' : registrada.nombresConductor}.',
    );
    _controlador.recargar();
  }

  Future<void> _verDetalle(Sancion sancion) async {
    await abrir(context, DetalleSancionScreen(sancion: sancion));
    if (mounted) _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: widget.conductor == null ? 'Sanciones' : 'Historial de sanciones',
        subtitulo: widget.conductor == null
            ? 'Control disciplinario de conductores'
            : 'Conductor C.C. ${widget.conductor}',
        acciones: [
          if (_puedeSancionar && widget.conductor == null)
            AccionEncabezado(
              icono: Icons.gavel,
              tooltip: 'Registrar sanción',
              alPresionar: _registrar,
            ),
        ],
      ),
      body: PantallaLista(
        filtros: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.conductor == null) ...[
              CampoBusqueda(
                hint: 'Buscar por identificación del conductor',
                teclado: TextInputType.number,
                alBuscar: (texto) {
                  _conductor = texto;
                  _controlador.recargar();
                },
              ),
              const SizedBox(height: 12),
            ],
            BarraFiltros<String?>(
              seleccionado: _estado,
              alCambiar: (valor) {
                setState(() => _estado = valor);
                _controlador.recargar();
              },
              opciones: const [
                OpcionFiltro(null, 'Todas'),
                OpcionFiltro(EstadoSancion.activa, 'Activas'),
                OpcionFiltro(EstadoSancion.cumplida, 'Cumplidas'),
                OpcionFiltro(EstadoSancion.anulada, 'Anuladas'),
              ],
            ),
          ],
        ),
        lista: VistaPaginada<Sancion>(
          controlador: _controlador,
          constructor: (context, sancion) => _TarjetaSancion(
            sancion: sancion,
            alTocar: () => _verDetalle(sancion),
          ),
          vacio: EstadoVacio(
            icono: Icons.verified_outlined,
            titulo: 'Sin sanciones',
            mensaje: 'No hay sanciones registradas con los filtros seleccionados.',
            textoAccion: _puedeSancionar && widget.conductor == null
                ? 'Registrar sanción'
                : null,
            iconoAccion: Icons.gavel,
            alAccion: _puedeSancionar ? _registrar : null,
          ),
        ),
      ),
    );
  }
}

class _TarjetaSancion extends StatelessWidget {
  const _TarjetaSancion({required this.sancion, required this.alTocar});

  final Sancion sancion;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final vigente = sancion.vigente;

    return TarjetaBase(
      alTocar: alTocar,
      colorBorde: vigente ? AppColors.rojoAlerta.withValues(alpha: 0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconoCaja(
                icono: Icons.gavel,
                tamano: 38,
                color: vigente ? AppColors.rojoAlerta : c.primario,
                fondo: vigente
                    ? AppColors.rojoAlerta.withValues(alpha: 0.1)
                    : c.badgeFondo,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sancion.nombresConductor.isEmpty
                          ? 'Conductor'
                          : sancion.nombresConductor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.montserrat(
                        size: 15,
                        weight: FontWeight.w600,
                        color: c.textoOscuro,
                      ),
                    ),
                    Text(
                      'C.C. ${sancion.identificacionConductor}',
                      style: AppTheme.inter(size: 12, color: c.textoSutil),
                    ),
                  ],
                ),
              ),
              ChipSancion(sancion: sancion),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sancion.motivo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.inter(size: 13, color: c.textoGris),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.date_range, size: 15, color: c.textoSutil),
              const SizedBox(width: 6),
              Text(
                '${Fechas.corta(sancion.fechaInicio)} — ${Fechas.corta(sancion.fechaFin)}',
                style: AppTheme.inter(
                  size: 12,
                  weight: FontWeight.w500,
                  color: c.textoSutil,
                ),
              ),
              const Spacer(),
              Text(
                '${sancion.duracionDias} ${sancion.duracionDias == 1 ? 'día' : 'días'}',
                style: AppTheme.inter(size: 12, color: c.textoSutil),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
