import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/services/local/gestor_sesion.dart';
import 'package:transcoorp/widgets/logo_transcoop.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final resultados = await Future.wait<Object?>([
      GestorSesion.restaurar(),
      Future<void>.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;
    final haySesion = resultados.first != null;
    Navigator.pushReplacementNamed(
      context,
      haySesion ? AppRoutes.inicio : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primario, AppColors.primarioOscuro],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        offset: Offset(0, 14),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: const LogoTranscoop(ancho: 210, alto: 134),
                ),
                const SizedBox(height: 28),
                Text(
                  'Cooperativa de Transporte Mixto',
                  style: AppTheme.montserrat(
                    size: 17,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistema Integral de Transporte Mixto',
                  style: AppTheme.inter(
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      color: AppColors.menta,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Verificando sesión...',
                  style: AppTheme.inter(
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'SITRAMIX · v1.0.0',
                  style: AppTheme.inter(
                    size: 11,
                    weight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
