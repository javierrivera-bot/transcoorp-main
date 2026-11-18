import 'package:transcoorp/models/comun/json.dart';

class Tarifa {
  const Tarifa({
    required this.id,
    required this.aportesGastosVarios,
    required this.fondoReposicion,
    required this.aporteSocialSocio,
    required this.total,
    required this.activo,
    this.fechaRegistro,
    this.ultimaActualizacion,
  });

  final int id;
  final double aportesGastosVarios;
  final double fondoReposicion;
  final double aporteSocialSocio;
  final double total;
  final bool activo;
  final DateTime? fechaRegistro;
  final DateTime? ultimaActualizacion;

  factory Tarifa.fromJson(Map<String, dynamic> json) {
    final gastos = Json.decimal(json, 'aportesGastosVarios');
    final fondo = Json.decimal(json, 'fondoReposicion');
    final aporte = Json.decimal(json, 'aporteSocialSocio');
    final total = Json.decimal(json, 'total');
    return Tarifa(
      id: Json.entero(json, 'id'),
      aportesGastosVarios: gastos,
      fondoReposicion: fondo,
      aporteSocialSocio: aporte,
      total: total == 0 ? gastos + fondo + aporte : total,
      activo: Json.booleano(json, 'activo'),
      fechaRegistro: Json.fecha(json, 'fechaRegistro'),
      ultimaActualizacion: Json.fecha(json, 'ultimaFechaActualizacion'),
    );
  }

  String get nombre => 'Tarifa N.° $id';
}
