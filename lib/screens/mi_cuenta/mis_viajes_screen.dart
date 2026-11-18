import 'package:flutter/material.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/despacho/despacho.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/despachos/detalle_despacho_screen.dart';
import 'package:transcoorp/services/remote/despacho_service.dart';
import 'package:transcoorp/services/remote/mi_cuenta_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/filtros.dart';
import 'package:transcoorp/widgets/tarjeta_despacho.dart';
import 'package:transcoorp/widgets/vista_paginada.dart';

class MisViajesScreen extends StatefulWidget {
  const MisViajesScreen({super.key, this.alVolver});

  final VoidCallback? alVolver;

  @override
  State<MisViajesScreen> createState() => _MisViajesScreenState();
}

class _MisViajesScreenState extends State<MisViajesScreen> {
  final DespachoService _servicio = DespachoService();
  late final ControladorPaginado<Despacho> _controlador =
      ControladorPaginado(_cargar);

  List<VehiculoAsociado> _vehiculos = const [];
  DateTime? _desde;
  DateTime? _hasta;
  String _placa = '';

  @override
  void initState() {
    super.initState();
    _controlador.recargar();
    _cargarVehiculos();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _cargarVehiculos() async {
    try {
      final vehiculos = await MiCuentaService().misVehiculos();
      if (mounted) setState(() => _vehiculos = vehiculos);
    } catch (_) {}
  }

  Future<Pagina<Despacho>> _cargar(int pagina) => _servicio.misDespachos(
    pagina: pagina,
    desde: _desde,
    hasta: _hasta,
    placa: _placa,
  );

  void _limpiar() {
    setState(() {
      _desde = null;
      _hasta = null;
      _placa = '';
    });
    _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final hayFiltros = _desde != null || _hasta != null || _placa.isNotEmpty;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Mis viajes',
        subtitulo: 'Despachos de tus vehículos',
        alVolver: widget.alVolver,
      ),
      body: PantallaLista(
        filtros: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FiltroFecha(
                    etiqueta: 'Desde',
                    valor: _desde,
                    alCambiar: (fecha) {
                      setState(() => _desde = fecha);
                      _controlador.recargar();
                    },
                  ),
                  const SizedBox(width: 8),
                  FiltroFecha(
                    etiqueta: 'Hasta',
                    valor: _hasta,
                    alCambiar: (fecha) {
                      setState(() => _hasta = fecha);
                      _controlador.recargar();
                    },
                  ),
                ],
              ),
            ),
            if (_vehiculos.length > 1) ...[
              const SizedBox(height: 8),
              BarraFiltros<String>(
                seleccionado: _placa,
                alCambiar: (valor) {
                  setState(() => _placa = valor);
                  _controlador.recargar();
                },
                opciones: [
                  const OpcionFiltro('', 'Todas las placas'),
                  for (final vehiculo in _vehiculos)
                    OpcionFiltro(vehiculo.placa, vehiculo.placa),
                ],
              ),
            ],
          ],
        ),
        lista: VistaPaginada<Despacho>(
          controlador: _controlador,
          constructor: (context, despacho) => TarjetaDespacho(
            despacho: despacho,
            alTocar: () => abrir(context, DetalleDespachoScreen(despacho: despacho)),
          ),
          vacio: hayFiltros
              ? EstadoVacio(
                  icono: Icons.search_off,
                  titulo: 'Sin viajes en este periodo',
                  mensaje: 'Ajusta las fechas o la placa para ver más resultados.',
                  textoAccion: 'Limpiar filtros',
                  iconoAccion: Icons.filter_alt_off_outlined,
                  alAccion: _limpiar,
                )
              : const EstadoVacio(
                  icono: Icons.route_outlined,
                  titulo: 'Aún no hay viajes',
                  mensaje: 'Los despachos de tus vehículos aparecerán aquí.',
                ),
        ),
      ),
    );
  }
}
