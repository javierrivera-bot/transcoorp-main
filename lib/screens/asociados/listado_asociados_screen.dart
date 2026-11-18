import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/models/asociado/asociado.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/asociados/detalle_asociado_screen.dart';
import 'package:transcoorp/screens/asociados/formulario_asociado_screen.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/asociado_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/filtros.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';
import 'package:transcoorp/widgets/vista_paginada.dart';

enum _FiltroEstado { todos, activos, inactivos }

class ListadoAsociadosScreen extends StatefulWidget {
  const ListadoAsociadosScreen({super.key});

  @override
  State<ListadoAsociadosScreen> createState() => _ListadoAsociadosScreenState();
}

class _ListadoAsociadosScreenState extends State<ListadoAsociadosScreen> {
  final AsociadoService _servicio = AsociadoService();
  late final ControladorPaginado<Asociado> _controlador =
      ControladorPaginado(_cargar);

  String _consulta = '';
  _FiltroEstado _filtro = _FiltroEstado.todos;

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

  bool? get _activo => switch (_filtro) {
    _FiltroEstado.todos => null,
    _FiltroEstado.activos => true,
    _FiltroEstado.inactivos => false,
  };

  Future<Pagina<Asociado>> _cargar(int pagina) async {
    final esIdentificacion = RegExp(r'^\d{3,}$').hasMatch(_consulta);
    if (!esIdentificacion) {
      return _servicio.listar(
        pagina: pagina,
        nombres: _consulta,
        activo: _activo,
      );
    }
    try {
      final asociado = await _servicio.obtenerPorId(_consulta);
      final coincide = _activo == null || asociado.activo == _activo;
      final items = coincide ? [asociado] : <Asociado>[];
      return Pagina(
        items: items,
        pagina: 1,
        totalPaginas: 1,
        totalItems: items.length,
      );
    } on ApiException catch (e) {
      if (e.noEncontrado) {
        return const Pagina(items: [], pagina: 1, totalPaginas: 1, totalItems: 0);
      }
      rethrow;
    }
  }

  void _buscar(String consulta) {
    _consulta = consulta;
    _controlador.recargar();
  }

  void _filtrar(_FiltroEstado filtro) {
    setState(() => _filtro = filtro);
    _controlador.recargar();
  }

  void _limpiarFiltros() {
    setState(() => _filtro = _FiltroEstado.todos);
    _buscar('');
  }

  Future<void> _registrar() async {
    final creado = await abrir<Asociado>(
      context,
      const FormularioAsociadoScreen(),
    );
    if (creado == null || !mounted) return;
    mostrarExito(context, 'Asociado ${creado.nombres} registrado correctamente.');
    _controlador.recargar();
  }

  Future<void> _verDetalle(Asociado asociado) async {
    await abrir(context, DetalleAsociadoScreen(asociado: asociado));
    if (mounted) _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final hayFiltros = _consulta.isNotEmpty || _filtro != _FiltroEstado.todos;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Asociados',
        subtitulo: 'Socios vinculados a la cooperativa',
        acciones: [
          AccionEncabezado(
            icono: Icons.person_add_alt_1_outlined,
            tooltip: 'Registrar asociado',
            alPresionar: _registrar,
          ),
        ],
      ),
      body: PantallaLista(
        filtros: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoBusqueda(
              hint: 'Buscar por identificación o nombres',
              alBuscar: _buscar,
            ),
            const SizedBox(height: 12),
            BarraFiltros<_FiltroEstado>(
              seleccionado: _filtro,
              alCambiar: _filtrar,
              opciones: const [
                OpcionFiltro(_FiltroEstado.todos, 'Todos'),
                OpcionFiltro(_FiltroEstado.activos, 'Activos'),
                OpcionFiltro(_FiltroEstado.inactivos, 'Inactivos'),
              ],
            ),
          ],
        ),
        lista: VistaPaginada<Asociado>(
          controlador: _controlador,
          cabecera: ListenableBuilder(
            listenable: _controlador,
            builder: (context, _) => ContadorResultados(
              mostrados: _controlador.items.length,
              total: _controlador.totalItems,
              sustantivo: 'asociados',
            ),
          ),
          constructor: (context, asociado) => _TarjetaAsociado(
            asociado: asociado,
            alTocar: () => _verDetalle(asociado),
          ),
          vacio: hayFiltros
              ? EstadoVacio(
                  icono: Icons.search_off,
                  titulo: 'Sin coincidencias',
                  mensaje: 'Ningún asociado coincide con la búsqueda o el filtro.',
                  textoAccion: 'Limpiar filtros',
                  iconoAccion: Icons.filter_alt_off_outlined,
                  alAccion: _limpiarFiltros,
                )
              : EstadoVacio(
                  icono: Icons.groups_outlined,
                  titulo: 'Aún no hay asociados',
                  mensaje: 'Registra el primer asociado de la cooperativa.',
                  textoAccion: 'Registrar asociado',
                  alAccion: _registrar,
                ),
        ),
      ),
    );
  }
}

class _TarjetaAsociado extends StatelessWidget {
  const _TarjetaAsociado({required this.asociado, required this.alTocar});

  final Asociado asociado;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return TarjetaBase(
      alTocar: alTocar,
      child: Row(
        children: [
          AvatarIniciales(texto: asociado.iniciales),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asociado.nombres,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.montserrat(
                    size: 15,
                    weight: FontWeight.w600,
                    color: c.textoOscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'C.C. ${asociado.identificacion}',
                  style: AppTheme.inter(size: 12, color: c.textoSutil),
                ),
                if (asociado.celular != null)
                  Text(
                    'Cel. ${asociado.celular}',
                    style: AppTheme.inter(size: 12, color: c.textoSutil),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ChipEstado.activo(asociado.activo),
              const SizedBox(height: 8),
              Icon(Icons.chevron_right, color: c.textoSutil),
            ],
          ),
        ],
      ),
    );
  }
}
