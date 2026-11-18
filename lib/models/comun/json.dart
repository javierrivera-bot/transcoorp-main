abstract final class Json {
  static Map<String, dynamic> datos(dynamic respuesta) {
    if (respuesta is Map<String, dynamic>) {
      final data = respuesta['data'];
      if (data is Map<String, dynamic>) return data;
      return respuesta;
    }
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> lista(dynamic respuesta) {
    dynamic fuente = respuesta;
    if (fuente is Map<String, dynamic>) {
      fuente = fuente['data'] ?? fuente['items'] ?? fuente;
    }
    if (fuente is Map<String, dynamic>) {
      fuente = fuente['items'];
    }
    if (fuente is List) {
      return fuente.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  static String texto(Map<String, dynamic> json, String clave) =>
      json[clave]?.toString() ?? '';

  static String? textoONulo(Map<String, dynamic> json, String clave) {
    final valor = json[clave]?.toString().trim();
    return valor == null || valor.isEmpty ? null : valor;
  }

  static int entero(Map<String, dynamic> json, String clave) {
    final valor = json[clave];
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static int? enteroONulo(Map<String, dynamic> json, String clave) {
    final valor = json[clave];
    if (valor == null) return null;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor.toString());
  }

  static double decimal(Map<String, dynamic> json, String clave) {
    final valor = json[clave];
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static bool booleano(Map<String, dynamic> json, String clave) =>
      json[clave] == true;

  static DateTime? fecha(Map<String, dynamic> json, String clave) {
    final valor = json[clave]?.toString();
    if (valor == null || valor.isEmpty) return null;
    final fecha = DateTime.tryParse(valor);
    if (fecha == null) return null;
    return fecha.isUtc ? fecha.toLocal() : fecha;
  }

  static Map<String, dynamic> objeto(Map<String, dynamic> json, String clave) {
    final valor = json[clave];
    return valor is Map<String, dynamic> ? valor : const <String, dynamic>{};
  }
}
