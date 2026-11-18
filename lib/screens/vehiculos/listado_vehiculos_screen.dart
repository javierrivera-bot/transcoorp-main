import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/conductor/conductor.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/services/local/cambios_datos.dart';
import 'package:transcoorp/screens/vehiculos/detalle_vehiculo_screen.dart';
import 'package:transcoorp/screens/vehiculos/formulario_vehiculo_screen.dart';
import 'package:transcoorp/services/remote/conductor_service.dart';
import 'package:transcoorp/services/remote/vehiculo_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/filtros.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';
import 'package:transcoorp/widgets/vista_paginada.dart';

class ListadoVehiculosScreen extends StatefulWidget {
  const ListadoVehiculosScreen({super.key, this.alVolver});

  final VoidCallback? alVolver;

  @override
  State<ListadoVehiculosScreen> createState() => _ListadoVehiculosScreenState();
}

class _ListadoVehiculosScreenState extends State<ListadoVehiculosScreen> {
  final VehiculoService _servicio = VehiculoService();
  late final ControladorPaginado<Vehiculo> _controlador =
      ControladorPaginado(_cargar);

  Map<String, Conductor> _conductores = const {};
  String _placa = '';
  String _tipo = '';

  @override
  void initState() {
    super.initState();
    CambiosDatos.conductores.addListener(_alCambiarConductores);
    _controlador.recargar();
  }

  @override
  void dispose() {
    CambiosDatos.conductores.removeListener(_alCambiarConductores);
    _controlador.dispose();
    super.dispose();
  }

  void _alCambiarConductores() => _cargarConductores();

  Future<void> _cargarConductores() async {
    try {
      final lista = await ConductorService().todos(soloActivos: false);
      if (!mounted) return;
      setState(() {
        _conductores = {for (final c in lista) c.identificacion: c};
      });
    } catch (_) {}
  }

  Future<Pagina<Vehiculo>> _cargar(int pagina) async {
    if (pagina == 1 && _conductores.isEmpty) {
      await _cargarConductores();
    }
    return _servicio.listar(pagina: pagina, placa: _placa, tipo: _tipo);
  }

  Future<void> _registrar() async {
    final creado = await abrir<Vehiculo>(
      context,
      const FormularioVehiculoScreen(),
    );
    if (creado == null || !mounted) return;
    mostrarExito(context, 'Vehículo ${creado.placa} registrado.');
    _controlador.recargar();
  }

  Future<void> _verDetalle(Vehiculo vehiculo) async {
    await abrir(context, DetalleVehiculoScreen(vehiculo: vehiculo));
    if (mounted) _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Vehículos',
        subtitulo: 'Parque automotor afiliado',
        alVolver: widget.alVolver,
        acciones: [
          AccionEncabezado(
            icono: Icons.add,
            tooltip: 'Registrar vehículo',
            alPresionar: _registrar,
          ),
        ],
      ),
      body: PantallaLista(
        filtros: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoBusqueda(
              hint: 'Buscar por placa',
              mayusculas: true,
              alBuscar: (texto) {
                _placa = texto.toUpperCase();
                _controlador.recargar();
              },
            ),
            const SizedBox(height: 12),
            BarraFiltros<String>(
              seleccionado: _tipo,
              alCambiar: (valor) {
                setState(() => _tipo = valor);
                _controlador.recargar();
              },
              opciones: [
                const OpcionFiltro('', 'Todos'),
                for (final tipo in VehiculoService.tipos) OpcionFiltro(tipo, tipo),
              ],
            ),
          ],
        ),
        lista: VistaPaginada<Vehiculo>(
          controlador: _controlador,
          cabecera: ListenableBuilder(
            listenable: _controlador,
            builder: (context, _) => ContadorResultados(
              mostrados: _controlador.items.length,
              total: _controlador.totalItems,
              sustantivo: 'vehículos',
            ),
          ),
          constructor: (context, vehiculo) => TarjetaVehiculo(
            vehiculo: vehiculo,
            conductor: _conductores[vehiculo.identificacionConductor],
            alTocar: () => _verDetalle(vehiculo),
          ),
          vacio: EstadoVacio(
            icono: Icons.directions_bus_outlined,
            titulo: _placa.isEmpty && _tipo.isEmpty
                ? 'Sin vehículos registrados'
                : 'Sin coincidencias',
            mensaje: _placa.isEmpty && _tipo.isEmpty
                ? 'Registra el primer vehículo del parque automotor.'
                : 'No hay vehículos con esa placa o tipo.',
            textoAccion: 'Registrar vehículo',
            alAccion: _registrar,
          ),
        ),
      ),
    );
  }
}

class TarjetaVehiculo extends StatelessWidget {
  const TarjetaVehiculo({
    super.key,
    required this.vehiculo,
    required this.alTocar,
    this.conductor,
  });

  final Vehiculo vehiculo;
  final Conductor? conductor;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final conductorTexto = vehiculo.identificacionConductor == null
        ? 'Sin asignar'
        : conductor?.nombres ?? 'C.C. ${vehiculo.identificacionConductor}';

    return TarjetaBase(
      alTocar: alTocar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconoCaja(
                icono: Icons.airport_shuttle_outlined,
                tamano: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlacaVehiculo(placa: vehiculo.placa),
                    const SizedBox(height: 6),
                    Text(
                      '${vehiculo.tipo ?? 'Vehículo'} · ${vehiculo.descripcion}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.montserrat(
                        size: 14,
                        weight: FontWeight.w600,
                        color: c.textoOscuro,
                      ),
                    ),
                  ],
                ),
              ),
              ChipEstado.activo(
                vehiculo.activo,
                textoActivo: 'Operativo',
                textoInactivo: 'Inactivo',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.fondo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _linea(
                  c,
                  Icons.groups_outlined,
                  'Capacidad: ${vehiculo.capacidadPasajeros} pasajeros',
                ),
                const SizedBox(height: 6),
                _linea(c, Icons.badge_outlined, 'Conductor: $conductorTexto'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                vehiculo.documentosAlDia
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                size: 16,
                color: vehiculo.documentosAlDia
                    ? c.verdeOscuro
                    : AppColors.rojoAlerta,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  vehiculo.documentosAlDia
                      ? 'SOAT y TRM vigentes'
                      : [
                          if (vehiculo.soatVencido) 'SOAT vencido',
                          if (vehiculo.trmVencida) 'TRM vencida',
                        ].join(' · '),
                  style: AppTheme.inter(
                    size: 12,
                    weight: FontWeight.w500,
                    color: vehiculo.documentosAlDia
                        ? c.textoSutil
                        : AppColors.rojoAlerta,
                  ),
                ),
              ),
              Text(
                'Ver detalle',
                style: AppTheme.inter(
                  size: 13,
                  weight: FontWeight.w600,
                  color: c.primario,
                ),
              ),
              Icon(Icons.arrow_forward, size: 16, color: c.primario),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linea(ColoresApp c, IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, size: 16, color: c.primario),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.inter(size: 12.5, color: c.textoGris),
          ),
        ),
      ],
    );
  }
}
