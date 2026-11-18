import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/planilla/planilla.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/planilla_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/boton_principal.dart';
import 'package:transcoorp/widgets/campos_formulario.dart';
import 'package:transcoorp/widgets/mensaje_error.dart';

Future<Pago?> mostrarRegistroPago(BuildContext context, {int? numeroPlanilla}) {
  return showModalBottomSheet<Pago>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colores.superficie,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _HojaPago(numeroPlanilla: numeroPlanilla),
  );
}

class _HojaPago extends StatefulWidget {
  const _HojaPago({this.numeroPlanilla});

  final int? numeroPlanilla;

  @override
  State<_HojaPago> createState() => _HojaPagoState();
}

class _HojaPagoState extends State<_HojaPago> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  late final TextEditingController _numero = TextEditingController(
    text: widget.numeroPlanilla?.toString() ?? '',
  );
  DateTime? _fecha = Fechas.hoy;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _numero.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final pago = await PlanillaService().registrarPago(
        numeroPlanilla: int.parse(_numero.text.trim()),
        fechaPago: _fecha!,
      );
      if (mounted) Navigator.pop(context, pago);
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
              'Registrar pago de planilla',
              style: AppTheme.montserrat(
                size: 18,
                weight: FontWeight.w700,
                color: c.textoOscuro,
              ),
            ),
            Text(
              'El valor se liquida según la tarifa asignada a la planilla.',
              style: AppTheme.inter(size: 13, color: c.textoSutil),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              MensajeError(_error!),
              const SizedBox(height: 12),
            ],
            CampoTexto(
              etiqueta: 'Número de la planilla',
              controlador: _numero,
              icono: Icons.tag,
              hint: 'Ej. 1024',
              teclado: TextInputType.number,
              formateadores: [Formateadores.soloDigitos],
              habilitado: widget.numeroPlanilla == null,
              obligatorio: true,
              validador: (v) => Validar.requerido(v, 'el número de planilla'),
            ),
            const SizedBox(height: 16),
            CampoFecha(
              etiqueta: 'Fecha de pago',
              valor: _fecha,
              ultima: Fechas.hoy,
              obligatorio: true,
              validador: (v) => Validar.fecha(v, 'la fecha de pago'),
              alCambiar: (fecha) => _fecha = fecha,
            ),
            const SizedBox(height: 20),
            BotonPrincipal(
              texto: 'Registrar pago',
              alPresionar: _guardar,
              cargando: _guardando,
            ),
          ],
        ),
      ),
    );
  }
}
