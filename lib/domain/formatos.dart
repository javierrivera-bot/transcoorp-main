abstract final class Formato {
  static String moneda(num valor) {
    final entero = valor.round().abs().toString();
    final grupos = StringBuffer();
    for (var i = 0; i < entero.length; i++) {
      if (i > 0 && (entero.length - i) % 3 == 0) grupos.write('.');
      grupos.write(entero[i]);
    }
    return '${valor < 0 ? '-' : ''}\$ $grupos';
  }

  static String iniciales(String nombre) {
    final palabras = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (palabras.isEmpty) return '?';
    final primera = palabras.first[0];
    final segunda = palabras.length > 1 ? palabras[1][0] : '';
    return (primera + segunda).toUpperCase();
  }

  static String capitalizar(String texto) {
    final limpio = texto.trim().toLowerCase().replaceAll('_', ' ');
    if (limpio.isEmpty) return limpio;
    return limpio[0].toUpperCase() + limpio.substring(1);
  }

  static String valorO(String? valor, [String alternativo = 'No registrado']) {
    if (valor == null || valor.trim().isEmpty) return alternativo;
    return valor;
  }
}
