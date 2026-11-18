import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/auth.dart';
import 'package:transcoorp/models/login/login_request.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/services/local/gestor_sesion.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/login_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/models/login/nueva_contrasena_args.dart';
import 'package:transcoorp/widgets/dialogos.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.mensaje});

  final String? mensaje;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  ColoresApp get _c => context.colores;

  Future<void> iniciarSesion() async {
    final errorUsuario = Auth.validarUsuario(usuarioController.text);
    final errorContrasena = Auth.validarContrasena(contrasenaController.text);

    setState(() {
      _errorUsuario = errorUsuario;
      _errorContrasena = errorContrasena;
      _errorServidor = null;
    });

    if (errorUsuario != null || errorContrasena != null) return;

    setState(() => _cargando = true);

    try {
      final respuesta = await _loginService.login(
        LoginRequest(
          username: usuarioController.text.trim(),
          password: contrasenaController.text,
        ),
      );
      if (!mounted) return;

      if (respuesta.requiereCambioPassword) {
        Navigator.pushNamed(
          context,
          AppRoutes.nuevaContrasena,
          arguments: NuevaContrasenaArgs(
            token: respuesta.token,
            recordar: _recordarSesion,
          ),
        );
      } else {
        await GestorSesion.iniciar(respuesta, recordar: _recordarSesion);
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.inicio,
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

  void alternarContrasena() {
    setState(() {
      _ocultarContrasena = !_ocultarContrasena;
    });
  }

  void alternarRecordar(bool? valor) {
    setState(() {
      _recordarSesion = valor ?? false;
    });
  }

  void irARecuperar() {
    Navigator.pushNamed(context, AppRoutes.recuperar);
  }

  bool _ocultarContrasena = true;
  bool _recordarSesion = true;
  bool _cargando = false;
  String? _errorUsuario;
  String? _errorContrasena;
  String? _errorServidor;

  final LoginService _loginService = LoginService();

  @override
  void initState() {
    super.initState();
    _errorServidor = widget.mensaje;
  }

  void contactarSecretaria() {
    mostrarInformacion(
      context,
      titulo: 'Secretaría TRANSCOOP',
      icono: Icons.support_agent,
      contenido: Text(
        'Atención de lunes a sábado, 6:00 a.m. a 6:00 p.m.\n\n'
        'Teléfono: (606) 282 4510\n'
        'Celular: 310 555 0142\n'
        'Correo: secretaria@transcoop.com',
        textAlign: TextAlign.center,
        style: AppTheme.inter(size: 14, color: _c.textoSecundario),
      ),
    );
  }

  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();

  @override
  void dispose() {
    usuarioController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _c.fondo,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _fondoMarca(),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      children: [
                        _logo(),
                        const SizedBox(height: 16),
                        _badgePortal(),
                        const SizedBox(height: 24),
                        _formulario(),
                        const SizedBox(height: 25),
                        _pie(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fondoMarca() {
    return Container(
      height: 330,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarioOscuro, AppColors.primario],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: _circulo(200),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            child: _circulo(180),
          ),
        ],
      ),
    );
  }

  Widget _circulo(double tamano) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _logo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: SizedBox(
        width: 190,
        height: 121,
        child: Image.asset(
          'assets/images/transcoop_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              'TRANSCOOP',
              style: AppTheme.montserrat(
                size: 28,
                weight: FontWeight.w800,
                color: AppColors.primario,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badgePortal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.menta,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Portal Cooperativa • Transporte Mixto',
            style: AppTheme.inter(
              size: 12,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      decoration: BoxDecoration(
        color: _c.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _c.bordeTarjeta),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            offset: Offset(0, 12),
            blurRadius: 32,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Iniciar Sesión',
            textAlign: TextAlign.center,
            style: AppTheme.montserrat(
              size: 24,
              weight: FontWeight.w700,
              color: _c.textoTitulo,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ingresa tus credenciales de socio o conductor para acceder al sistema operativo.',
            textAlign: TextAlign.center,
            style: AppTheme.inter(size: 14, color: _c.textoSecundario),
          ),
          const SizedBox(height: 24),
          _etiqueta('USUARIO O CORREO INSTITUCIONAL'),
          const SizedBox(height: 6),
          TextField(
            controller: usuarioController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_cargando,
            style: AppTheme.inter(size: 14, color: _c.textoTitulo),
            decoration: _decoracionCampo(
              hint: 'Ej. socio@transcoop.com o Cédula',
              icono: Icons.person_outline,
              error: _errorUsuario,
            ),
          ),
          const SizedBox(height: 16),
          _etiqueta('CONTRASEÑA'),
          const SizedBox(height: 6),
          TextField(
            controller: contrasenaController,
            obscureText: _ocultarContrasena,
            textInputAction: TextInputAction.done,
            enabled: !_cargando,
            onSubmitted: (_) => iniciarSesion(),
            style: AppTheme.inter(size: 14, color: _c.textoTitulo),
            decoration: _decoracionCampo(
              hint: '••••••••••••',
              icono: Icons.lock_outline,
              error: _errorContrasena,
              sufijo: IconButton(
                onPressed: alternarContrasena,
                icon: Icon(
                  _ocultarContrasena
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: _c.textoSecundario,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => alternarRecordar(!_recordarSesion),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: Checkbox(
                        value: _recordarSesion,
                        onChanged: alternarRecordar,
                        activeColor: AppColors.primario,
                        side: BorderSide(color: _c.borde),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recordar sesión',
                      style: AppTheme.inter(
                        size: 12,
                        weight: FontWeight.w500,
                        color: _c.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: irARecuperar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: AppTheme.inter(
                      size: 12,
                      weight: FontWeight.w600,
                      color: _c.primario,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_errorServidor != null) ...[
            _mensajeError(_errorServidor!),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _cargando ? null : iniciarSesion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primario,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primario.withValues(
                  alpha: 0.7,
                ),
                disabledForegroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0x331E3A8A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _cargando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Iniciar Sesión',
                      style: AppTheme.montserrat(
                        size: 16,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensajeError(String texto) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rojoAlerta.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rojoAlerta.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: AppColors.rojoAlerta,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: AppTheme.inter(
                size: 13,
                weight: FontWeight.w500,
                color: _c.textoTitulo,
              ),
            ),
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

  InputDecoration _decoracionCampo({
    required String hint,
    required IconData icono,
    String? error,
    Widget? sufijo,
  }) {
    OutlineInputBorder borde(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.inter(size: 14, color: _c.hint),
      errorText: error,
      filled: true,
      fillColor: _c.superficie,
      prefixIcon: Icon(icono, size: 20, color: _c.textoSecundario),
      suffixIcon: sufijo,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      enabledBorder: borde(_c.borde),
      disabledBorder: borde(_c.borde),
      focusedBorder: borde(_c.primario),
      errorBorder: borde(Colors.redAccent),
      focusedErrorBorder: borde(Colors.redAccent),
    );
  }

  Widget _pie() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.support_agent, size: 14, color: _c.textoSecundario),
        const SizedBox(width: 4),
        Text(
          '¿Problemas para acceder?',
          style: AppTheme.inter(size: 12, color: _c.textoSecundario),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: contactarSecretaria,
          child: Text(
            'Contactar a Secretaría',
            style: AppTheme.inter(
              size: 12,
              weight: FontWeight.w600,
              color: _c.primarioOscuro,
            ).copyWith(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }
}
