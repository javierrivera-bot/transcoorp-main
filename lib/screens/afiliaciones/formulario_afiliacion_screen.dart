import 'package:flutter/material.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/afiliacion/afiliacion.dart';
import 'package:transcoorp/models/asociado/asociado.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/services/remote/afiliacion_service.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/asociado_service.dart';
import 'package:transcoorp/services/remote/servicio_base.dart';
import 'package:transcoorp/services/remote/vehiculo_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/campos_formulario.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/mensaje_error.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';

class FormularioAfiliacionScreen extends StatefulWidget {
  const FormularioAfiliacionScreen({
    super.key,
    this.afiliacion,
    this.identificacionAsociado,
  });

  final Afiliacion? afiliacion;
  final String? identificacionAsociado;

  @override
  State<FormularioAfiliacionScreen> createState() =>
      _FormularioAfiliacionScreenState();
}

class _FormularioAfiliacionScreenState
    extends State<FormularioAfiliacionScreen> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final AfiliacionService _servicio = AfiliacionService();

  late String? _asociado =
      widget.afiliacion?.identificacionAsociado ?? widget.identificacionAsociado;
  late String? _placa = widget.afiliacion?.placaVehiculo;
  late DateTime? _fechaAfiliacion =
      widget.afiliacion?.fechaAfiliacion ?? Fechas.hoy;
  late DateTime? _fechaFin = widget.afiliacion?.fechaFin;
  late String _estado = widget.afiliacion?.estado ?? EstadoAfiliacion.activa;

  List<Asociado> _asociados = const [];
  List<Vehiculo> _vehiculos = const [];
  bool _cargando = true;
  bool _guardando = false;
  String? _errorCarga;
  String? _errorServidor;

  bool get _esEdicion => widget.afiliacion != null;

  @override
  void initState() {
    super.initState();
    _cargarOpciones();
  }

  Future<void> _cargarOpciones() async {
    if (_esEdicion) {
      setState(() => _cargando = false);
      return;
    }
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final resultados = await Future.wait<Object>([
        AsociadoService().listar(tamano: ServicioBase.tamanoMaximo, activo: true),
        VehiculoService().todos(),
      ]);
      if (!mounted) return;
      setState(() {
        _asociados = (resultados[0] as Pagina<Asociado>).items;
        _vehiculos = resultados[1] as List<Vehiculo>;
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

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);
    try {
      final Afiliacion resultado = _esEdicion
          ? await _servicio.editar(
              widget.afiliacion!,
              fechaAfiliacion: _fechaAfiliacion!,
              fechaFin: _fechaFin,
              estado: _estado,
            )
          : await _servicio.registrar(
              identificacionAsociado: _asociado!,
              placaVehiculo: _placa!,
              fechaAfiliacion: _fechaAfiliacion!,
              fechaFin: _fechaFin,
              estado: _estado,
            );
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
        titulo: _esEdicion ? 'Editar afiliación' : 'Nueva afiliación',
        subtitulo: 'Vínculo asociado — vehículo',
      ),
      body: _cargando
          ? const EstadoCarga(mensaje: 'Cargando asociados y vehículos...')
          : _errorCarga != null
          ? EstadoError(mensaje: _errorCarga!, alReintentar: _cargarOpciones)
          : _formularioContenido(),
      bottomNavigationBar: _cargando || _errorCarga != null
          ? null
          : BarraAcciones(
              textoPrincipal: _esEdicion ? 'Guardar cambios' : 'Afiliar',
              alPrincipal: _guardar,
              cargando: _guardando,
            ),
    );
  }

  Widget _formularioContenido() {
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
            const TituloSeccionFormulario(
              titulo: 'Partes del vínculo',
              icono: Icons.handshake_outlined,
            ),
            const SizedBox(height: 12),
            if (_esEdicion) ...[
              FilaDato(
                icono: Icons.person_outline,
                etiqueta: 'Asociado',
                valor: 'C.C. ${widget.afiliacion!.identificacionAsociado}',
              ),
              const SizedBox(height: 10),
              FilaDato(
                icono: Icons.directions_car_outlined,
                etiqueta: 'Vehículo',
                valor: widget.afiliacion!.placaVehiculo,
              ),
            ] else ...[
              CampoSelector<String>(
                etiqueta: 'Asociado',
                valor: _asociado,
                icono: Icons.person_outline,
                hint: 'Seleccionar asociado',
                obligatorio: true,
                validador: (v) => Validar.seleccion(v, 'el asociado'),
                opciones: [
                  for (final asociado in _asociados)
                    OpcionSelector(
                      valor: asociado.identificacion,
                      texto: asociado.nombres,
                      detalle: 'C.C. ${asociado.identificacion}',
                    ),
                ],
                alCambiar: (valor) => setState(() => _asociado = valor),
              ),
              const SizedBox(height: 16),
              CampoSelector<String>(
                etiqueta: 'Vehículo',
                valor: _placa,
                icono: Icons.directions_car_outlined,
                hint: 'Seleccionar vehículo',
                obligatorio: true,
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
            ],
            const SizedBox(height: 24),
            const TituloSeccionFormulario(
              titulo: 'Vigencia',
              icono: Icons.event_outlined,
            ),
            const SizedBox(height: 12),
            CampoFecha(
              etiqueta: 'Fecha de afiliación',
              valor: _fechaAfiliacion,
              ultima: Fechas.hoy,
              obligatorio: true,
              validador: (v) => Validar.fecha(v, 'la fecha de afiliación'),
              alCambiar: (fecha) => setState(() => _fechaAfiliacion = fecha),
            ),
            const SizedBox(height: 16),
            CampoFecha(
              etiqueta: 'Fecha de fin (si aplica)',
              valor: _fechaFin,
              hint: 'Sin fecha de finalización',
              validador: (v) {
                if (v == null || _fechaAfiliacion == null) return null;
                return Fechas.soloFecha(v).isBefore(_fechaAfiliacion!)
                    ? 'Debe ser posterior a la fecha de afiliación.'
                    : null;
              },
              alCambiar: (fecha) => setState(() => _fechaFin = fecha),
            ),
            const SizedBox(height: 16),
            CampoSelector<String>(
              etiqueta: 'Estado',
              valor: _estado,
              icono: Icons.flag_outlined,
              obligatorio: true,
              opciones: [
                for (final estado in EstadoAfiliacion.valores)
                  OpcionSelector(valor: estado, texto: Formato.capitalizar(estado)),
              ],
              alCambiar: (valor) => setState(
                () => _estado = valor ?? EstadoAfiliacion.activa,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
