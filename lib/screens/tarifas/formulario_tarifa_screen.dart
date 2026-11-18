import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/tarifa_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/campos_formulario.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/mensaje_error.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';

class FormularioTarifaScreen extends StatefulWidget {
  const FormularioTarifaScreen({super.key});

  @override
  State<FormularioTarifaScreen> createState() => _FormularioTarifaScreenState();
}

class _FormularioTarifaScreenState extends State<FormularioTarifaScreen> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  final TextEditingController _gastos = TextEditingController();
  final TextEditingController _fondo = TextEditingController();
  final TextEditingController _aporte = TextEditingController();

  bool _activo = true;
  bool _guardando = false;
  String? _errorServidor;

  double get _total =>
      Formateadores.valorMiles(_gastos.text) +
      Formateadores.valorMiles(_fondo.text) +
      Formateadores.valorMiles(_aporte.text);

  @override
  void dispose() {
    _gastos.dispose();
    _fondo.dispose();
    _aporte.dispose();
    super.dispose();
  }

  String? _validarValor(String valor) {
    if (valor.trim().isEmpty) return 'Ingresa el valor.';
    return null;
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;
    if (_total <= 0) {
      setState(() => _errorServidor = 'El total de la tarifa debe ser mayor a cero.');
      return;
    }

    setState(() => _guardando = true);
    try {
      final tarifa = await TarifaService().registrar(
        aportesGastosVarios: Formateadores.valorMiles(_gastos.text),
        fondoReposicion: Formateadores.valorMiles(_fondo.text),
        aporteSocialSocio: Formateadores.valorMiles(_aporte.text),
        activo: _activo,
      );
      if (mounted) Navigator.pop(context, tarifa);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorServidor = e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _campo(String etiqueta, TextEditingController controlador, IconData icono) {
    return CampoTexto(
      etiqueta: etiqueta,
      controlador: controlador,
      icono: icono,
      hint: '0',
      teclado: TextInputType.number,
      formateadores: [Formateadores.miles],
      obligatorio: true,
      validador: _validarValor,
      alCambiar: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: const EncabezadoModulo(
        titulo: 'Registrar tarifa',
        subtitulo: 'Componentes monetarios por planilla',
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
              _campo('Aportes gastos varios', _gastos, Icons.receipt_outlined),
              const SizedBox(height: 16),
              _campo('Fondo de reposición', _fondo, Icons.savings_outlined),
              const SizedBox(height: 16),
              _campo(
                'Aporte social del socio',
                _aporte,
                Icons.volunteer_activism_outlined,
              ),
              const SizedBox(height: 16),
              InterruptorCampo(
                titulo: 'Tarifa activa',
                descripcion: 'Disponible para generar planillas',
                valor: _activo,
                alCambiar: (valor) => setState(() => _activo = valor),
              ),
              const SizedBox(height: 20),
              TarjetaBase(
                colorFondo: c.badgeFondo,
                child: Row(
                  children: [
                    Icon(Icons.functions, color: c.primario),
                    const SizedBox(width: 10),
                    Text(
                      'Total calculado',
                      style: AppTheme.inter(
                        size: 14,
                        weight: FontWeight.w600,
                        color: c.textoGris,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Formato.moneda(_total),
                      style: AppTheme.montserrat(
                        size: 22,
                        weight: FontWeight.w800,
                        color: c.primarioOscuro,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarraAcciones(
        textoPrincipal: 'Registrar tarifa',
        alPrincipal: _guardar,
        cargando: _guardando,
      ),
    );
  }
}
