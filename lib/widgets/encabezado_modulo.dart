import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/theme/colores_app.dart';

class EncabezadoModulo extends StatelessWidget implements PreferredSizeWidget {
  const EncabezadoModulo({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acciones = const [],
    this.alVolver,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> acciones;
  final VoidCallback? alVolver;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final puedeVolver = alVolver != null || Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: c.fondo,
      foregroundColor: c.primarioOscuro,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      automaticallyImplyLeading: alVolver == null,
      leading: alVolver == null
          ? null
          : IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: alVolver,
            ),
      titleSpacing: puedeVolver ? 0 : 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.montserrat(
              size: 19,
              weight: FontWeight.w700,
              color: c.primarioOscuro,
            ),
          ),
          if (subtitulo != null)
            Text(
              subtitulo!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.inter(size: 12, color: c.textoSutil),
            ),
        ],
      ),
      actions: [...acciones, const SizedBox(width: 8)],
    );
  }
}

class AccionEncabezado extends StatelessWidget {
  const AccionEncabezado({
    super.key,
    required this.icono,
    required this.tooltip,
    required this.alPresionar,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        tooltip: tooltip,
        onPressed: alPresionar,
        style: IconButton.styleFrom(
          backgroundColor: c.badgeFondo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icono, color: c.primario, size: 22),
      ),
    );
  }
}
