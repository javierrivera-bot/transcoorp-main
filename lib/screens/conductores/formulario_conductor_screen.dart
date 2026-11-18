import 'package:flutter/material.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/conductor/conductor.dart';
import 'package:transcoorp/services/local/cambios_datos.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/conductor_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/campos_formulario.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/mensaje_error.dart';

class FormularioConductorScreen extends StatefulWidget {
  const FormularioConductorScreen({super.key, this.conductor});

  final Conductor? conductor;

  @override
  State<FormularioConductorScreen> createState() =>
      _FormularioConductorScreenState();
}

class _FormularioConductorScreenState extends State<FormularioConductorScreen> {
  static const _categorias = ['B1', 'B2', 'B3', 'C1', 'C2', 'C3'];

  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final ConductorService _servicio = ConductorService();

  late final TextEditingController _identificacion = TextEditingController(
    text: widget.conductor?.identificacion,
  );
  late final TextEditingController _nombres = TextEditingController(
    text: widget.conductor?.nombres,
  );
  late final TextEditingController _licencia = TextEditingController(
    text: widget.conductor?.numeroLicencia,
  );
  late final TextEditingController _celular = TextEditingController(
    text: widget.conductor?.celular,
  );
  late final TextEditingController _correo = TextEditingController(
    text: widget.conductor?.correo,
  );

  late DateTime? _fechaNacimiento = widget.conductor?.fechaNacimiento;
  late DateTime? _vigencia = widget.conductor?.vigenciaLicencia;
  late String? _categoria = _categorias.contains(widget.conductor?.categoriaLicencia)
      ? widget.conductor?.categoriaLicencia
      : null;
  late bool _activo = widget.conductor?.activo ?? true;

  bool _guardando = false;
  String? _errorServidor;

  bool get _esEdicion => widget.conductor != null;

  @override
  void dispose() {
    _identificacion.dispose();
    _nombres.dispose();
    _licencia.dispose();
    _celular.dispose();
    _correo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;

    final datos = DatosConductor(
      identificacion: _identificacion.text.trim(),
      nombres: _nombres.text.trim(),
      fechaNacimiento: _fechaNacimiento!,
      activo: _activo,
      numeroLicencia: _licencia.text.trim(),
      categoriaLicencia: _categoria!,
      vigenciaLicencia: _vigencia!,
      celular: _celular.text.trim(),
      correo: _correo.text.trim(),
    );

    setState(() => _guardando = true);
    try {
      final resultado = _esEdicion
          ? await _servicio.editar(datos)
          : await _servicio.registrar(datos);
      CambiosDatos.notificarConductores();
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
    final hoy = Fechas.hoy;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: _esEdicion ? 'Editar conductor' : 'Registrar conductor',
        subtitulo: _esEdicion
            ? widget.conductor!.nombres
            : 'Alta de personal autorizado',
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
                titulo: 'Información personal',
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
                obligatorio: true,
                validador: Validar.identificacion,
              ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Nombres y apellidos',
                controlador: _nombres,
                icono: Icons.person_outline,
                hint: 'Ej. Carlos Eduardo Ramírez',
                mayusculas: TextCapitalization.words,
                obligatorio: true,
                validador: Validar.nombre,
              ),
              const SizedBox(height: 16),
              CampoFecha(
                etiqueta: 'Fecha de nacimiento',
                valor: _fechaNacimiento,
                ultima: DateTime(hoy.year - 18, hoy.month, hoy.day),
                icono: Icons.cake_outlined,
                obligatorio: true,
                validador: (v) => Validar.fecha(v, 'la fecha de nacimiento'),
                alCambiar: (fecha) => _fechaNacimiento = fecha,
              ),
              const SizedBox(height: 16),
              InterruptorCampo(
                titulo: 'Conductor activo',
                descripcion: 'Disponible para ser asignado a vehículos',
                valor: _activo,
                alCambiar: (valor) => setState(() => _activo = valor),
              ),
              const SizedBox(height: 24),
              const TituloSeccionFormulario(
                titulo: 'Licencia de conducción',
                icono: Icons.credit_card,
                descripcion: 'Información verificada ante el RUNT',
              ),
              const SizedBox(height: 12),
              CampoTexto(
                etiqueta: 'Número de licencia',
                controlador: _licencia,
                icono: Icons.numbers,
                hint: 'Número del documento',
                formateadores: [Formateadores.mayusculas],
                obligatorio: true,
                validador: (v) => Validar.requerido(v, 'el número de licencia'),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CampoSelector<String>(
                      etiqueta: 'Categoría',
                      valor: _categoria,
                      icono: Icons.category_outlined,
                      obligatorio: true,
                      validador: (v) => Validar.seleccion(v, 'la categoría'),
                      opciones: [
                        for (final categoria in _categorias)
                          OpcionSelector(valor: categoria, texto: categoria),
                      ],
                      alCambiar: (valor) => setState(() => _categoria = valor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CampoFecha(
                      etiqueta: 'Vigencia',
                      valor: _vigencia,
                      primera: DateTime(hoy.year - 5),
                      obligatorio: true,
                      icono: Icons.event_available_outlined,
                      validador: (v) => Validar.fecha(v, 'la vigencia'),
                      alCambiar: (fecha) => _vigencia = fecha,
                    ),
                  ),
                ],
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
                hint: 'conductor@correo.com',
                teclado: TextInputType.emailAddress,
                obligatorio: true,
                accion: TextInputAction.done,
                validador: Validar.correo,
              ),
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
}
