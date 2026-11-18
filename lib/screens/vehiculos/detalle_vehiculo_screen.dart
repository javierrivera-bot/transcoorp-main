import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/conductor/conductor.dart';
import 'package:transcoorp/models/mantenimiento/mantenimiento.dart';
import 'package:transcoorp/models/sancion/sancion.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/mantenimientos/formulario_mantenimiento_screen.dart';
import 'package:transcoorp/screens/mantenimientos/listado_mantenimientos_screen.dart';
import 'package:transcoorp/screens/vehiculos/formulario_vehiculo_screen.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/conductor_service.dart';
import 'package:transcoorp/services/remote/mantenimiento_service.dart';
import 'package:transcoorp/services/remote/sancion_service.dart';
import 'package:transcoorp/services/remote/vehiculo_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/boton_principal.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';

class DetalleVehiculoScreen extends StatefulWidget {
  const DetalleVehiculoScreen({super.key, required this.vehiculo});

  final Vehiculo vehiculo;

  @override
  State<DetalleVehiculoScreen> createState() => _DetalleVehiculoScreenState();
}

class _DetalleVehiculoScreenState extends State<DetalleVehiculoScreen> {
  final VehiculoService _servicio = VehiculoService();

  late Vehiculo _vehiculo = widget.vehiculo;
  Conductor? _conductor;
  Sancion? _sancionConductor;
  Mantenimiento? _mantenimiento;

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  Future<void> _refrescar() async {
    try {
      final actual = await _servicio.obtenerPorPlaca(_vehiculo.placa);
      if (mounted) setState(() => _vehiculo = actual);
    } on ApiException catch (_) {}

    final identificacion = _vehiculo.identificacionConductor;
    if (identificacion != null) {
      try {
        final conductor = await ConductorService().obtenerPorId(identificacion);
        final vigentes = await SancionService().vigentesPorConductor();
        if (mounted) {
          setState(() {
            _conductor = conductor;
            _sancionConductor = vigentes[identificacion];
          });
        }
      } catch (_) {}
    } else if (mounted) {
      setState(() {
        _conductor = null;
        _sancionConductor = null;
      });
    }

    try {
      final abierto = await MantenimientoService().abiertoDe(_vehiculo.placa);
      if (mounted) setState(() => _mantenimiento = abierto);
    } catch (_) {}
  }

  Future<void> _editar() async {
    final actualizado = await abrir<Vehiculo>(
      context,
      FormularioVehiculoScreen(vehiculo: _vehiculo),
    );
    if (actualizado == null || !mounted) return;
    setState(() => _vehiculo = actualizado);
    mostrarExito(context, 'Vehículo actualizado.');
    _refrescar();
  }

