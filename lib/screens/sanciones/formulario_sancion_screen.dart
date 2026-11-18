import 'package:flutter/material.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/conductor/conductor.dart';
import 'package:transcoorp/models/sancion/sancion.dart';
import 'package:transcoorp/services/local/gestor_sesion.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/conductor_service.dart';
import 'package:transcoorp/services/remote/sancion_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/campos_formulario.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/mensaje_error.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';

class FormularioSancionScreen extends StatefulWidget {
  const FormularioSancionScreen({super.key, this.conductor});

  final Conductor? conductor;

  @override
  State<FormularioSancionScreen> createState() =>
      _FormularioSancionScreenState();
}

class _FormularioSancionScreenState extends State<FormularioSancionScreen> {
  static const _motivosFrecuentes = [
    'Inasistencia injustificada al turno',
    'Exceso de velocidad reportado',
    'Sobrecupo de pasajeros o carga',
    'Incumplimiento de la ruta asignada',
    'Trato inadecuado a usuarios',
    'Conducción bajo efectos de alcohol',
  ];

  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final SancionService _servicio = SancionService();
  final TextEditingController _motivo = TextEditingController();
  final TextEditingController _observaciones = TextEditingController();

  late String? _conductor = widget.conductor?.identificacion;
  DateTime? _inicio = Fechas.hoy;
  DateTime? _fin;

