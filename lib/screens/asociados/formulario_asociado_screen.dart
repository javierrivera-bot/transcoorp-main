import 'package:flutter/material.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/asociado/asociado.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/services/remote/afiliacion_service.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/asociado_service.dart';
import 'package:transcoorp/services/remote/vehiculo_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/campos_formulario.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/mensaje_error.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';

class FormularioAsociadoScreen extends StatefulWidget {
  const FormularioAsociadoScreen({super.key, this.asociado});

  final Asociado? asociado;

  @override
  State<FormularioAsociadoScreen> createState() =>
      _FormularioAsociadoScreenState();
}

class _FormularioAsociadoScreenState extends State<FormularioAsociadoScreen> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final AsociadoService _servicio = AsociadoService();
  final AfiliacionService _afiliaciones = AfiliacionService();
  final VehiculoService _vehiculos = VehiculoService();

  late final TextEditingController _identificacion = TextEditingController(
    text: widget.asociado?.identificacion,
  );
  late final TextEditingController _nombres = TextEditingController(
    text: widget.asociado?.nombres,
  );
  late final TextEditingController _celular = TextEditingController(
    text: widget.asociado?.celular,
  );
  late final TextEditingController _correo = TextEditingController(
    text: widget.asociado?.correo,
  );

  late DateTime? _fechaNacimiento = widget.asociado?.fechaNacimiento;
  DateTime? _fechaIngreso = Fechas.hoy;
  bool _activo = true;
  String? _placa;

  List<Vehiculo>? _listaVehiculos;
  bool _guardando = false;
  String? _errorServidor;

  bool get _esEdicion => widget.asociado != null;

  @override
  void initState() {
    super.initState();
    if (!_esEdicion) _cargarVehiculos();
  }

  @override
  void dispose() {
    _identificacion.dispose();
    _nombres.dispose();
    _celular.dispose();
    _correo.dispose();
    super.dispose();
  }

  Future<void> _cargarVehiculos() async {
    try {
      final lista = await _vehiculos.todos();
      if (mounted) setState(() => _listaVehiculos = lista);
    } on ApiException catch (_) {
      if (mounted) setState(() => _listaVehiculos = const []);
    }
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);
    try {
      final Asociado resultado;
      if (_esEdicion) {
        resultado = await _servicio.editar(
          widget.asociado!.identificacion,
          celular: _celular.text.trim(),
          correo: _correo.text.trim(),
          fechaNacimiento: _fechaNacimiento,
        );
      } else {
        resultado = await _servicio.registrar(
          identificacion: _identificacion.text.trim(),
          nombres: _nombres.text.trim(),
          activo: _activo,
          celular: _celular.text.trim(),
          correo: _correo.text.trim(),
          fechaNacimiento: _fechaNacimiento!,
          fechaIngreso: _fechaIngreso!,
        );
        if (_placa != null) {
          try {
            await _afiliaciones.registrar(
              identificacionAsociado: _identificacion.text.trim(),
              placaVehiculo: _placa!,
              fechaAfiliacion: _fechaIngreso!,
            );
          } on ApiException catch (e) {
            if (mounted) {
              mostrarError(
                context,
                'Asociado creado, pero no se pudo afiliar el vehículo: ${e.message}',
              );
            }
          }
        }
      }
      if (!mounted) return;
      Navigator.pop(context, resultado);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorServidor = e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final hoy = Fechas.hoy;
    final mayorDeEdad = DateTime(hoy.year - 18, hoy.month, hoy.day);

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: _esEdicion ? 'Editar asociado' : 'Registrar asociado',
        subtitulo: _esEdicion
            ? widget.asociado!.nombres
            : 'Afiliación de un nuevo socio',
      ),
      body: Form(
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
                titulo: 'Datos personales',
                icono: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              CampoTexto(
                etiqueta: 'Identificación',
                controlador: _identificacion,
                icono: Icons.badge_outlined,
                hint: 'Número de cédula',
                teclado: TextInputType.number,
                formateadores: [Formateadores.soloDigitos],
                longitudMaxima: 15,
                habilitado: !_esEdicion,
                obligatorio: !_esEdicion,
                validador: _esEdicion ? null : Validar.identificacion,
              ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Nombres y apellidos',
                controlador: _nombres,
                icono: Icons.person_outline,
                hint: 'Ej. Jorge Luis Terán Mendoza',
                mayusculas: TextCapitalization.words,
                habilitado: !_esEdicion,
                obligatorio: !_esEdicion,
                validador: _esEdicion ? null : Validar.nombre,
              ),
              const SizedBox(height: 16),
              CampoFecha(
                etiqueta: 'Fecha de nacimiento',
                valor: _fechaNacimiento,
                ultima: mayorDeEdad,
                obligatorio: true,
                icono: Icons.cake_outlined,
                validador: (v) => Validar.fecha(v, 'la fecha de nacimiento'),
                alCambiar: (fecha) => _fechaNacimiento = fecha,
              ),
              const SizedBox(height: 24),
              const TituloSeccionFormulario(
                titulo: 'Contacto',
                icono: Icons.contact_phone_outlined,
              ),
              const SizedBox(height: 12),
              CampoTexto(
                etiqueta: 'Celular',
                controlador: _celular,
                icono: Icons.phone_outlined,
                hint: '3001234567',
                teclado: TextInputType.phone,
                formateadores: [Formateadores.soloDigitos],
                longitudMaxima: 10,
                obligatorio: true,
                validador: Validar.celular,
              ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Correo electrónico',
                controlador: _correo,
                icono: Icons.mail_outline,
                hint: 'socio@correo.com',
                teclado: TextInputType.emailAddress,
                obligatorio: true,
                accion: TextInputAction.done,
                validador: Validar.correo,
              ),
              if (!_esEdicion) ..._seccionVinculacion(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarraAcciones(
        textoPrincipal: _esEdicion ? 'Guardar cambios' : 'Registrar',
        alPrincipal: _guardar,
        cargando: _guardando,
      ),
    );
  }

  List<Widget> _seccionVinculacion() {
    final vehiculos = _listaVehiculos;
    return [
      const SizedBox(height: 24),
      const TituloSeccionFormulario(
        titulo: 'Vinculación',
        icono: Icons.apartment_outlined,
      ),
      const SizedBox(height: 12),
      CampoFecha(
        etiqueta: 'Fecha de ingreso',
        valor: _fechaIngreso,
        ultima: Fechas.hoy,
        obligatorio: true,
        validador: (v) => Validar.fecha(v, 'la fecha de ingreso'),
        alCambiar: (fecha) => _fechaIngreso = fecha,
      ),
      const SizedBox(height: 16),
      if (vehiculos == null)
        const LinearProgressIndicator(minHeight: 2)
      else
        CampoSelector<String?>(
          etiqueta: 'Placa del vehículo (opcional)',
          valor: _placa,
          icono: Icons.directions_car_outlined,
          hint: vehiculos.isEmpty
              ? 'No hay vehículos disponibles'
              : 'Seleccionar vehículo a afiliar',
          opciones: [
            const OpcionSelector<String?>(valor: null, texto: 'Sin vehículo por ahora'),
            for (final vehiculo in vehiculos)
              OpcionSelector<String?>(
                valor: vehiculo.placa,
                texto: vehiculo.placa,
                detalle: '${vehiculo.tipo ?? 'Vehículo'} · ${vehiculo.descripcion}',
              ),
          ],
          alCambiar: (valor) => setState(() => _placa = valor),
        ),
      const SizedBox(height: 16),
      InterruptorCampo(
        titulo: 'Asociado activo',
        descripcion: 'Habilitado para operar dentro de la cooperativa',
        valor: _activo,
        alCambiar: (valor) => setState(() => _activo = valor),
      ),
      const SizedBox(height: 16),
      const Aviso(
        titulo: 'Afiliación del vehículo',
        mensaje:
            'Si seleccionas una placa, se registrará automáticamente la afiliación con la fecha de ingreso.',
        tono: TonoEstado.info,
      ),
    ];
  }
}
