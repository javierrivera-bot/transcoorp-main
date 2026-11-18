import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/mantenimiento/mantenimiento.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/mantenimientos/formulario_mantenimiento_screen.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/mantenimiento_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/boton_principal.dart';
import 'package:transcoorp/widgets/campos_formulario.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/filtros.dart';
import 'package:transcoorp/widgets/mensaje_error.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';
import 'package:transcoorp/widgets/vista_paginada.dart';

class ListadoMantenimientosScreen extends StatefulWidget {
  const ListadoMantenimientosScreen({super.key, this.placa});

  final String? placa;

  @override
  State<ListadoMantenimientosScreen> createState() =>
      _ListadoMantenimientosScreenState();
}

class _ListadoMantenimientosScreenState
    extends State<ListadoMantenimientosScreen> {
  final MantenimientoService _servicio = MantenimientoService();
  late final ControladorPaginado<Mantenimiento> _controlador =
      ControladorPaginado(_cargar);

  late String _placa = widget.placa ?? '';
  String? _estado;

  @override
  void initState() {
    super.initState();
    _controlador.recargar();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<Pagina<Mantenimiento>> _cargar(int pagina) =>
      _servicio.listar(pagina: pagina, placa: _placa, estado: _estado);

  Future<void> _registrar() async {
    final registrado = await abrir<Mantenimiento>(
      context,
      FormularioMantenimientoScreen(placa: widget.placa),
    );
    if (registrado == null || !mounted) return;
    mostrarExito(
      context,
      'Ingreso de ${registrado.placaVehiculo} a mantenimiento registrado.',
    );
    _controlador.recargar();
  }

  Future<void> _registrarSalida(Mantenimiento mantenimiento) async {
    final actualizado = await showModalBottomSheet<Mantenimiento>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colores.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _HojaSalida(mantenimiento: mantenimiento),
    );
    if (actualizado == null || !mounted) return;
    mostrarExito(context, 'Salida de ${actualizado.placaVehiculo} registrada.');
    _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Mantenimiento',
        subtitulo: widget.placa == null
            ? 'Ingresos y salidas de taller'
            : 'Historial del vehículo ${widget.placa}',
        acciones: [
          AccionEncabezado(
            icono: Icons.add,
            tooltip: 'Registrar ingreso',
            alPresionar: _registrar,
          ),
        ],
      ),
      body: PantallaLista(
        filtros: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.placa == null) ...[
              CampoBusqueda(
                hint: 'Buscar por placa',
                mayusculas: true,
                alBuscar: (texto) {
                  _placa = texto.toUpperCase();
                  _controlador.recargar();
                },
              ),
              const SizedBox(height: 12),
            ],
            BarraFiltros<String?>(
              seleccionado: _estado,
              alCambiar: (valor) {
                setState(() => _estado = valor);
                _controlador.recargar();
              },
              opciones: const [
                OpcionFiltro(null, 'Todos'),
                OpcionFiltro(EstadoMantenimiento.enMantenimiento, 'En taller'),
                OpcionFiltro(EstadoMantenimiento.finalizado, 'Finalizados'),
              ],
            ),
          ],
        ),
        lista: VistaPaginada<Mantenimiento>(
          controlador: _controlador,
          constructor: (context, mantenimiento) => _TarjetaMantenimiento(
            mantenimiento: mantenimiento,
            alRegistrarSalida: () => _registrarSalida(mantenimiento),
          ),
          vacio: EstadoVacio(
            icono: Icons.build_outlined,
            titulo: 'Sin registros de mantenimiento',
            mensaje: 'Los ingresos a taller aparecerán en esta sección.',
            textoAccion: 'Registrar ingreso',
            alAccion: _registrar,
          ),
        ),
      ),
    );
  }
}

class _TarjetaMantenimiento extends StatelessWidget {
  const _TarjetaMantenimiento({
    required this.mantenimiento,
    required this.alRegistrarSalida,
  });

  final Mantenimiento mantenimiento;
  final VoidCallback alRegistrarSalida;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final m = mantenimiento;