  List<Conductor> _conductores = const [];
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
      final conductores = widget.conductor != null
          ? [widget.conductor!]
          : await ConductorService().todos();
      final vigentes = await _servicio.vigentesPorConductor();
      if (!mounted) return;
      setState(() {
        _conductores = conductores;
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

  Conductor? get _seleccionado {
    for (final conductor in _conductores) {
      if (conductor.identificacion == _conductor) return conductor;
    }
    return null;
  }

  int get _dias {
    if (_inicio == null || _fin == null) return 0;
    return Fechas.soloFecha(_fin!).difference(Fechas.soloFecha(_inicio!)).inDays + 1;
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;

    if (_vigentes.containsKey(_conductor)) {
      setState(
        () => _errorServidor =
            'El conductor ya tiene una sanción vigente hasta el ${Fechas.corta(_vigentes[_conductor]!.fechaFin)}.',
      );
      return;
    }

    final conductor = _seleccionado;
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Confirmar sanción',
      mensaje:
          '${conductor?.nombres ?? 'El conductor'} no podrá ser asignado a operaciones del ${Fechas.corta(_inicio)} al ${Fechas.corta(_fin)} ($_dias ${_dias == 1 ? 'día' : 'días'}).',
      textoConfirmar: 'Registrar sanción',
      peligrosa: true,
      icono: Icons.gavel,
    );
    if (!confirmado || !mounted) return;

    setState(() => _guardando = true);
    try {
      final sancion = await _servicio.registrar(
        identificacionConductor: _conductor!,
        motivo: Sancion.componerMotivo(_motivo.text, _observaciones.text),
        fechaInicio: _inicio!,
        fechaFin: _fin!,
      );
      if (mounted) Navigator.pop(context, sancion);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorServidor = e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final autorizado = GestorSesion.actual?.puedeSancionar ?? false;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: const EncabezadoModulo(
        titulo: 'Registrar sanción',
        subtitulo: 'Solo Gerencia y Asistencia',
      ),
      body: !autorizado
          ? const EstadoVacio(
              icono: Icons.lock_outline,
              titulo: 'Acción restringida',
              mensaje:
                  'Solo los perfiles GERENTE y ASISTENTE pueden sancionar conductores.',
            )
          : _cargando
          ? const EstadoCarga(mensaje: 'Cargando conductores...')
          : _errorCarga != null
          ? EstadoError(mensaje: _errorCarga!, alReintentar: _cargar)
          : _contenido(),
      bottomNavigationBar: !autorizado || _cargando || _errorCarga != null
          ? null
          : BarraAcciones(
              textoPrincipal: 'Registrar sanción',
              alPrincipal: _guardar,
              cargando: _guardando,
            ),
    );
  }

  Widget _contenido() {
    return Form(
      key: _formulario,
      child: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Aviso(
              titulo: 'Efecto de la sanción',
              mensaje:
                  'Mientras la fecha actual esté dentro del periodo, el conductor no podrá ser asignado a vehículos, planillas ni despachos.',
              tono: TonoEstado.alerta,
            ),
            const SizedBox(height: 16),
            if (_errorServidor != null) ...[
              MensajeError(_errorServidor!),
              const SizedBox(height: 16),
            ],
            CampoSelector<String>(
              etiqueta: 'Conductor',
              valor: _conductor,
              icono: Icons.badge_outlined,
              hint: 'Seleccionar conductor',
              obligatorio: true,
              habilitado: widget.conductor == null,
              validador: (v) => Validar.seleccion(v, 'el conductor'),
              opciones: [
                for (final conductor in _conductores)
                  OpcionSelector(
                    valor: conductor.identificacion,
                    texto: conductor.nombres,
                    habilitada: !_vigentes.containsKey(conductor.identificacion),
                    detalle: _vigentes.containsKey(conductor.identificacion)
                        ? 'Sancionado hasta ${Fechas.corta(_vigentes[conductor.identificacion]!.fechaFin)}'
                        : 'C.C. ${conductor.identificacion}',
                  ),
              ],
              alCambiar: (valor) => setState(() => _conductor = valor),
            ),
            const SizedBox(height: 24),
            const TituloSeccionFormulario(
              titulo: 'Periodo',
              icono: Icons.date_range,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoFecha(
                    etiqueta: 'Fecha inicial',
                    valor: _inicio,
                    primera: Fechas.hoy,
                    obligatorio: true,
                    validador: (v) => Validar.fecha(v, 'la fecha inicial'),
                    alCambiar: (fecha) => setState(() => _inicio = fecha),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CampoFecha(
                    etiqueta: 'Fecha final',
                    valor: _fin,
                    primera: Fechas.hoy,
                    obligatorio: true,
                    validador: (v) {
                      if (v == null) return 'Selecciona la fecha final.';
                      if (_inicio != null &&
                          Fechas.soloFecha(v).isBefore(Fechas.soloFecha(_inicio!))) {
                        return 'Debe ser igual o posterior a la inicial.';
                      }
                      return null;
                    },
                    alCambiar: (fecha) => setState(() => _fin = fecha),
                  ),
                ),
              ],
            ),
            if (_dias > 0) ...[
              const SizedBox(height: 10),
              FilaDato(
                icono: Icons.timelapse,
                etiqueta: 'Duración de la sanción',
                valor: '$_dias ${_dias == 1 ? 'día' : 'días'}',
              ),
            ],
            const SizedBox(height: 24),
            const TituloSeccionFormulario(
              titulo: 'Motivo',
              icono: Icons.description_outlined,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final motivo in _motivosFrecuentes)
                  ActionChip(
                    label: Text(motivo),
                    onPressed: () => setState(() => _motivo.text = motivo),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            CampoTexto(
              etiqueta: 'Motivo de la sanción',
              controlador: _motivo,
              icono: Icons.report_outlined,
              hint: 'Describe la falta cometida',
              lineas: 2,
              obligatorio: true,
              mayusculas: TextCapitalization.sentences,
              validador: (v) => v.trim().length < 5
                  ? 'Describe el motivo (mínimo 5 caracteres).'
                  : null,
            ),
            const SizedBox(height: 16),
            CampoTexto(
              etiqueta: 'Observaciones (opcional)',
              controlador: _observaciones,
              icono: Icons.notes,
              hint: 'Resolución, número de acta o detalles adicionales',
              lineas: 3,
              mayusculas: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}
