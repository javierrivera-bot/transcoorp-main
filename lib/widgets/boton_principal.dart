import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';

class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.alPresionar,
    this.cargando = false,
  });

  final String texto;
  final VoidCallback alPresionar;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: cargando ? null : alPresionar,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primario,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primario.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                texto,
                style: AppTheme.montserrat(
                  size: 16,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}