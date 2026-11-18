import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/planilla/planilla.dart';
import 'package:transcoorp/models/sancion/sancion.dart';
import 'package:transcoorp/models/tarifa/tarifa.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/planilla_service.dart';
import 'package:transcoorp/services/remote/sancion_service.dart';
import 'package:transcoorp/services/remote/tarifa_service.dart';
import 'package:transcoorp/services/remote/vehiculo_service.dart';
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
import 'package:transcoorp/widgets/tarjeta_base.dart';

class GenerarPlanillasScreen extends StatefulWidget {
  const GenerarPlanillasScreen({super.key});

  @override
  State<GenerarPlanillasScreen> createState() => _GenerarPlanillasScreenState();
}

class _GenerarPlanillasScreenState extends State<GenerarPlanillasScreen> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();

  DateTime? _fecha = Fechas.hoy;
  String _tipo = TipoPlanilla.viaje;
  int? _tarifa;
  final Set<String> _seleccionados = {};

  List<Vehiculo> _vehiculos = const [];
  List<Tarifa> _tarifas = const [];
  Map<String, Sancion> _vigentes = const {};
  bool _cargando = true;
  bool _generando = false;
  String? _errorCarga;
  String? _errorServidor;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final vehiculos = await VehiculoService().todos();
      final tarifas = await TarifaService().activas();
      final vigentes = await SancionService().vigentesPorConductor();
      if (!mounted) return;
      setState(() {
        _vehiculos = vehiculos;
        _tarifas = tarifas;
        _vigentes = vigentes;
        _tarifa = tarifas.length == 1 ? tarifas.first.id : null;
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

  String? _bloqueo(Vehiculo vehiculo) {
    final sancion = vehiculo.identificacionConductor == null
        ? null
        : _vigentes[vehiculo.identificacionConductor];
    if (sancion != null) {
      return 'Conductor sancionado hasta ${Fechas.corta(sancion.fechaFin)}';
    }
    if (vehiculo.identificacionConductor == null) return 'Sin conductor asignado';
    if (!vehiculo.documentosAlDia) return 'SOAT o TRM vencidos';
    return null;
  }

  List<Vehiculo> get _habilitados =>
      _vehiculos.where((v) => _bloqueo(v) == null).toList();

  void _alternarTodos() {
    setState(() {
      if (_seleccionados.length == _habilitados.length) {
        _seleccionados.clear();
      } else {
        _seleccionados
          ..clear()
          ..addAll(_habilitados.map((v) => v.placa));
      }
    });
  }

  Future<void> _generar() async {
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;
    if (_seleccionados.isEmpty) {
      setState(() => _errorServidor = 'Selecciona al menos un vehículo.');
      return;
    }

    final confirmado = await confirmarAccion(
      context,
      titulo: 'Generar planillas',
      mensaje:
          'Se generarán ${_seleccionados.length} planillas de tipo ${TipoPlanilla.etiqueta(_tipo).toLowerCase()} para el ${Fechas.corta(_fecha)}.',
      textoConfirmar: 'Generar',
      icono: Icons.post_add,
    );
    if (!confirmado || !mounted) return;

    setState(() => _generando = true);
    try {
      final resultado = await PlanillaService().generarMasivas(
        fecha: _fecha!,
        placas: _seleccionados.toList(),
        tipo: _tipo,
        tarifaId: _tarifa,
      );
      if (!mounted) return;
      await mostrarInformacion(
        context,
        titulo: 'Generación completada',
        icono: resultado.rechazadas.isEmpty
            ? Icons.check_circle_outline
            : Icons.info_outline,
        contenido: _Resumen(resultado: resultado),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorServidor = e.message);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: const EncabezadoModulo(
        titulo: 'Generar planillas',
        subtitulo: 'Emisión múltiple en una sola operación',
      ),
      body: _cargando
          ? const EstadoCarga(mensaje: 'Cargando vehículos y tarifas...')
          : _errorCarga != null
          ? EstadoError(mensaje: _errorCarga!, alReintentar: _cargar)
          : _contenido(c),
      bottomNavigationBar: _cargando || _errorCarga != null
          ? null
          : BarraAcciones(
              textoPrincipal: _seleccionados.isEmpty
                  ? 'Generar planillas'
                  : 'Generar (${_seleccionados.length})',
              alPrincipal: _generar,
              cargando: _generando,
            ),
    );
  }

  Widget _contenido(ColoresApp c) {
    return Form(
      key: _formulario,
      child: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Aviso(
              titulo: 'Emisión en bloque',
              mensaje:
                  'Configura los datos comunes y selecciona los vehículos. Los vehículos con conductor sancionado o documentos vencidos no pueden incluirse.',
              tono: TonoEstado.info,
            ),
            const SizedBox(height: 16),
            if (_errorServidor != null) ...[
              MensajeError(_errorServidor!),
              const SizedBox(height: 16),
            ],
            CampoFecha(
              etiqueta: 'Fecha de emisión',
              valor: _fecha,
              primera: Fechas.hoy,
              obligatorio: true,
              validador: (v) => Validar.fecha(v, 'la fecha'),
              alCambiar: (fecha) => _fecha = fecha,
            ),
            const SizedBox(height: 16),
            CampoSelector<String>(
              etiqueta: 'Tipo de planilla',
              valor: _tipo,
              icono: Icons.local_offer_outlined,
              obligatorio: true,
              opciones: [
                for (final tipo in TipoPlanilla.valores)
                  OpcionSelector(valor: tipo, texto: TipoPlanilla.etiqueta(tipo)),
              ],
              alCambiar: (valor) =>
                  setState(() => _tipo = valor ?? TipoPlanilla.viaje),
            ),
            const SizedBox(height: 16),
            CampoSelector<int>(
              etiqueta: 'Tarifa autorizada',
              valor: _tarifa,
              icono: Icons.payments_outlined,
              hint: _tarifas.isEmpty ? 'No hay tarifas activas' : 'Seleccionar tarifa',
              obligatorio: true,
              validador: (v) => Validar.seleccion(v, 'la tarifa'),
              opciones: [
                for (final tarifa in _tarifas)
                  OpcionSelector(
                    valor: tarifa.id,
                    texto: '${tarifa.nombre} · ${Formato.moneda(tarifa.total)}',
                  ),
              ],
              alCambiar: (valor) => setState(() => _tarifa = valor),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: EtiquetaCampo(
                    'Vehículos (${_seleccionados.length}/${_habilitados.length})',
                    obligatorio: true,
                  ),
                ),
                TextButton(
                  onPressed: _habilitados.isEmpty ? null : _alternarTodos,
                  child: Text(
                    _seleccionados.length == _habilitados.length &&
                            _habilitados.isNotEmpty
                        ? 'Quitar todos'
                        : 'Seleccionar todos',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_vehiculos.isEmpty)
              const EstadoVacio(
                icono: Icons.directions_bus_outlined,
                titulo: 'Sin vehículos operativos',
                mensaje: 'Registra o activa vehículos para generar planillas.',
              )
            else
              for (final vehiculo in _vehiculos) ...[
                _OpcionVehiculo(
                  vehiculo: vehiculo,
                  bloqueo: _bloqueo(vehiculo),
                  seleccionado: _seleccionados.contains(vehiculo.placa),
                  alCambiar: (valor) => setState(() {
                    if (valor) {
                      _seleccionados.add(vehiculo.placa);
                    } else {
                      _seleccionados.remove(vehiculo.placa);
                    }
                  }),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _OpcionVehiculo extends StatelessWidget {
  const _OpcionVehiculo({
    required this.vehiculo,
    required this.bloqueo,
    required this.seleccionado,
    required this.alCambiar,
  });

  final Vehiculo vehiculo;
  final String? bloqueo;
  final bool seleccionado;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final habilitado = bloqueo == null;

    return Opacity(
      opacity: habilitado ? 1 : 0.6,
      child: TarjetaBase(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        colorBorde: seleccionado ? c.primario : null,
        alTocar: habilitado ? () => alCambiar(!seleccionado) : null,
        child: Row(
          children: [
            Checkbox(
              value: seleccionado,
              onChanged: habilitado ? (v) => alCambiar(v ?? false) : null,
              activeColor: AppColors.primario,
            ),
            PlacaVehiculo(placa: vehiculo.placa),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehiculo.tipo ?? 'Vehículo'} · ${vehiculo.descripcion}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(
                      size: 13,
                      weight: FontWeight.w500,
                      color: c.textoOscuro,
                    ),
                  ),
                  Text(
                    bloqueo ?? '${vehiculo.capacidadPasajeros} pasajeros',
                    style: AppTheme.inter(
                      size: 11.5,
                      weight: habilitado ? FontWeight.w400 : FontWeight.w600,
                      color: habilitado ? c.textoSutil : AppColors.rojoAlerta,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.resultado});

  final ResultadoPlanillaMasiva resultado;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GrillaDatos(
            datos: [
              FilaDato(
                etiqueta: 'Registradas',
                valor: '${resultado.totalRegistradas}',
                destacado: true,
              ),
              FilaDato(
                etiqueta: 'Rechazadas',
                valor: '${resultado.rechazadas.length}',
                destacado: true,
              ),
            ],
          ),
          if (resultado.correctas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              resultado.correctas
                  .map((p) => '${p.codigo} · ${p.placaVehiculo}')
                  .join('\n'),
              style: AppTheme.inter(size: 12.5, color: c.textoGris),
            ),
          ],
          for (final rechazo in resultado.rechazadas) ...[
            const SizedBox(height: 8),
            Aviso(
              titulo: rechazo.placa,
              mensaje: rechazo.motivo,
              tono: TonoEstado.peligro,
            ),
          ],
        ],
      ),
    );
  }
}
