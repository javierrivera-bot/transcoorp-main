import 'package:flutter/material.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/mantenimiento_service.dart';
import 'package:transcoorp/services/remote/vehiculo_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/campos_formulario.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/mensaje_error.dart';

class FormularioMantenimientoScreen extends StatefulWidget {
  const FormularioMantenimientoScreen({super.key, this.placa});

  final String? placa;

  @override
  State<FormularioMantenimientoScreen> createState() =>
      _FormularioMantenimientoScreenState();
}

class _FormularioMantenimientoScreenState
    extends State<FormularioMantenimientoScreen> {
  static const _motivos = [
    'Mantenimiento preventivo',
    'Cambio de aceite y filtros',
    'Revisión de frenos',
    'Falla mecánica',
    'Sistema eléctrico',
    'Latonería y pintura',
  ];

  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final TextEditingController _motivo = TextEditingController();
  final TextEditingController _observaciones = TextEditingController();

  late String? _placa = widget.placa;
  DateTime? _fechaIngreso = DateTime.now();
  TimeOfDay? _horaIngreso = TimeOfDay.now();
  String? _estadoVehiculo;

  List<Vehiculo> _vehiculos = const [];
  bool _cargando = true;
  bool _guardando = false;
  String? _errorCarga;
  String? _errorServidor;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _motivo.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final vehiculos = await VehiculoService().todos(soloActivos: false);
      if (mounted) {
        setState(() {
          _vehiculos = vehiculos;
          _cargando = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorCarga = e.message;
          _cargando = false;
        });
      }
    }
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;

    final hora = _horaIngreso ?? TimeOfDay.now();
    final fecha = DateTime(
      _fechaIngreso!.year,
      _fechaIngreso!.month,
      _fechaIngreso!.day,
      hora.hour,
      hora.minute,
    );

    setState(() => _guardando = true);
    try {
      final registrado = await MantenimientoService().registrarIngreso(
        placaVehiculo: _placa!,
        fechaIngreso: fecha,
        motivo: _motivo.text.trim(),
        estadoVehiculo: _estadoVehiculo!,
        observaciones: _observaciones.text.trim(),
      );
      if (mounted) Navigator.pop(context, registrado);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorServidor = e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: const EncabezadoModulo(
        titulo: 'Ingreso a mantenimiento',
        subtitulo: 'Registro de entrada a taller',
      ),
      body: _cargando
          ? const EstadoCarga(mensaje: 'Cargando vehículos...')
          : _errorCarga != null
          ? EstadoError(mensaje: _errorCarga!, alReintentar: _cargar)
          : Form(
              key: _formulario,
              child: ContenidoCentrado(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (_errorServidor != null) ...[
                      MensajeError(_errorServidor!),
                      const SizedBox(height: 16),
                    ],
                    CampoSelector<String>(
                      etiqueta: 'Vehículo',
                      valor: _placa,
                      icono: Icons.directions_car_outlined,
                      hint: 'Seleccionar vehículo',
                      obligatorio: true,
                      habilitado: widget.placa == null,
                      validador: (v) => Validar.seleccion(v, 'el vehículo'),
                      opciones: [
                        for (final vehiculo in _vehiculos)
                          OpcionSelector(
                            valor: vehiculo.placa,
                            texto: vehiculo.placa,
                            detalle:
                                '${vehiculo.tipo ?? 'Vehículo'} · ${vehiculo.descripcion}',
                          ),
                      ],
                      alCambiar: (valor) => setState(() => _placa = valor),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CampoFecha(
                            etiqueta: 'Fecha de ingreso',
                            valor: _fechaIngreso,
                            ultima: Fechas.hoy,
                            obligatorio: true,
                            validador: (v) => Validar.fecha(v),
                            alCambiar: (fecha) => _fechaIngreso = fecha,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoHora(
                            etiqueta: 'Hora',
                            valor: _horaIngreso,
                            alCambiar: (hora) => _horaIngreso = hora,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CampoSelector<String>(
                      etiqueta: 'Estado del vehículo',
                      valor: _estadoVehiculo,
                      icono: Icons.health_and_safety_outlined,
                      obligatorio: true,
                      validador: (v) => Validar.seleccion(v, 'el estado'),
                      opciones: [
                        for (final estado in MantenimientoService.estadosIngreso)
                          OpcionSelector(valor: estado, texto: estado),
                      ],
                      alCambiar: (valor) =>
                          setState(() => _estadoVehiculo = valor),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final motivo in _motivos)
                          ActionChip(
                            label: Text(motivo),
                            onPressed: () => setState(() => _motivo.text = motivo),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CampoTexto(
                      etiqueta: 'Motivo del mantenimiento',
                      controlador: _motivo,
                      icono: Icons.build_outlined,
                      hint: 'Describe el trabajo a realizar',
                      obligatorio: true,
                      mayusculas: TextCapitalization.sentences,
                      validador: (v) => Validar.requerido(v, 'el motivo'),
                    ),
                    const SizedBox(height: 16),
                    CampoTexto(
                      etiqueta: 'Observaciones',
                      controlador: _observaciones,
                      icono: Icons.notes,
                      hint: 'Kilometraje, novedades o taller asignado',
                      lineas: 3,
                      mayusculas: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _cargando || _errorCarga != null
          ? null
          : BarraAcciones(
              textoPrincipal: 'Registrar ingreso',
              alPrincipal: _guardar,
              cargando: _guardando,
            ),
    );
  }
}
