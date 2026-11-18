import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/conductor/conductor.dart';
import 'package:transcoorp/models/sancion/sancion.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/conductores/detalle_conductor_screen.dart';
import 'package:transcoorp/screens/conductores/formulario_conductor_screen.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/conductor_service.dart';
import 'package:transcoorp/services/remote/sancion_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/filtros.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';
import 'package:transcoorp/widgets/vista_paginada.dart';

class ListadoConductoresScreen extends StatefulWidget {
  const ListadoConductoresScreen({super.key});

  @override
  State<ListadoConductoresScreen> createState() =>
      _ListadoConductoresScreenState();
}

class _ListadoConductoresScreenState extends State<ListadoConductoresScreen> {
  final ConductorService _servicio = ConductorService();
  final SancionService _sanciones = SancionService();
  late final ControladorPaginado<Conductor> _controlador =
      ControladorPaginado(_cargar);

  Map<String, Sancion> _vigentes = const {};
  String _consulta = '';
  bool? _activo;

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

  Future<Pagina<Conductor>> _cargar(int pagina) async {
    if (pagina == 1) {
      try {
        final vigentes = await _sanciones.vigentesPorConductor();
        if (mounted) setState(() => _vigentes = vigentes);
      } catch (_) {}
    }

    if (RegExp(r'^\d{3,}$').hasMatch(_consulta)) {
      try {
        final conductor = await _servicio.obtenerPorId(_consulta);
        final coincide = _activo == null || conductor.activo == _activo;
        final items = coincide ? [conductor] : <Conductor>[];
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

    return _servicio.listar(pagina: pagina, nombres: _consulta, activo: _activo);
  }

  Future<void> _registrar() async {
    final creado = await abrir<Conductor>(
      context,
      const FormularioConductorScreen(),
    );
    if (creado == null || !mounted) return;
    mostrarExito(context, 'Conductor ${creado.nombres} registrado.');
    _controlador.recargar();
  }

  Future<void> _verDetalle(Conductor conductor) async {
    await abrir(context, DetalleConductorScreen(conductor: conductor));
    if (mounted) _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Conductores',
        subtitulo: 'Personal autorizado para operar',
        acciones: [
          AccionEncabezado(
            icono: Icons.person_add_alt_1_outlined,
            tooltip: 'Registrar conductor',
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
              alBuscar: (texto) {
                _consulta = texto;
                _controlador.recargar();
              },
            ),
            const SizedBox(height: 12),
            BarraFiltros<bool?>(
              seleccionado: _activo,
              alCambiar: (valor) {
                setState(() => _activo = valor);
                _controlador.recargar();
              },
              opciones: const [
                OpcionFiltro(null, 'Todos'),
                OpcionFiltro(true, 'Activos'),
                OpcionFiltro(false, 'Inactivos'),
              ],
            ),
          ],
        ),
        lista: VistaPaginada<Conductor>(
          controlador: _controlador,
          constructor: (context, conductor) => _TarjetaConductor(
            conductor: conductor,
            sancion: _vigentes[conductor.identificacion],
            alTocar: () => _verDetalle(conductor),
          ),
          vacio: EstadoVacio(
            icono: Icons.badge_outlined,
            titulo: 'Sin conductores',
            mensaje: _consulta.isEmpty && _activo == null
                ? 'Registra a los conductores autorizados de la cooperativa.'
                : 'Ningún conductor coincide con la búsqueda.',
            textoAccion: 'Registrar conductor',
            alAccion: _registrar,
          ),
        ),
      ),
    );
  }
}

class _TarjetaConductor extends StatelessWidget {
  const _TarjetaConductor({
    required this.conductor,
    required this.alTocar,
    this.sancion,
  });

  final Conductor conductor;
  final Sancion? sancion;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final sancionado = sancion != null;

    return TarjetaBase(
      alTocar: alTocar,
      colorBorde: sancionado ? AppColors.rojoAlerta.withValues(alpha: 0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarIniciales(texto: conductor.iniciales),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conductor.nombres,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.montserrat(
                        size: 15,
                        weight: FontWeight.w600,
                        color: c.textoOscuro,
                      ),
                    ),
                    Text(
                      'C.C. ${conductor.identificacion}',
                      style: AppTheme.inter(size: 12, color: c.textoSutil),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textoSutil),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChipEstado.activo(conductor.activo),
              if (sancionado)
                ChipEstado(
                  texto: 'Sancionado hasta ${Fechas.corta(sancion!.fechaFin)}',
                  tono: TonoEstado.peligro,
                  icono: Icons.gavel,
                ),
              ChipEstado(
                texto: conductor.licenciaVencida
                    ? 'Licencia vencida'
                    : 'Licencia ${conductor.categoriaLicencia ?? ''}'.trim(),
                tono: conductor.licenciaVencida
                    ? TonoEstado.alerta
                    : TonoEstado.info,
                icono: Icons.credit_card,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
