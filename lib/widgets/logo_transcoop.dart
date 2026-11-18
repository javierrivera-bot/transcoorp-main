import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/theme/colores_app.dart';

class LogoTranscoop extends StatelessWidget {
  const LogoTranscoop({super.key, this.ancho = 200, this.alto = 128});

  final double ancho;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: alto,
      child: Image.asset(
        'assets/images/transcoop_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            'TRANSCOOP',
            style: AppTheme.montserrat(
              size: 28,
              weight: FontWeight.w800,
              color: context.colores.primario,
            ),
          ),
        ),
      ),
    );
  }
}