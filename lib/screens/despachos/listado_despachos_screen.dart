import 'package:flutter/material.dart';
import 'package:transcoorp/domain/rutas.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/despacho/despacho.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/despachos/detalle_despacho_screen.dart';
import 'package:transcoorp/screens/despachos/formulario_despacho_screen.dart';
import 'package:transcoorp/services/remote/despacho_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/filtros.dart';
import 'package:transcoorp/widgets/tarjeta_despacho.dart';
import 'package:transcoorp/widgets/vista_paginada.dart';

class ListadoDespachosScreen extends StatefulWidget {
  const ListadoDespachosScreen({super.key});

  @override
  State<ListadoDespachosScreen> createState() => _ListadoDespachosScreenState();
}

class _ListadoDespachosScreenState extends State<ListadoDespachosScreen> {
  final DespachoService _servicio = DespachoService();
  late final ControladorPaginado<Despacho> _controlador =
      ControladorPaginado(_cargar);

  String _vehiculo = '';
  String _ruta = '';
  DateTime? _fecha;

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

  Future<Pagina<Despacho>> _cargar(int pagina) => _servicio.listar(
    pagina: pagina,
    fecha: _fecha,
    vehiculo: _vehiculo,
    ruta: _ruta,
  );

  Future<void> _registrar() async {
    final creado = await abrir<Despacho>(context, const FormularioDespachoScreen());
    if (creado == null || !mounted) return;
    mostrarExito(context, 'Despacho del vehículo ${creado.placaVehiculo} registrado.');
    _controlador.recargar();
  }

  Future<void> _verDetalle(Despacho despacho) async {
    await abrir(context, DetalleDespachoScreen(despacho: despacho));
    if (mounted) _controlador.recargar();
  }

  void _limpiar() {
    setState(() {
      _fecha = null;
      _ruta = '';
    });
    _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final hayFiltros = _fecha != null || _ruta.isNotEmpty || _vehiculo.isNotEmpty;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Despachos',
        subtitulo: 'Salidas autorizadas de vehículos',
        acciones: [
          AccionEncabezado(
            icono: Icons.add_road,
            tooltip: 'Registrar despacho',
            alPresionar: _registrar,
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
            BarraFiltros<String>(
              seleccionado: _ruta,
              alCambiar: (valor) {
                setState(() => _ruta = valor);
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
              opciones: [
                const OpcionFiltro('', 'Todas las rutas'),
                for (final ruta in CatalogoRutas.rutas)
                  OpcionFiltro(ruta.etiqueta, ruta.codigo),
              ],
            ),
          ],
        ),
        lista: VistaPaginada<Despacho>(
          controlador: _controlador,
          constructor: (context, despacho) => TarjetaDespacho(
            despacho: despacho,
            alTocar: () => _verDetalle(despacho),
          ),
          vacio: hayFiltros
              ? EstadoVacio(
                  icono: Icons.search_off,
                  titulo: 'Sin despachos para estos filtros',
                  mensaje: 'Prueba con otra fecha, ruta o placa.',
                  textoAccion: 'Limpiar filtros',
                  iconoAccion: Icons.filter_alt_off_outlined,
                  alAccion: _limpiar,
                )
              : EstadoVacio(
                  icono: Icons.departure_board_outlined,
                  titulo: 'Sin despachos registrados',
                  mensaje: 'Registra la salida de un vehículo hacia una ruta.',
                  textoAccion: 'Registrar despacho',
                  alAccion: _registrar,
                ),
        ),
      ),
    );
  }
}
