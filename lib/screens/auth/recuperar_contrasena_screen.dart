import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/auth.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/recuperacion_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/boton_principal.dart';
import 'package:transcoorp/widgets/decoracion_campo.dart';
import 'package:transcoorp/widgets/encabezado_seguridad.dart';
import 'package:transcoorp/widgets/mensaje_error.dart';

class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  ColoresApp get _c => context.colores;

  Future<void> enviarCodigo() async {
    final error = Auth.validarCorreo(correoController.text);

    setState(() {
      _errorCorreo = error;
      _errorServidor = null;
    });
    if (error != null) return;

    setState(() => _cargando = true);

    try {
      final correo = correoController.text.trim();
      await _servicio.enviarCodigo(correo);
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.verificarOtp, arguments: correo);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorServidor = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  bool _cargando = false;
  String? _errorCorreo;
  String? _errorServidor;

  final RecuperacionService _servicio = RecuperacionService();

  final TextEditingController correoController = TextEditingController();

  @override
  void dispose() {
    correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c.fondo,
      appBar: const EncabezadoSeguridad(titulo: 'Recuperar contraseña'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 402),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ingresa el correo registrado en tu cuenta. Te enviaremos '
                    'un código de 6 dígitos para restablecer tu contraseña.',
                    style: AppTheme.inter(size: 14, color: _c.textoSecundario),
                  ),
                  const SizedBox(height: 24),
                  _tarjeta(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjeta() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _c.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _c.bordeTarjeta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CORREO INSTITUCIONAL',
            style: AppTheme.inter(
              size: 12,
              weight: FontWeight.w700,
              color: _c.textoEtiqueta,
            ).copyWith(letterSpacing: 0.6),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: correoController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !_cargando,
            onSubmitted: (_) => enviarCodigo(),
            style: AppTheme.inter(size: 14, color: _c.textoTitulo),
            decoration: decoracionCampo(
              context,
              hint: 'nombre@transcoop.com',
              icono: Icons.mail_outline,
              error: _errorCorreo,
            ),
          ),
          const SizedBox(height: 16),
          if (_errorServidor != null) ...[
            MensajeError(_errorServidor!),
            const SizedBox(height: 12),
          ],
          BotonPrincipal(
            texto: 'Enviar código',
            alPresionar: enviarCodigo,
            cargando: _cargando,
          ),
        ],
      ),
    );
  }
}