import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/despacho/despacho.dart';
import 'package:transcoorp/models/sancion/sancion.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/afiliaciones/listado_afiliaciones_screen.dart';
import 'package:transcoorp/screens/asociados/listado_asociados_screen.dart';
import 'package:transcoorp/screens/conductores/listado_conductores_screen.dart';
import 'package:transcoorp/screens/despachos/detalle_despacho_screen.dart';
import 'package:transcoorp/screens/despachos/listado_despachos_screen.dart';
import 'package:transcoorp/screens/mantenimientos/listado_mantenimientos_screen.dart';
import 'package:transcoorp/screens/planillas/generar_planillas_screen.dart';
import 'package:transcoorp/screens/planillas/listado_pagos_screen.dart';
import 'package:transcoorp/screens/rutas/consulta_rutas_screen.dart';
import 'package:transcoorp/screens/sanciones/listado_sanciones_screen.dart';
import 'package:transcoorp/screens/tarifas/listado_tarifas_screen.dart';
import 'package:transcoorp/services/local/cambios_datos.dart';
import 'package:transcoorp/services/local/gestor_sesion.dart';
import 'package:transcoorp/services/remote/asociado_service.dart';
import 'package:transcoorp/services/remote/conductor_service.dart';
import 'package:transcoorp/services/remote/despacho_service.dart';
import 'package:transcoorp/services/remote/sancion_service.dart';
import 'package:transcoorp/services/remote/vehiculo_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/theme/preferencia_tema.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';
import 'package:transcoorp/widgets/tarjeta_despacho.dart';
import 'package:transcoorp/widgets/tarjeta_bienvenida.dart';

class _Modulo {
  const _Modulo(this.icono, this.texto, this.color, this.pantalla);

