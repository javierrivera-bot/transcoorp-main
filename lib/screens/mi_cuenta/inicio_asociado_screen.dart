import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/despacho/despacho.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/despachos/detalle_despacho_screen.dart';
import 'package:transcoorp/screens/rutas/consulta_rutas_screen.dart';
import 'package:transcoorp/services/local/gestor_sesion.dart';
import 'package:transcoorp/services/remote/despacho_service.dart';
import 'package:transcoorp/services/remote/mi_cuenta_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/theme/preferencia_tema.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';
import 'package:transcoorp/widgets/tarjeta_despacho.dart';
import 'package:transcoorp/widgets/tarjeta_bienvenida.dart';

class InicioAsociadoScreen extends StatefulWidget {
  const InicioAsociadoScreen({super.key, required this.alCambiarPestana});

  final ValueChanged<int> alCambiarPestana;

  @override
  State<InicioAsociadoScreen> createState() => _InicioAsociadoScreenState();
}

class _InicioAsociadoScreenState extends State<InicioAsociadoScreen> {
  List<VehiculoAsociado>? _vehiculos;
  Pagina<Despacho>? _viajesMes;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final hoy = Fechas.hoy;
    try {
      final vehiculos = await MiCuentaService().misVehiculos();
      final viajes = await DespachoService().misDespachos(
        desde: DateTime(hoy.year, hoy.month, 1),
        hasta: hoy,
        tamano: 5,
      );
      if (!mounted) return;
      setState(() {
        _vehiculos = vehiculos;
        _viajesMes = viajes;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final sesion = GestorSesion.actual;
    final ahora = DateTime.now();
    final vehiculos = _vehiculos;
    final viajes = _viajesMes;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: AppBar(
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
                    ),
                  ),
                  Text(
                    'Portal del asociado',
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
                texto: Formato.iniciales(sesion?.username ?? 'Asociado'),
                tamano: 36,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ContenidoCentrado(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              TarjetaBienvenida(
                fecha: Fechas.fechaLarga(ahora),
                saludo: '${Fechas.saludo(ahora)}, ${sesion?.username ?? ''}',
                rol: 'Asociado',
                metricas: [
                  MetricaBienvenida(
                    icono: Icons.directions_car_outlined,
                    valor: _cargando ? '…' : '${vehiculos?.length ?? '—'}',
                    titulo: 'Vehículos afiliados',
                    alTocar: () => widget.alCambiarPestana(1),
                  ),
                  MetricaBienvenida(
                    icono: Icons.route_outlined,
                    valor: _cargando ? '…' : '${viajes?.totalItems ?? '—'}',
                    titulo: 'Viajes este mes',
                    alTocar: () => widget.alCambiarPestana(2),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TarjetaBase(
                alTocar: () => abrir(context, const ConsultaRutasScreen()),
                child: Row(
                  children: [
                    const IconoCaja(icono: Icons.alt_route),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consultar rutas',
                            style: AppTheme.montserrat(
                              size: 14,
                              weight: FontWeight.w600,
                              color: c.textoOscuro,
                            ),
                          ),
                          Text(
                            'Recorridos y tarifas de la cooperativa',
                            style: AppTheme.inter(size: 12, color: c.textoSutil),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: c.textoSutil),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Viajes recientes',
                    style: AppTheme.montserrat(
                      size: 17,
                      weight: FontWeight.w600,
                      color: c.primarioOscuro,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.alCambiarPestana(2),
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
              if (_cargando)
                const SizedBox(height: 140, child: EstadoCarga())
              else if (_error != null)
                EstadoError(
                  mensaje: 'No fue posible consultar tu información.',
                  alReintentar: _cargar,
                )
              else if (viajes == null || viajes.items.isEmpty)
                const EstadoVacio(
                  icono: Icons.route_outlined,
                  titulo: 'Sin viajes este mes',
                  mensaje: 'Los despachos de tus vehículos aparecerán aquí.',
                )
              else
                for (final despacho in viajes.items)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TarjetaDespacho(
                      despacho: despacho,
                      alTocar: () => abrir(
                        context,
                        DetalleDespachoScreen(despacho: despacho),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
