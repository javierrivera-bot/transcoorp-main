import 'package:flutter/material.dart';
import 'package:transcoorp/models/login/nueva_contrasena_args.dart';
import 'package:transcoorp/screens/auth/login_screen.dart';
import 'package:transcoorp/screens/auth/nueva_contrasena_screen.dart';
import 'package:transcoorp/screens/auth/recuperar_contrasena_screen.dart';
import 'package:transcoorp/screens/auth/verificar_otp_screen.dart';
import 'package:transcoorp/screens/inicio/inicio_screen.dart';
import 'package:transcoorp/screens/inicio/splash_screen.dart';

abstract final class AppRoutes {
  static final GlobalKey<NavigatorState> navegador = GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String login = '/login';
  static const String recuperar = '/recuperar';
  static const String verificarOtp = '/verificar-otp';
  static const String nuevaContrasena = '/nueva-contrasena';
  static const String inicio = '/inicio';

  static Route<dynamic> generar(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _ruta(const SplashScreen(), settings);
      case login:
        final mensaje = settings.arguments as String?;
        return _ruta(LoginScreen(mensaje: mensaje), settings);
      case recuperar:
        return _ruta(const RecuperarContrasenaScreen(), settings);
      case verificarOtp:
        final correo = settings.arguments as String? ?? '';
        return _ruta(VerificarOtpScreen(correo: correo), settings);
      case nuevaContrasena:
        final args = settings.arguments as NuevaContrasenaArgs?;
        return _ruta(
          NuevaContrasenaScreen(
            token: args?.token,
            correo: args?.correo,
            recordar: args?.recordar ?? false,
            voluntario: args?.voluntario ?? false,
          ),
          settings,
        );
      case inicio:
        return _ruta(const InicioScreen(), settings);
      default:
        return _ruta(const SplashScreen(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _ruta(
    Widget pantalla,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(builder: (_) => pantalla, settings: settings);
  }
}

Future<T?> abrir<T>(BuildContext context, Widget pantalla) {
  return Navigator.of(
    context,
  ).push<T>(MaterialPageRoute<T>(builder: (_) => pantalla));
}
