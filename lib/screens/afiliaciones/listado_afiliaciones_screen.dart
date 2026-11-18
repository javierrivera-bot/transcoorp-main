import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/afiliacion/afiliacion.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/afiliaciones/detalle_afiliacion_screen.dart';
import 'package:transcoorp/screens/afiliaciones/formulario_afiliacion_screen.dart';
import 'package:transcoorp/services/remote/afiliacion_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/filtros.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';
import 'package:transcoorp/widgets/vista_paginada.dart';

TonoEstado tonoAfiliacion(String estado) => switch (estado) {
  EstadoAfiliacion.activa => TonoEstado.exito,
  EstadoAfiliacion.suspendida => TonoEstado.alerta,
  EstadoAfiliacion.finalizada => TonoEstado.info,
  _ => TonoEstado.neutro,
};

class ListadoAfiliacionesScreen extends StatefulWidget {
  const ListadoAfiliacionesScreen({super.key, this.asociado});

  final String? asociado;

  @override
  State<ListadoAfiliacionesScreen> createState() =>
      _ListadoAfiliacionesScreenState();
}

class _ListadoAfiliacionesScreenState extends State<ListadoAfiliacionesScreen> {
  final AfiliacionService _servicio = AfiliacionService();
  late final ControladorPaginado<Afiliacion> _controlador =
      ControladorPaginado(_cargar);

  late String _asociado = widget.asociado ?? '';
  String _vehiculo = '';
  String? _estado;
  bool _buscarPorPlaca = false;

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

  Future<Pagina<Afiliacion>> _cargar(int pagina) => _servicio.listar(
    pagina: pagina,
    asociado: _asociado,
    vehiculo: _vehiculo,
    estado: _estado,
  );

  void _buscar(String texto) {
    if (_buscarPorPlaca) {
      _vehiculo = texto.toUpperCase();
      _asociado = widget.asociado ?? '';
    } else {
      _asociado = texto;
      _vehiculo = '';
    }
    _controlador.recargar();
  }

  void _filtrarEstado(String? estado) {
    setState(() => _estado = estado);
    _controlador.recargar();
  }

  Future<void> _registrar() async {
    final creada = await abrir<Afiliacion>(
      context,
      FormularioAfiliacionScreen(identificacionAsociado: widget.asociado),
    );
    if (creada == null || !mounted) return;
    mostrarExito(context, 'Afiliación del vehículo ${creada.placaVehiculo} registrada.');
    _controlador.recargar();
  }

  Future<void> _verDetalle(Afiliacion afiliacion) async {
    await abrir(context, DetalleAfiliacionScreen(afiliacion: afiliacion));
    if (mounted) _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Afiliaciones',
        subtitulo: widget.asociado == null
            ? 'Vínculos entre asociados y vehículos'
            : 'Asociado C.C. ${widget.asociado}',
        acciones: [
          AccionEncabezado(
            icono: Icons.add_link,
            tooltip: 'Nueva afiliación',
            alPresionar: _registrar,
          ),
        ],
      ),
      body: PantallaLista(
        filtros: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: CampoBusqueda(
                    key: ValueKey(_buscarPorPlaca),
                    hint: _buscarPorPlaca
                        ? 'Filtrar por placa del vehículo'
                        : 'Filtrar por identificación del asociado',
                    mayusculas: _buscarPorPlaca,
                    alBuscar: _buscar,
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Icons.person_outline)),
                    ButtonSegment(value: true, icon: Icon(Icons.directions_car_outlined)),
                  ],
                  selected: {_buscarPorPlaca},
                  onSelectionChanged: (valor) {
                    setState(() => _buscarPorPlaca = valor.first);
                    _buscar('');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            BarraFiltros<String?>(
              seleccionado: _estado,
              alCambiar: _filtrarEstado,
              opciones: const [
                OpcionFiltro(null, 'Todas'),
                OpcionFiltro(EstadoAfiliacion.activa, 'Activas'),
                OpcionFiltro(EstadoAfiliacion.suspendida, 'Suspendidas'),
                OpcionFiltro(EstadoAfiliacion.finalizada, 'Finalizadas'),
                OpcionFiltro(EstadoAfiliacion.inactiva, 'Inactivas'),
              ],
            ),
          ],
        ),
        lista: VistaPaginada<Afiliacion>(
          controlador: _controlador,
          constructor: (context, afiliacion) => _TarjetaAfiliacion(
            afiliacion: afiliacion,
            alTocar: () => _verDetalle(afiliacion),
          ),
          vacio: EstadoVacio(
            icono: Icons.handshake_outlined,
            titulo: 'Sin afiliaciones',
            mensaje: 'No hay afiliaciones que coincidan con los filtros.',
            textoAccion: 'Nueva afiliación',
            alAccion: _registrar,
          ),
        ),
      ),
    );
  }
}

class _TarjetaAfiliacion extends StatelessWidget {
  const _TarjetaAfiliacion({required this.afiliacion, required this.alTocar});

  final Afiliacion afiliacion;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return TarjetaBase(
      alTocar: alTocar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlacaVehiculo(placa: afiliacion.placaVehiculo),
              const Spacer(),
              ChipEstado(
                texto: Formato.capitalizar(afiliacion.estado),
                tono: tonoAfiliacion(afiliacion.estado),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: c.textoSutil),
              const SizedBox(width: 6),
              Text(
                'Asociado C.C. ${afiliacion.identificacionAsociado}',
                style: AppTheme.inter(
                  size: 13,
                  weight: FontWeight.w500,
                  color: c.textoOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.event_available_outlined, size: 16, color: c.textoSutil),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  afiliacion.fechaFin == null
                      ? 'Desde ${Fechas.corta(afiliacion.fechaAfiliacion)}'
                      : '${Fechas.corta(afiliacion.fechaAfiliacion)} — ${Fechas.corta(afiliacion.fechaFin)}',
                  style: AppTheme.inter(size: 12.5, color: c.textoSutil),
                ),
              ),
              Text(
                'N.° ${afiliacion.id}',
                style: AppTheme.inter(size: 12, color: c.textoSutil),
              ),
              Icon(Icons.chevron_right, color: c.textoSutil),
            ],
          ),
        ],
      ),
    );
  }
}
