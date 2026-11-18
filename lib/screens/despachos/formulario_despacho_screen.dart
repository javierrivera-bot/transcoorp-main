import 'package:flutter/material.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/domain/rutas.dart';
import 'package:transcoorp/models/sancion/sancion.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/despacho_service.dart';
import 'package:transcoorp/services/remote/sancion_service.dart';
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

class FormularioDespachoScreen extends StatefulWidget {
  const FormularioDespachoScreen({super.key});

  @override
  State<FormularioDespachoScreen> createState() =>
      _FormularioDespachoScreenState();
}

class _FormularioDespachoScreenState extends State<FormularioDespachoScreen> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final TextEditingController _pasajeros = TextEditingController();

  String? _ruta;
  String? _placa;
  DateTime? _fecha = Fechas.hoy;
  TimeOfDay? _hora = TimeOfDay.now();

  List<Vehiculo> _vehiculos = const [];
  Map<String, Sancion> _vigentes = const {};
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
    _pasajeros.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final vehiculos = await VehiculoService().todos();
      final vigentes = await SancionService().vigentesPorConductor();
      if (!mounted) return;
      setState(() {
        _vehiculos = vehiculos;
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

  Vehiculo? get _vehiculo {
    for (final vehiculo in _vehiculos) {
      if (vehiculo.placa == _placa) return vehiculo;
    }
    return null;
  }

  String? _bloqueo(Vehiculo vehiculo) {
    final conductor = vehiculo.identificacionConductor;
    if (conductor == null) return 'Sin conductor asignado';
    final sancion = _vigentes[conductor];
    if (sancion != null) {
      return 'Conductor sancionado hasta ${Fechas.corta(sancion.fechaFin)}';
    }
    if (!vehiculo.documentosAlDia) return 'SOAT o TRM vencidos';
    return null;
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;

    final vehiculo = _vehiculo;
    final bloqueo = vehiculo == null ? null : _bloqueo(vehiculo);
    if (bloqueo != null) {
      setState(() => _errorServidor = 'No se puede despachar ${vehiculo!.placa}: $bloqueo.');
      return;
    }

    setState(() => _guardando = true);
    try {
      final despacho = await DespachoService().registrar(
        ruta: _ruta!,
        placaVehiculo: _placa!,
        fecha: _fecha!,
        hora: _hora ?? TimeOfDay.now(),
        numeroPasajeros: int.parse(_pasajeros.text.trim()),
      );
      if (mounted) Navigator.pop(context, despacho);
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
        titulo: 'Registrar despacho',
        subtitulo: 'Autorización de salida a ruta',
      ),
      body: _cargando
          ? const EstadoCarga(mensaje: 'Cargando vehículos disponibles...')
          : _errorCarga != null
          ? EstadoError(mensaje: _errorCarga!, alReintentar: _cargar)
          : _contenido(),
      bottomNavigationBar: _cargando || _errorCarga != null
          ? null
          : BarraAcciones(
              textoPrincipal: 'Registrar despacho',
              alPrincipal: _guardar,
              cargando: _guardando,
            ),
    );
  }

  Widget _contenido() {
    final ruta = _ruta == null ? null : CatalogoRutas.buscar(_ruta!);
    final vehiculo = _vehiculo;

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
            CampoSelector<String>(
              etiqueta: 'Ruta',
              valor: _ruta,
              icono: Icons.alt_route,
              hint: 'Seleccionar ruta',
              obligatorio: true,
              validador: (v) => Validar.seleccion(v, 'la ruta'),
              opciones: [
                for (final r in CatalogoRutas.activas)
                  OpcionSelector(
                    valor: r.etiqueta,
                    texto: '${r.codigo} · ${r.nombre}',
                    detalle: '${r.trayecto} · ${Formato.moneda(r.tarifa)}',
                  ),
              ],
              alCambiar: (valor) => setState(() => _ruta = valor),
            ),
            if (ruta != null) ...[
              const SizedBox(height: 10),
              FilaDato(
                icono: Icons.route_outlined,
                etiqueta: '${ruta.puntoOrigen} → ${ruta.puntoDestino}',
                valor: '${ruta.duracion} · ${ruta.distanciaKm} km',
              ),
            ],
            const SizedBox(height: 16),
            CampoSelector<String>(
              etiqueta: 'Vehículo',
              valor: _placa,
              icono: Icons.directions_car_outlined,
              hint: 'Seleccionar vehículo',
              obligatorio: true,
              validador: (v) => Validar.seleccion(v, 'el vehículo'),
              opciones: [
                for (final v in _vehiculos)
                  OpcionSelector(
                    valor: v.placa,
                    texto: '${v.placa} · ${v.tipo ?? 'Vehículo'}',
                    habilitada: _bloqueo(v) == null,
                    detalle: _bloqueo(v) ?? 'Capacidad ${v.capacidadPasajeros} pasajeros',
                  ),
              ],
              alCambiar: (valor) => setState(() => _placa = valor),
            ),
            if (_vigentes.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Aviso(
                titulo: 'Conductores sancionados',
                mensaje:
                    'Los vehículos con conductor sancionado aparecen deshabilitados y no pueden despacharse.',
                tono: TonoEstado.alerta,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoFecha(
                    etiqueta: 'Fecha',
                    valor: _fecha,
                    primera: Fechas.hoy.subtract(const Duration(days: 1)),
                    obligatorio: true,
                    validador: (v) => Validar.fecha(v),
                    alCambiar: (fecha) => _fecha = fecha,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CampoHora(
                    etiqueta: 'Hora',
                    valor: _hora,
                    obligatorio: true,
                    alCambiar: (hora) => _hora = hora,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CampoTexto(
              etiqueta: 'Número de pasajeros',
              controlador: _pasajeros,
              icono: Icons.groups_outlined,
              hint: vehiculo == null
                  ? 'Cantidad de pasajeros'
                  : 'Máximo ${vehiculo.capacidadPasajeros}',
              teclado: TextInputType.number,
              formateadores: [Formateadores.soloDigitos],
              longitudMaxima: 3,
              obligatorio: true,
              accion: TextInputAction.done,
              validador: (v) {
                final cantidad = int.tryParse(v);
                if (cantidad == null) return 'Ingresa el número de pasajeros.';
                if (cantidad < 0) return 'Valor no válido.';
                final capacidad = _vehiculo?.capacidadPasajeros ?? 0;
                if (capacidad > 0 && cantidad > capacidad) {
                  return 'Supera la capacidad del vehículo ($capacidad).';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
