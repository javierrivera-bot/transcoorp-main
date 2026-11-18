import 'package:flutter/material.dart';

@immutable
class ColoresApp extends ThemeExtension<ColoresApp> {
  const ColoresApp({
    required this.fondo,
    required this.superficie,
    required this.primario,
    required this.primarioOscuro,
    required this.textoTitulo,
    required this.textoSecundario,
    required this.textoEtiqueta,
    required this.textoOscuro,
    required this.textoGris,
    required this.textoSutil,
    required this.hint,
    required this.borde,
    required this.bordeTarjeta,
    required this.badgeFondo,
    required this.verde,
    required this.verdeOscuro,
    required this.unidadFondo,
    required this.chipRutaFondo,
    required this.chipRutaTexto,
    required this.chipCompletoFondo,
    required this.chipCompletoTexto,
  });

  final Color fondo;
  final Color superficie;
  final Color primario;
  final Color primarioOscuro;
  final Color textoTitulo;
  final Color textoSecundario;
  final Color textoEtiqueta;
  final Color textoOscuro;
  final Color textoGris;
  final Color textoSutil;
  final Color hint;
  final Color borde;
  final Color bordeTarjeta;
  final Color badgeFondo;
  final Color verde;
  final Color verdeOscuro;
  final Color unidadFondo;
  final Color chipRutaFondo;
  final Color chipRutaTexto;
  final Color chipCompletoFondo;
  final Color chipCompletoTexto;

  static const ColoresApp claro = ColoresApp(
    fondo: Color(0xFFF8F9FF),
    superficie: Color(0xFFFFFFFF),
    primario: Color(0xFF1E3A8A),
    primarioOscuro: Color(0xFF00236F),
    textoTitulo: Color(0xFF111827),
    textoSecundario: Color(0xFF6B7280),
    textoEtiqueta: Color(0xFF374151),
    textoOscuro: Color(0xFF121C2A),
    textoGris: Color(0xFF444651),
    textoSutil: Color(0xFF757682),
    hint: Color(0xFF9CA3AF),
    borde: Color(0xFFD1D5DB),
    bordeTarjeta: Color(0xFFF3F4F6),
    badgeFondo: Color(0xFFEFF4FF),
    verde: Color(0xFF10B981),
    verdeOscuro: Color(0xFF006C49),
    unidadFondo: Color(0xFF00236F),
    chipRutaFondo: Color(0xFF6CF8BB),
    chipRutaTexto: Color(0xFF00714D),
    chipCompletoFondo: Color(0xFFD9E3F6),
    chipCompletoTexto: Color(0xFF121C2A),
  );

  static const ColoresApp oscuro = ColoresApp(
    fondo: Color(0xFF0B1220),
    superficie: Color(0xFF151E2E),
    primario: Color(0xFF8FA8FF),
    primarioOscuro: Color(0xFF8FA8FF),
    textoTitulo: Color(0xFFF3F4F6),
    textoSecundario: Color(0xFF9CA3AF),
    textoEtiqueta: Color(0xFFD1D5DB),
    textoOscuro: Color(0xFFF3F4F6),
    textoGris: Color(0xFFCBD5E1),
    textoSutil: Color(0xFF94A3B8),
    hint: Color(0xFF6B7280),
    borde: Color(0xFF334155),
    bordeTarjeta: Color(0xFF1F2937),
    badgeFondo: Color(0xFF1E2A4A),
    verde: Color(0xFF34D399),
    verdeOscuro: Color(0xFF34D399),
    unidadFondo: Color(0xFF2B3F8A),
    chipRutaFondo: Color(0xFF0F3D2E),
    chipRutaTexto: Color(0xFF6CF8BB),
    chipCompletoFondo: Color(0xFF263149),
    chipCompletoTexto: Color(0xFFE2E8F0),
  );

  @override
  ColoresApp copyWith({
    Color? fondo, Color? superficie, Color? primario, Color? primarioOscuro,
    Color? textoTitulo, Color? textoSecundario, Color? textoEtiqueta,
    Color? textoOscuro, Color? textoGris, Color? textoSutil, Color? hint,
    Color? borde, Color? bordeTarjeta, Color? badgeFondo, Color? verde,
    Color? verdeOscuro, Color? unidadFondo, Color? chipRutaFondo,
    Color? chipRutaTexto, Color? chipCompletoFondo, Color? chipCompletoTexto,
  }) => ColoresApp(
    fondo: fondo ?? this.fondo,
    superficie: superficie ?? this.superficie,
    primario: primario ?? this.primario,
    primarioOscuro: primarioOscuro ?? this.primarioOscuro,
    textoTitulo: textoTitulo ?? this.textoTitulo,
    textoSecundario: textoSecundario ?? this.textoSecundario,
    textoEtiqueta: textoEtiqueta ?? this.textoEtiqueta,
    textoOscuro: textoOscuro ?? this.textoOscuro,
    textoGris: textoGris ?? this.textoGris,
    textoSutil: textoSutil ?? this.textoSutil,
    hint: hint ?? this.hint,
    borde: borde ?? this.borde,
    bordeTarjeta: bordeTarjeta ?? this.bordeTarjeta,
    badgeFondo: badgeFondo ?? this.badgeFondo,
    verde: verde ?? this.verde,
    verdeOscuro: verdeOscuro ?? this.verdeOscuro,
    unidadFondo: unidadFondo ?? this.unidadFondo,
    chipRutaFondo: chipRutaFondo ?? this.chipRutaFondo,
    chipRutaTexto: chipRutaTexto ?? this.chipRutaTexto,
    chipCompletoFondo: chipCompletoFondo ?? this.chipCompletoFondo,
    chipCompletoTexto: chipCompletoTexto ?? this.chipCompletoTexto,
  );

  @override
  ColoresApp lerp(ThemeExtension<ColoresApp>? other, double t) {
    if (other is! ColoresApp) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return ColoresApp(
      fondo: m(fondo, other.fondo),
      superficie: m(superficie, other.superficie),
      primario: m(primario, other.primario),
      primarioOscuro: m(primarioOscuro, other.primarioOscuro),
      textoTitulo: m(textoTitulo, other.textoTitulo),
      textoSecundario: m(textoSecundario, other.textoSecundario),
      textoEtiqueta: m(textoEtiqueta, other.textoEtiqueta),
      textoOscuro: m(textoOscuro, other.textoOscuro),
      textoGris: m(textoGris, other.textoGris),
      textoSutil: m(textoSutil, other.textoSutil),
      hint: m(hint, other.hint),
      borde: m(borde, other.borde),
      bordeTarjeta: m(bordeTarjeta, other.bordeTarjeta),
      badgeFondo: m(badgeFondo, other.badgeFondo),
      verde: m(verde, other.verde),
      verdeOscuro: m(verdeOscuro, other.verdeOscuro),
      unidadFondo: m(unidadFondo, other.unidadFondo),
      chipRutaFondo: m(chipRutaFondo, other.chipRutaFondo),
      chipRutaTexto: m(chipRutaTexto, other.chipRutaTexto),
      chipCompletoFondo: m(chipCompletoFondo, other.chipCompletoFondo),
      chipCompletoTexto: m(chipCompletoTexto, other.chipCompletoTexto),
    );
  }
}

extension ColoresContexto on BuildContext {
  ColoresApp get colores {
    final tema = Theme.of(this);
    return tema.extension<ColoresApp>() ??
        (tema.brightness == Brightness.dark
            ? ColoresApp.oscuro
            : ColoresApp.claro);
  }
}