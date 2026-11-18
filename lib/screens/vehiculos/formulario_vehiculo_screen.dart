import 'package:flutter/material.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/conductor/conductor.dart';
import 'package:transcoorp/models/sancion/sancion.dart';
import 'package:transcoorp/models/tarifa/tarifa.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/conductor_service.dart';
import 'package:transcoorp/services/remote/sancion_service.dart';
import 'package:transcoorp/services/remote/tarifa_service.dart';
import 'package:transcoorp/services/remote/vehiculo_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/campos_formulario.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/mensaje_error.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';

class FormularioVehiculoScreen extends StatefulWidget {
  const FormularioVehiculoScreen({super.key, this.vehiculo});

  final Vehiculo? vehiculo;

  @override
  State<FormularioVehiculoScreen> createState() =>
      _FormularioVehiculoScreenState();
}

class _FormularioVehiculoScreenState extends State<FormularioVehiculoScreen> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final VehiculoService _servicio = VehiculoService();

  final TextEditingController _placa = TextEditingController();
  final TextEditingController _marca = TextEditingController();
  final TextEditingController _modelo = TextEditingController();
  final TextEditingController _capacidad = TextEditingController();
  final TextEditingController _tarjeta = TextEditingController();

  String? _tipo;
  String? _conductor;
  int? _tarifa;
  bool _activo = true;
  DateTime? _soat;
  DateTime? _trm;
  DateTime? _ingreso = Fechas.hoy;

  List<Conductor> _conductores = const [];
  List<Tarifa> _tarifas = const [];
  Map<String, Sancion> _vigentes = const {};
  bool _cargando = true;
  bool _guardando = false;
  String? _errorCarga;
  String? _errorServidor;

  bool get _esEdicion => widget.vehiculo != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehiculo;
    if (v != null) {
      _placa.text = v.placa;
      _marca.text = v.marca ?? '';
      _modelo.text = v.modelo ?? '';
      _capacidad.text = '${v.capacidadPasajeros}';
      _tarjeta.text = v.tarjetaPropiedad ?? '';
      _tipo = v.tipo;
      _conductor = v.identificacionConductor;
      _tarifa = v.tarifaId;
      _activo = v.activo;
      _soat = v.vigenciaSoat;
      _trm = v.vigenciaTrm;
      _ingreso = v.fechaIngreso;
    }
    _cargarOpciones();
  }

  @override
  void dispose() {
    _placa.dispose();
    _marca.dispose();
    _modelo.dispose();
    _capacidad.dispose();
    _tarjeta.dispose();
    super.dispose();
  }

  Future<void> _cargarOpciones() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final conductores = await ConductorService().todos();
      final tarifas = await TarifaService().activas();
      final vigentes = await SancionService().vigentesPorConductor();
      if (!mounted) return;
      setState(() {
        _conductores = conductores;
        _tarifas = tarifas;
        _vigentes = vigentes;
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorCarga = e.message;
          _cargando = false;
        });
      }
    }
  }

  String? _motivoBloqueo(Conductor conductor) {
    final sancion = _vigentes[conductor.identificacion];
    if (sancion != null) {
      return 'Sancionado hasta ${Fechas.corta(sancion.fechaFin)}';
    }
    if (conductor.licenciaVencida) return 'Licencia vencida';
    return null;
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;

    final sancion = _conductor == null ? null : _vigentes[_conductor];
    if (sancion != null) {
      setState(
        () => _errorServidor =
            'No se puede asignar a ${sancion.nombresConductor.isEmpty ? 'este conductor' : sancion.nombresConductor}: tiene una sanción vigente hasta el ${Fechas.corta(sancion.fechaFin)}.',
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final Vehiculo resultado;
      if (_esEdicion) {
        resultado = await _servicio.editar(
          widget.vehiculo!.placa,
          identificacionConductor: _conductor,
          tarifaId: _tarifa,
          activo: _activo,
          vigenciaSoat: _soat!,
          vigenciaTrm: _trm!,
        );
      } else {
        resultado = await _servicio.registrar(
          DatosVehiculo(
            placa: _placa.text.trim().toUpperCase(),
            identificacionConductor: _conductor,
            tipo: _tipo!,
            marca: _marca.text.trim(),
            modelo: _modelo.text.trim(),
            capacidadPasajeros: int.parse(_capacidad.text.trim()),
            tarjetaPropiedad: _tarjeta.text.trim(),
            tarifaId: _tarifa!,
            activo: _activo,
            vigenciaSoat: _soat!,
            vigenciaTrm: _trm!,
            fechaIngreso: _ingreso!,
          ),
        );
      }
      if (mounted) Navigator.pop(context, resultado);
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
      appBar: EncabezadoModulo(
        titulo: _esEdicion ? 'Editar vehículo' : 'Registrar vehículo',
        subtitulo: _esEdicion
            ? widget.vehiculo!.placa
            : 'Ingreso al parque automotor',
      ),
      body: _cargando
          ? const EstadoCarga(mensaje: 'Cargando conductores y tarifas...')
          : _errorCarga != null
          ? EstadoError(mensaje: _errorCarga!, alReintentar: _cargarOpciones)
          : _contenido(),
      bottomNavigationBar: _cargando || _errorCarga != null
          ? null
          : BarraAcciones(
              textoPrincipal: _esEdicion ? 'Guardar cambios' : 'Registrar',
              alPrincipal: _guardar,
              cargando: _guardando,
            ),
    );
  }

  Widget _contenido() {
    final anioActual = DateTime.now().year;
    return Form(
      key: _formulario,
      child: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_errorServidor != null) ...[
              MensajeError(_errorServidor!),
              const SizedBox(height: 16),
            ],
            if (!_esEdicion) ...[
              const TituloSeccionFormulario(
                titulo: 'Información general',
                icono: Icons.info_outline,
              ),
              const SizedBox(height: 12),
              CampoTexto(
                etiqueta: 'Placa',
                controlador: _placa,
                icono: Icons.pin_outlined,
                hint: 'ABC-123',
                formateadores: [Formateadores.mayusculas],
                longitudMaxima: 8,
                obligatorio: true,
                validador: Validar.placa,
              ),
              const SizedBox(height: 16),
              CampoSelector<String>(
                etiqueta: 'Tipo de vehículo',
                valor: _tipo,
                icono: Icons.category_outlined,
                obligatorio: true,
                validador: (v) => Validar.seleccion(v, 'el tipo'),
                opciones: [
                  for (final tipo in VehiculoService.tipos)
                    OpcionSelector(valor: tipo, texto: tipo),
                ],
                alCambiar: (valor) => setState(() => _tipo = valor),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CampoTexto(
                      etiqueta: 'Marca',
                      controlador: _marca,
                      icono: Icons.directions_car_outlined,
                      hint: 'Toyota',
                      mayusculas: TextCapitalization.words,
                      obligatorio: true,
                      validador: (v) => Validar.requerido(v, 'la marca'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CampoTexto(
                      etiqueta: 'Modelo',
                      controlador: _modelo,
                      icono: Icons.calendar_month_outlined,
                      hint: '$anioActual',
                      teclado: TextInputType.number,
                      formateadores: [Formateadores.soloDigitos],
                      longitudMaxima: 4,
                      obligatorio: true,
                      validador: (v) {
                        final anio = int.tryParse(v);
                        if (anio == null) return 'Ingresa el año.';
                        if (anio < 1970 || anio > anioActual + 1) {
                          return 'Año no válido.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CampoTexto(
                      etiqueta: 'Capacidad',
                      controlador: _capacidad,
                      icono: Icons.groups_outlined,
                      hint: 'Pasajeros',
                      teclado: TextInputType.number,
                      formateadores: [Formateadores.soloDigitos],
                      longitudMaxima: 2,
                      obligatorio: true,
                      validador: (v) {
                        final cantidad = int.tryParse(v);
                        if (cantidad == null || cantidad < 1) {
                          return 'Mínimo 1.';
                        }
                        return cantidad > 60 ? 'Máximo 60.' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CampoTexto(
                      etiqueta: 'Tarjeta de propiedad',
                      controlador: _tarjeta,
                      icono: Icons.description_outlined,
                      hint: 'N.° de licencia',
                      formateadores: [Formateadores.mayusculas],
                      obligatorio: true,
                      validador: (v) => Validar.requerido(v, 'la tarjeta'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            const TituloSeccionFormulario(
              titulo: 'Operación',
              icono: Icons.settings_outlined,
            ),
            const SizedBox(height: 12),
            CampoSelector<String?>(
              etiqueta: 'Conductor asignado',
              valor: _conductor,
              icono: Icons.badge_outlined,
              opciones: [
                const OpcionSelector<String?>(
                  valor: null,
                  texto: 'Sin conductor asignado',
                ),
                if (_conductor != null &&
                    !_conductores.any((c) => c.identificacion == _conductor))
                  OpcionSelector<String?>(
                    valor: _conductor,
                    texto: 'C.C. $_conductor',
                    habilitada: !_vigentes.containsKey(_conductor),
                    detalle: _vigentes.containsKey(_conductor)
                        ? 'Sancionado hasta ${Fechas.corta(_vigentes[_conductor]!.fechaFin)}'
                        : 'Conductor asignado actualmente',
                  ),
                for (final conductor in _conductores)
                  OpcionSelector<String?>(
                    valor: conductor.identificacion,
                    texto: conductor.nombres,
                    habilitada: _motivoBloqueo(conductor) == null,
                    detalle:
                        _motivoBloqueo(conductor) ??
                        'C.C. ${conductor.identificacion} · Licencia ${conductor.categoriaLicencia ?? ''}',
                  ),
              ],
              alCambiar: (valor) => setState(() => _conductor = valor),
            ),
            if (_conductor != null && _vigentes.containsKey(_conductor)) ...[
              const SizedBox(height: 10),
              Aviso(
                titulo: 'Conductor sancionado',
                mensaje:
                    'El conductor actual tiene sanción vigente hasta el ${Fechas.corta(_vigentes[_conductor]!.fechaFin)}. Debes asignar otro conductor para guardar.',
                tono: TonoEstado.peligro,
              ),
            ],
            const SizedBox(height: 16),
            CampoSelector<int>(
              etiqueta: 'Tarifa',
              valor: _tarifa,
              icono: Icons.payments_outlined,
              hint: _tarifas.isEmpty ? 'No hay tarifas activas' : 'Seleccionar tarifa',
              obligatorio: !_esEdicion,
              validador: _esEdicion
                  ? null
                  : (v) => Validar.seleccion(v, 'la tarifa'),
              opciones: [
                for (final tarifa in _tarifas)
                  OpcionSelector(
                    valor: tarifa.id,
                    texto: '${tarifa.nombre} · ${Formato.moneda(tarifa.total)}',
                  ),
              ],
              alCambiar: (valor) => setState(() => _tarifa = valor),
            ),
            const SizedBox(height: 16),
            InterruptorCampo(
              titulo: 'Vehículo operativo',
              descripcion: 'Habilitado para planillas y despachos',
              valor: _activo,
              alCambiar: (valor) => setState(() => _activo = valor),
            ),
            const SizedBox(height: 24),
            const TituloSeccionFormulario(
              titulo: 'Vigencias',
              icono: Icons.event_available_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoFecha(
                    etiqueta: 'Vigencia SOAT',
                    valor: _soat,
                    primera: DateTime(anioActual - 3),
                    obligatorio: true,
                    validador: (v) => Validar.fecha(v, 'la vigencia del SOAT'),
                    alCambiar: (fecha) => _soat = fecha,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CampoFecha(
                    etiqueta: 'Vigencia TRM',
                    valor: _trm,
                    primera: DateTime(anioActual - 3),
                    obligatorio: true,
                    validador: (v) => Validar.fecha(v, 'la vigencia de la TRM'),
                    alCambiar: (fecha) => _trm = fecha,
                  ),
                ),
              ],
            ),
            if (!_esEdicion) ...[
              const SizedBox(height: 16),
              CampoFecha(
                etiqueta: 'Fecha de ingreso',
                valor: _ingreso,
                ultima: Fechas.hoy,
                obligatorio: true,
                icono: Icons.login,
                validador: (v) => Validar.fecha(v, 'la fecha de ingreso'),
                alCambiar: (fecha) => _ingreso = fecha,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
