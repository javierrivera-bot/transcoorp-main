import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:transcoorp/theme/colores_app.dart';

class AppColors {
  static const Color fondo = Color(0xFFF8F9FF);
  static const Color primario = Color(0xFF1E3A8A);
  static const Color primarioOscuro = Color(0xFF00236F);
  static const Color textoTitulo = Color(0xFF111827);
  static const Color textoSecundario = Color(0xFF6B7280);
  static const Color textoEtiqueta = Color(0xFF374151);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color borde = Color(0xFFD1D5DB);
  static const Color bordeTarjeta = Color(0xFFF3F4F6);
  static const Color badgeFondo = Color(0xFFEFF4FF);
  static const Color verde = Color(0xFF10B981);
  static const Color textoOscuro = Color(0xFF121C2A);
  static const Color textoGris = Color(0xFF444651);
  static const Color textoSutil = Color(0xFF757682);
  static const Color azulClaro = Color(0xFFE6EEFF);
  static const Color azulBoton = Color(0xFFD9E3F6);
  static const Color azulMedio = Color(0xFF4059AA);
  static const Color verdeOscuro = Color(0xFF006C49);
  static const Color menta = Color(0xFF6CF8BB);
  static const Color verdeBadge = Color(0xFF00714D);
  static const Color azulSuave = Color(0xFFDCE1FF);
  static const Color azulBadge = Color(0xFF264191);
  static const Color azulChip = Color(0xFFDEE9FC);
  static const Color naranjaClaro = Color(0xFFFFDDB8);
  static const Color naranjaOscuro = Color(0xFF3E2400);
  static const Color rojoAlerta = Color(0xFFBA1A1A);
  static const Color azulBannerTexto = Color(0xFF90A8FF);
}

class AppTheme {
  static TextStyle montserrat({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textoTitulo,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle inter({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textoTitulo,
  }) {
    return GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);
  }

  static ThemeData get light {
    const c = ColoresApp.claro;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: c.fondo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primario,
      ).copyWith(primary: AppColors.primario, surface: c.superficie),
      extensions: const [c],
    );
  }

  static ThemeData get dark {
    const c = ColoresApp.oscuro;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.primario,
            brightness: Brightness.dark,
          ).copyWith(
            primary: c.primario,
            surface: c.superficie,
            onSurface: c.textoTitulo,
            outline: c.borde,
          ),
      scaffoldBackgroundColor: c.fondo,
      dividerColor: c.borde,
      extensions: const [c],
    );
  }

  static const List<BoxShadow> sombraSuave = [
    BoxShadow(color: Color(0x0A0F172A), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0F1E3A8A), offset: Offset(0, 6), blurRadius: 16),
  ];
}