  Future<void> _mantenimientoAccion() async {
    if (_mantenimiento != null) {
      await abrir(
        context,
        ListadoMantenimientosScreen(placa: _vehiculo.placa),
      );
    } else {
      final registrado = await abrir<Mantenimiento>(
        context,
        FormularioMantenimientoScreen(placa: _vehiculo.placa),
      );
      if (registrado != null && mounted) {
        mostrarExito(context, 'Ingreso a mantenimiento registrado.');
      }
    }
    if (mounted) _refrescar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final v = _vehiculo;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Detalle del vehículo',
        subtitulo: v.placa,
        acciones: [
          IconButton(
            tooltip: 'Historial de mantenimiento',
            icon: Icon(Icons.history, color: c.primarioOscuro),
            onPressed: () => abrir(
              context,
              ListadoMantenimientosScreen(placa: v.placa),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: ContenidoCentrado(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _cabecera(c, v),
              if (_mantenimiento != null) ...[
                const SizedBox(height: 12),
                Aviso(
                  titulo: 'En mantenimiento',
                  mensaje:
                      '${_mantenimiento!.motivo} · Ingresó el ${Fechas.fechaHora(_mantenimiento!.fechaIngreso)}',
                  tono: TonoEstado.alerta,
                  icono: Icons.build_circle_outlined,
                ),
              ],
              if (!v.documentosAlDia) ...[
                const SizedBox(height: 12),
                Aviso(
                  titulo: 'Documentación vencida',
                  mensaje: [
                    if (v.soatVencido) 'SOAT vencido desde ${Fechas.corta(v.vigenciaSoat)}',
                    if (v.trmVencida) 'TRM vencida desde ${Fechas.corta(v.vigenciaTrm)}',
                  ].join('\n'),
                  tono: TonoEstado.peligro,
                ),
              ],
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Información general',
                icono: Icons.info_outline,
                children: [
                  GrillaDatos(
                    datos: [
                      FilaDato(etiqueta: 'Tipo', valor: Formato.valorO(v.tipo)),
                      FilaDato(etiqueta: 'Marca', valor: Formato.valorO(v.marca)),
                      FilaDato(etiqueta: 'Modelo', valor: Formato.valorO(v.modelo)),
                      FilaDato(
                        etiqueta: 'Capacidad',
                        valor: '${v.capacidadPasajeros} pasajeros',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Conductor asignado',
                icono: Icons.badge_outlined,
                children: [
                  if (v.identificacionConductor == null)
                    const FilaDato(
                      icono: Icons.person_off_outlined,
                      etiqueta: 'Asignación',
                      valor: 'Sin conductor asignado',
                    )
                  else
                    FilaDato(
                      icono: Icons.person_outline,
                      etiqueta: 'C.C. ${v.identificacionConductor}',
                      valor: _conductor?.nombres ?? 'Consultando...',
                      complemento: _sancionConductor != null
                          ? const ChipEstado(
                              texto: 'Sancionado',
                              tono: TonoEstado.peligro,
                            )
                          : null,
                    ),
                  if (_sancionConductor != null)
                    Aviso(
                      titulo: 'Conductor no disponible',
                      mensaje:
                          'Tiene sanción vigente hasta el ${Fechas.corta(_sancionConductor!.fechaFin)}. Asigna otro conductor para operar el vehículo.',
                      tono: TonoEstado.peligro,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Documentación y vigencias',
                icono: Icons.folder_open_outlined,
                children: [
                  FilaDato(
                    icono: Icons.description_outlined,
                    etiqueta: 'Tarjeta de propiedad',
                    valor: Formato.valorO(v.tarjetaPropiedad),
                  ),
                  _vigencia(c, 'SOAT', v.vigenciaSoat),
                  _vigencia(c, 'Revisión técnico-mecánica (TRM)', v.vigenciaTrm),
                ],
              ),
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Tarifa y estado',
                icono: Icons.payments_outlined,
                children: [
                  GrillaDatos(
                    datos: [
                      FilaDato(
                        etiqueta: 'Tarifa',
                        valor: v.tarifaTotal == null
                            ? (v.tarifaId == null ? 'Sin tarifa' : 'N.° ${v.tarifaId}')
                            : Formato.moneda(v.tarifaTotal!),
                        destacado: true,
                      ),
                      FilaDato(
                        etiqueta: 'Estado',
                        valor: v.activo ? 'Operativo' : 'Inactivo',
                        destacado: true,
                      ),
                    ],
                  ),
                  FilaDato(
                    icono: Icons.login,
                    etiqueta: 'Fecha de ingreso a la cooperativa',
                    valor: Fechas.corta(v.fechaIngreso),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PieTrazabilidad(
                registro: Fechas.corta(v.fechaRegistro),
                actualizacion: Fechas.corta(
                  v.ultimaActualizacion ?? v.fechaRegistro,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PieAcciones(
        children: [
          BotonSecundario(
            texto: _mantenimiento == null ? 'Mantenimiento' : 'Ver taller',
            icono: Icons.build_outlined,
            alPresionar: _mantenimientoAccion,
          ),
          BotonPrincipal(texto: 'Editar', alPresionar: _editar),
        ],
      ),
    );
  }

  Widget _cabecera(ColoresApp c, Vehiculo v) {
    return TarjetaBase(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          IconoCaja(icono: Icons.airport_shuttle_rounded, tamano: 64),
          const SizedBox(height: 12),
          PlacaVehiculo(placa: v.placa, grande: true),
          const SizedBox(height: 8),
          Text(
            '${v.tipo ?? 'Vehículo'} · ${v.descripcion}',
            textAlign: TextAlign.center,
            style: AppTheme.montserrat(
              size: 15,
              weight: FontWeight.w600,
              color: c.textoOscuro,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            alignment: WrapAlignment.center,
            children: [
              ChipEstado.activo(
                v.activo,
                textoActivo: 'Operativo',
                textoInactivo: 'Inactivo',
              ),
              if (_mantenimiento != null)
                const ChipEstado(
                  texto: 'En mantenimiento',
                  tono: TonoEstado.alerta,
                  icono: Icons.build,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vigencia(ColoresApp c, String nombre, DateTime? fecha) {
    final vencida = Fechas.vencida(fecha);
    final dias = fecha == null ? null : Fechas.diasHasta(fecha);
    final porVencer = dias != null && dias >= 0 && dias <= 30;

    return FilaDato(
      icono: Icons.event_available_outlined,
      etiqueta: nombre,
      valor: Fechas.corta(fecha),
      complemento: fecha == null
          ? null
          : ChipEstado(
              texto: vencida
                  ? 'Vencida'
                  : porVencer
                  ? 'Vence en $dias días'
                  : 'Vigente',
              tono: vencida
                  ? TonoEstado.peligro
                  : porVencer
                  ? TonoEstado.alerta
                  : TonoEstado.exito,
            ),
    );
  }
}