  final IconData icono;
  final String texto;
  final Color color;
  final Widget Function() pantalla;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.alCambiarPestana});

  final ValueChanged<int> alCambiarPestana;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AsociadoService _asociados = AsociadoService();
  final ConductorService _conductores = ConductorService();
  final VehiculoService _vehiculos = VehiculoService();
  final DespachoService _despachos = DespachoService();
  final SancionService _sanciones = SancionService();

  int? _totalAsociados;
  int? _totalConductores;
  int? _totalVehiculos;
  int _sancionesVigentes = 0;
  List<Despacho> _recientes = const [];
  bool _cargando = true;
  String? _errorDespachos;

  static final List<_Modulo> _modulos = [
    _Modulo(Icons.groups_outlined, 'Asociados', Color(0xFF2563EB), () => const ListadoAsociadosScreen()),
    _Modulo(Icons.handshake_outlined, 'Afiliaciones', Color(0xFF0D9488), () => const ListadoAfiliacionesScreen()),
    _Modulo(Icons.badge_outlined, 'Conductores', Color(0xFF4F46E5), () => const ListadoConductoresScreen()),
    _Modulo(Icons.gavel_outlined, 'Sanciones', Color(0xFFDC2626), () => const ListadoSancionesScreen()),
    _Modulo(Icons.build_outlined, 'Mantenimiento', Color(0xFFD97706), () => const ListadoMantenimientosScreen()),
    _Modulo(Icons.payments_outlined, 'Tarifas', Color(0xFF059669), () => const ListadoTarifasScreen()),
    _Modulo(Icons.post_add_outlined, 'Generar planillas', Color(0xFF1E3A8A), () => const GenerarPlanillasScreen()),
    _Modulo(Icons.receipt_long_outlined, 'Pagos', Color(0xFF16A34A), () => const ListadoPagosScreen()),
    _Modulo(Icons.departure_board_outlined, 'Despachos', Color(0xFF7C3AED), () => const ListadoDespachosScreen()),
    _Modulo(Icons.alt_route_outlined, 'Rutas', Color(0xFF0891B2), () => const ConsultaRutasScreen()),
  ];

  @override
  void initState() {
    super.initState();
    CambiosDatos.conductores.addListener(_alCambiarConductores);
    _cargar();
  }

  @override
  void dispose() {
    CambiosDatos.conductores.removeListener(_alCambiarConductores);
    super.dispose();
  }

  void _alCambiarConductores() {
    if (mounted) _cargar();
  }

  Future<T?> _seguro<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } catch (_) {
      return null;
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorDespachos = null;
    });

    final resultados = await Future.wait<Object?>([
      _seguro(_asociados.total),
      _seguro(_conductores.total),
      _seguro(_vehiculos.total),
      _seguro(_sanciones.vigentesPorConductor),
      _seguro(() => _despachos.listar(tamano: 4)),
    ]);
    if (!mounted) return;

    final sanciones = resultados[3] as Map<String, Sancion>?;
    final despachos = resultados[4] as Pagina<Despacho>?;

    setState(() {
      _totalAsociados = resultados[0] as int?;
      _totalConductores = resultados[1] as int?;
      _totalVehiculos = resultados[2] as int?;
      _sancionesVigentes = sanciones?.length ?? 0;
      if (despachos == null) {
        _errorDespachos = 'No fue posible consultar los despachos recientes.';
        _recientes = const [];
      } else {
        _recientes = despachos.items;
      }
      _cargando = false;
    });
  }

  Future<void> _abrirYActualizar(Widget pantalla) async {
    final resultado = await abrir(context, pantalla);
    if (resultado != null && mounted) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: _encabezado(c),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ContenidoCentrado(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _bienvenida(),
              if (_sancionesVigentes > 0) ...[
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => abrir(context, const ListadoSancionesScreen()),
                  child: Aviso(
                    titulo: _sancionesVigentes == 1
                        ? '1 conductor con sanción vigente'
                        : '$_sancionesVigentes conductores con sanción vigente',
                    mensaje:
                        'No pueden ser asignados a vehículos ni planillas hasta finalizar el periodo.',
                    tono: TonoEstado.peligro,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _titulo(c, 'Módulos de gestión'),
              const SizedBox(height: 12),
              _gridModulos(c),
              const SizedBox(height: 24),
              _titulo(
                c,
                'Despachos recientes',
                accion: TextButton(
                  onPressed: () =>
                      abrir(context, const ListadoDespachosScreen()),
                  child: const Text('Ver todos'),
                ),
              ),
              const SizedBox(height: 4),
              ..._despachosRecientes(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _encabezado(ColoresApp c) {
    final sesion = GestorSesion.actual;
    return AppBar(
      backgroundColor: c.fondo,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primario,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.airport_shuttle_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRANSCOOP',
                  style: AppTheme.montserrat(
                    size: 18,
                    weight: FontWeight.w700,
                    color: c.primarioOscuro,
                  ).copyWith(letterSpacing: -0.3),
                ),
                Text(
                  sesion?.empresa ?? 'Panel administrativo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(size: 11.5, color: c.textoSutil),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: PreferenciaTema.modo,
          builder: (context, modo, _) => IconButton(
            tooltip: modo == ThemeMode.dark ? 'Modo claro' : 'Modo oscuro',
            onPressed: PreferenciaTema.alternar,
            icon: Icon(
              modo == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: c.primarioOscuro,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => widget.alCambiarPestana(3),
            child: AvatarIniciales(
              texto: Formato.iniciales(sesion?.username ?? 'Usuario'),
              tamano: 36,
            ),
          ),
        ),
      ],
    );
  }

  Widget _titulo(ColoresApp c, String texto, {Widget? accion}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          texto,
          style: AppTheme.montserrat(
            size: 17,
            weight: FontWeight.w600,
            color: c.primarioOscuro,
          ),
        ),
        ?accion,
      ],
    );
  }

  String _valor(int? total) => _cargando ? '…' : (total?.toString() ?? '—');

  Widget _bienvenida() {
    final ahora = DateTime.now();
    final sesion = GestorSesion.actual;
    return TarjetaBienvenida(
      fecha: Fechas.fechaLarga(ahora),
      saludo: '${Fechas.saludo(ahora)}, ${sesion?.username ?? ''}',
      rol: sesion?.rolLegible ?? 'Usuario',
      metricas: [
        MetricaBienvenida(
          icono: Icons.groups_outlined,
          valor: _valor(_totalAsociados),
          titulo: 'Asociados',
          alTocar: () => _abrirYActualizar(const ListadoAsociadosScreen()),
        ),
        MetricaBienvenida(
          icono: Icons.badge_outlined,
          valor: _valor(_totalConductores),
          titulo: 'Conductores',
          alTocar: () => _abrirYActualizar(const ListadoConductoresScreen()),
        ),
        MetricaBienvenida(
          icono: Icons.directions_bus_outlined,
          valor: _valor(_totalVehiculos),
          titulo: 'Vehículos',
          alTocar: () => widget.alCambiarPestana(1),
        ),
      ],
    );
  }

  Widget _gridModulos(ColoresApp c) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        const columnas = 4;
        const espacio = 10.0;
        final ancho =
            (restricciones.maxWidth - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: 14,
          children: [
            for (final modulo in _modulos)
              SizedBox(
                width: ancho,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _abrirYActualizar(modulo.pantalla()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: modulo.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: modulo.color.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Icon(
                            modulo.icono,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Color.lerp(modulo.color, Colors.white, 0.35)
                                : modulo.color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          modulo.texto,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: AppTheme.inter(
                            size: 11.5,
                            weight: FontWeight.w500,
                            color: c.textoOscuro,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _despachosRecientes() {
    if (_cargando) {
      return const [
        SizedBox(height: 140, child: EstadoCarga(mensaje: 'Consultando despachos...')),
      ];
    }
    if (_errorDespachos != null) {
      return [EstadoError(mensaje: _errorDespachos!, alReintentar: _cargar)];
    }
    if (_recientes.isEmpty) {
      return [
        EstadoVacio(
          icono: Icons.departure_board_outlined,
          titulo: 'Sin despachos registrados',
          mensaje: 'Los despachos que registres aparecerán aquí.',
          textoAccion: 'Ir a despachos',
          iconoAccion: Icons.arrow_forward,
          alAccion: () => abrir(context, const ListadoDespachosScreen()),
        ),
      ];
    }
    return [
      for (final despacho in _recientes)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TarjetaDespacho(
            despacho: despacho,
            alTocar: () =>
                abrir(context, DetalleDespachoScreen(despacho: despacho)),
          ),
        ),
    ];
  }
}