    return TarjetaBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PlacaVehiculo(placa: m.placaVehiculo),
              const Spacer(),
              m.abierto
                  ? const ChipEstado(
                      texto: 'En mantenimiento',
                      tono: TonoEstado.alerta,
                      icono: Icons.build,
                    )
                  : const ChipEstado(
                      texto: 'Finalizado',
                      tono: TonoEstado.exito,
                      icono: Icons.check,
                    ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            m.motivo,
            style: AppTheme.montserrat(
              size: 14,
              weight: FontWeight.w600,
              color: c.textoOscuro,
            ),
          ),
          if (m.estadoVehiculoIngreso != null) ...[
            const SizedBox(height: 2),
            Text(
              'Estado al ingreso: ${m.estadoVehiculoIngreso}',
              style: AppTheme.inter(size: 12.5, color: c.textoSutil),
            ),
          ],
          const SizedBox(height: 10),
          GrillaDatos(
            datos: [
              FilaDato(etiqueta: 'Ingreso', valor: Fechas.fechaHora(m.fechaIngreso)),
              FilaDato(
                etiqueta: 'Salida',
                valor: m.fechaSalida == null
                    ? 'Pendiente'
                    : Fechas.fechaHora(m.fechaSalida),
              ),
            ],
          ),
          if (m.observaciones != null || m.observacionesIngreso != null) ...[
            const SizedBox(height: 10),
            Text(
              Formato.valorO(m.observaciones ?? m.observacionesIngreso),
              style: AppTheme.inter(size: 12.5, color: c.textoGris),
            ),
          ],
          if (m.abierto) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: alRegistrarSalida,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Registrar salida'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.primario,
                side: BorderSide(color: c.primario.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HojaSalida extends StatefulWidget {
  const _HojaSalida({required this.mantenimiento});

  final Mantenimiento mantenimiento;

  @override
  State<_HojaSalida> createState() => _HojaSalidaState();
}

class _HojaSalidaState extends State<_HojaSalida> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final TextEditingController _observaciones = TextEditingController();
  DateTime? _fecha = DateTime.now();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _observaciones.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    final ingreso = widget.mantenimiento.fechaIngreso;
    if (ingreso != null && Fechas.soloFecha(_fecha!).isBefore(Fechas.soloFecha(ingreso))) {
      setState(() => _error = 'La salida no puede ser anterior al ingreso.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final ahora = DateTime.now();
      final fecha = DateTime(
        _fecha!.year,
        _fecha!.month,
        _fecha!.day,
        ahora.hour,
        ahora.minute,
      );
      final actualizado = await MantenimientoService().registrarSalida(
        widget.mantenimiento.id,
        fechaSalida: fecha,
        observaciones: _observaciones.text.trim(),
      );
      if (mounted) Navigator.pop(context, actualizado);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.borde,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Registrar salida de taller',
              style: AppTheme.montserrat(
                size: 18,
                weight: FontWeight.w700,
                color: c.textoOscuro,
              ),
            ),
            Text(
              'Vehículo ${widget.mantenimiento.placaVehiculo}',
              style: AppTheme.inter(size: 13, color: c.textoSutil),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              MensajeError(_error!),
              const SizedBox(height: 12),
            ],
            CampoFecha(
              etiqueta: 'Fecha de salida',
              valor: _fecha,
              ultima: Fechas.hoy,
              obligatorio: true,
              validador: (v) => Validar.fecha(v, 'la fecha de salida'),
              alCambiar: (fecha) => _fecha = fecha,
            ),
            const SizedBox(height: 16),
            CampoTexto(
              etiqueta: 'Observaciones',
              controlador: _observaciones,
              icono: Icons.notes,
              hint: 'Trabajos realizados y estado de entrega',
              lineas: 3,
              mayusculas: TextCapitalization.sentences,
              obligatorio: true,
              validador: (v) => Validar.requerido(v, 'las observaciones'),
            ),
            const SizedBox(height: 20),
            BotonPrincipal(
              texto: 'Registrar salida',
              alPresionar: _guardar,
              cargando: _guardando,
            ),
          ],
        ),
      ),
    );
  }
}
