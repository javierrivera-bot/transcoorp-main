import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/mi_cuenta_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';

class MisVehiculosScreen extends StatefulWidget {
  const MisVehiculosScreen({super.key, this.alVolver});

  final VoidCallback? alVolver;

  @override
  State<MisVehiculosScreen> createState() => _MisVehiculosScreenState();
}

class _MisVehiculosScreenState extends State<MisVehiculosScreen> {
  final MiCuentaService _servicio = MiCuentaService();

  List<VehiculoAsociado>? _vehiculos;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final vehiculos = await _servicio.misVehiculos();
      if (mounted) setState(() => _vehiculos = vehiculos);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final vehiculos = _vehiculos;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Mis vehículos',
        subtitulo: vehiculos == null
            ? 'Vehículos afiliados a tu nombre'
            : '${vehiculos.length} ${vehiculos.length == 1 ? 'vehículo afiliado' : 'vehículos afiliados'}',
        alVolver: widget.alVolver,
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ContenidoCentrado(
          child: _error != null && vehiculos == null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 60),
                    EstadoError(mensaje: _error!, alReintentar: _cargar),
                  ],
                )
              : vehiculos == null
              ? const EstadoCarga(mensaje: 'Consultando tus vehículos...')
              : vehiculos.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 60),
                    EstadoVacio(
                      icono: Icons.directions_car_outlined,
                      titulo: 'Sin vehículos afiliados',
                      mensaje:
                          'Cuando la cooperativa afilie un vehículo a tu nombre aparecerá aquí.',
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: vehiculos.length,
                  separatorBuilder: (context, indice) => const SizedBox(height: 12),
                  itemBuilder: (context, indice) =>
                      _TarjetaMiVehiculo(vehiculo: vehiculos[indice]),
                ),
        ),
      ),
    );
  }
}

class _TarjetaMiVehiculo extends StatelessWidget {
  const _TarjetaMiVehiculo({required this.vehiculo});

  final VehiculoAsociado vehiculo;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return TarjetaBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const IconoCaja(icono: Icons.airport_shuttle_outlined, tamano: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlacaVehiculo(placa: vehiculo.placa),
                    const SizedBox(height: 6),
                    Text(
                      '${vehiculo.tipo ?? 'Vehículo'} · ${vehiculo.descripcion}',
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
          GrillaDatos(
            datos: [
              FilaDato(etiqueta: 'Marca', valor: vehiculo.marca ?? '—'),
              FilaDato(etiqueta: 'Modelo', valor: vehiculo.modelo ?? '—'),
              FilaDato(
                etiqueta: 'Conductor',
                valor: vehiculo.identificacionConductor == null
                    ? 'Sin asignar'
                    : 'C.C. ${vehiculo.identificacionConductor}',
              ),
              FilaDato(
                etiqueta: 'Afiliado desde',
                valor: Fechas.corta(vehiculo.fechaAfiliacion),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
