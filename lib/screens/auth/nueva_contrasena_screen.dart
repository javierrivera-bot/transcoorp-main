import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/auth.dart';
import 'package:transcoorp/models/login/cambiar_password_request.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/services/local/gestor_sesion.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/login_service.dart';
import 'package:transcoorp/services/remote/recuperacion_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/boton_principal.dart';
import 'package:transcoorp/widgets/decoracion_campo.dart';
import 'package:transcoorp/widgets/encabezado_seguridad.dart';
import 'package:transcoorp/widgets/mensaje_error.dart';

class NuevaContrasenaScreen extends StatefulWidget {
  const NuevaContrasenaScreen({
    super.key,
    this.token,
    this.correo,
    this.recordar = false,
    this.voluntario = false,
  });

  final String? token;

  final String? correo;

  final bool recordar;

  final bool voluntario;

  @override
  State<NuevaContrasenaScreen> createState() => _NuevaContrasenaScreenState();
}

class _NuevaContrasenaScreenState extends State<NuevaContrasenaScreen> {
  ColoresApp get _c => context.colores;

  Future<void> guardarContrasena() async {
    final errorNueva = Auth.validarNuevaContrasena(nuevaController.text);
    final errorConfirmacion = Auth.validarConfirmacion(
      nuevaController.text,
      confirmarController.text,
    );

    setState(() {
      _errorNueva = errorNueva;
      _errorConfirmacion = errorConfirmacion;
      _errorServidor = null;
    });
    if (errorNueva != null || errorConfirmacion != null) return;

    final token = widget.token;
    final correo = widget.correo;

    if (token == null && correo == null) {
      setState(() {
        _errorServidor =
            'No hay un cambio de contraseña en curso. Vuelve a iniciar sesión.';
      });
      return;
    }

    setState(() => _cargando = true);

    try {
      if (token != null) {
        final respuesta = await _loginService.cambiarPassword(
          token,
          CambiarPasswordRequest(
            nuevaPassword: nuevaController.text,
            confirmacionPassword: confirmarController.text,
          ),
        );
        if (widget.voluntario && respuesta != null) {
          await GestorSesion.reemplazarToken(respuesta);
        }
        if (!mounted) return;
        if (widget.voluntario) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña actualizada correctamente.')),
          );
          Navigator.pop(context);
          return;
        }
        if (respuesta == null) {
          await GestorSesion.cerrar();
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (ruta) => false,
            arguments: 'Contraseña actualizada. Inicia sesión con tu nueva contraseña.',
          );
          return;
        }
        await GestorSesion.iniciar(respuesta, recordar: widget.recordar);
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.inicio,
          (ruta) => false,
        );
      } else {
        await _recuperacion.restablecerContrasena(
          correo!,
          nuevaController.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              RecuperacionService.simulado
                  ? 'Demostración: el cambio no se guardó en el servidor.'
                  : 'Contraseña actualizada. Inicia sesión.',
            ),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (ruta) => false,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorServidor = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void alternarNueva() {
    setState(() {
      _ocultarNueva = !_ocultarNueva;
    });
  }

  void alternarConfirmacion() {
    setState(() {
      _ocultarConfirmacion = !_ocultarConfirmacion;
    });
  }

  bool _ocultarNueva = true;
  bool _ocultarConfirmacion = true;
  bool _cargando = false;
  String? _errorNueva;
  String? _errorConfirmacion;
  String? _errorServidor;

  final LoginService _loginService = LoginService();
  final RecuperacionService _recuperacion = RecuperacionService();

  final TextEditingController nuevaController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();

  @override
  void dispose() {
    nuevaController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c.fondo,
      appBar: const EncabezadoSeguridad(titulo: 'Nueva contraseña'),
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
                    'Crea una contraseña de al menos 12 caracteres.',
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
          _etiqueta('NUEVA CONTRASEÑA'),
          const SizedBox(height: 6),
          _campoContrasena(
            controller: nuevaController,
            ocultar: _ocultarNueva,
            alAlternar: alternarNueva,
            error: _errorNueva,
          ),
          const SizedBox(height: 12),
          _panelSeguridad(),
          const SizedBox(height: 16),
          _etiqueta('CONFIRMA LA CONTRASEÑA'),
          const SizedBox(height: 6),
          _campoContrasena(
            controller: confirmarController,
            ocultar: _ocultarConfirmacion,
            alAlternar: alternarConfirmacion,
            error: _errorConfirmacion,
          ),
          const SizedBox(height: 20),
          if (_errorServidor != null) ...[
            MensajeError(_errorServidor!),
            const SizedBox(height: 12),
          ],
          BotonPrincipal(
            texto: 'Guardar contraseña',
            alPresionar: guardarContrasena,
            cargando: _cargando,
          ),
        ],
      ),
    );
  }

  Widget _etiqueta(String texto) {
    return Text(
      texto,
      style: AppTheme.inter(
        size: 12,
        weight: FontWeight.w700,
        color: _c.textoEtiqueta,
      ).copyWith(letterSpacing: 0.6),
    );
  }

  Widget _campoContrasena({
    required TextEditingController controller,
    required bool ocultar,
    required VoidCallback alAlternar,
    String? error,
  }) {
    return TextField(
      controller: controller,
      obscureText: ocultar,
      enabled: !_cargando,
      onChanged: (_) => setState(() {}),
      style: AppTheme.inter(size: 14, color: _c.textoTitulo),
      decoration: decoracionCampo(
        context,
        hint: '••••••••••••',
        icono: Icons.lock_outline,
        error: error,
        sufijo: IconButton(
          onPressed: alAlternar,
          icon: Icon(
            ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: _c.textoSecundario,
          ),
        ),
      ),
    );
  }

  Widget _panelSeguridad() {
    final contrasena = nuevaController.text;
    final nivel = Auth.nivelSeguridad(contrasena);
    final colorBarra = nivel == 3 ? _c.verdeOscuro : _c.primario;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _c.badgeFondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nivel de seguridad',
                style: AppTheme.inter(
                  size: 11,
                  weight: FontWeight.w500,
                  color: _c.textoSutil,
                ),
              ),
              Text(
                Auth.etiquetaSeguridad(nivel),
                style: AppTheme.inter(
                  size: 11,
                  weight: FontWeight.w600,
                  color: _c.textoSutil,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < nivel ? colorBarra : _c.borde,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          _requisito('Mínimo 12 caracteres', Auth.cumpleMinimo(contrasena)),
          const SizedBox(height: 6),
          _requisito(
            'Mayúscula y minúscula',
            Auth.cumpleMayusMinus(contrasena),
          ),
          const SizedBox(height: 6),
          _requisito('Al menos un número', Auth.cumpleNumero(contrasena)),
        ],
      ),
    );
  }

  Widget _requisito(String texto, bool cumple) {
    return Row(
      children: [
        Icon(
          cumple ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: cumple ? _c.verdeOscuro : _c.textoSutil,
        ),
        const SizedBox(width: 8),
        Text(texto, style: AppTheme.inter(size: 12, color: _c.textoGris)),
      ],
    );
  }
}