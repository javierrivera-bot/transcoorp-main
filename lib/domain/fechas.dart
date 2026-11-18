import 'package:flutter/material.dart';

abstract final class Fechas {
  static const List<String> _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const List<String> _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static DateTime get hoy => soloFecha(DateTime.now());

  static DateTime soloFecha(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);

  static String fechaLarga(DateTime fecha) {
    return '${_dias[fecha.weekday - 1]}, ${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}';
  }

  static String fechaLargaSegura(DateTime? fecha) =>
      fecha == null ? '—' : fechaLarga(fecha);

  static String corta(DateTime? fecha) {
    if (fecha == null) return '—';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  static String media(DateTime? fecha) {
    if (fecha == null) return '—';
    return '${fecha.day} ${_meses[fecha.month - 1].substring(0, 3)} ${fecha.year}';
  }

  static String fechaHora(DateTime? fecha) {
    if (fecha == null) return '—';
    return '${corta(fecha)} · ${hora12(fecha)}';
  }

  static String api(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  static String apiFechaHora(DateTime fecha) {
    final local = fecha.toLocal();
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    return '${api(local)}T$hora:$minuto:00';
  }

  static String horaApi(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  static String hora12(DateTime fecha) {
    final hora = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
    final minutos = fecha.minute.toString().padLeft(2, '0');
    final sufijo = fecha.hour < 12 ? 'AM' : 'PM';
    return '${hora.toString().padLeft(2, '0')}:$minutos $sufijo';
  }

  static String horaTexto(String? hora) {
    if (hora == null || hora.isEmpty) return '—';
    final partes = hora.split(':');
    if (partes.length < 2) return hora;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null) return hora;
    return hora12(DateTime(2000, 1, 1, h, m));
  }

  static String saludo(DateTime fecha) {
    if (fecha.hour < 12) return 'Buenos días';
    if (fecha.hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  static bool vencida(DateTime? fecha) =>
      fecha != null && soloFecha(fecha).isBefore(hoy);

  static int diasHasta(DateTime fecha) =>
      soloFecha(fecha).difference(hoy).inDays;
}
