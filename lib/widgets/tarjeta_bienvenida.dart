import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';

class MetricaBienvenida {
  const MetricaBienvenida({
    required this.icono,
    required this.valor,
    required this.titulo,
    this.alTocar,
  });

  final IconData icono;
  final String valor;
  final String titulo;
  final VoidCallback? alTocar;
}

class TarjetaBienvenida extends StatelessWidget {
  const TarjetaBienvenida({
    super.key,
    required this.fecha,
    required this.saludo,
    required this.rol,
    required this.metricas,
  });

  final String fecha;
  final String saludo;
  final String rol;
  final List<MetricaBienvenida> metricas;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarioOscuro, AppColors.primario],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331E3A8A),
            offset: Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(top: -50, right: -40, child: _circulo(170)),
          Positioned(bottom: -60, right: 60, child: _circulo(120)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fecha,
                  style: AppTheme.inter(
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  saludo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.montserrat(
                    size: 22,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: AppColors.menta,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        rol,
                        style: AppTheme.inter(
                          size: 11.5,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    for (var i = 0; i < metricas.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: _Metrica(metrica: metricas[i])),
                    ],
                  ],
                ),
              ],
            ),
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
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.metrica});

  final MetricaBienvenida metrica;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(16);
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: radio,
      child: InkWell(
        onTap: metrica.alTocar,
        borderRadius: radio,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(metrica.icono, size: 20, color: AppColors.menta),
              const SizedBox(height: 10),
              Text(
                metrica.valor,
                style: AppTheme.montserrat(
                  size: 22,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                metrica.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.inter(
                  size: 11.5,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
