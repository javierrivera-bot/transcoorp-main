import 'package:transcoorp/models/comun/json.dart';

abstract final class EstadoMantenimiento {
  static const enMantenimiento = 'EN_MANTENIMIENTO';
  static const finalizado = 'FINALIZADO';
}

class Mantenimiento {
  const Mantenimiento({
    required this.id,
    required this.placaVehiculo,
    required this.motivo,
    required this.estado,
    this.fechaIngreso,
    this.estadoVehiculoIngreso,
    this.observacionesIngreso,
    this.fechaSalida,
    this.observaciones,
    this.registradoPor,
    this.salidaRegistradaPor,
  });

  final int id;
  final String placaVehiculo;
  final String motivo;
  final String estado;
  final DateTime? fechaIngreso;
  final String? estadoVehiculoIngreso;
  final String? observacionesIngreso;
  final DateTime? fechaSalida;
  final String? observaciones;
  final String? registradoPor;
  final String? salidaRegistradaPor;

  factory Mantenimiento.fromJson(Map<String, dynamic> json) => Mantenimiento(
    id: Json.entero(json, 'id'),
    placaVehiculo: Json.texto(json, 'placaVehiculo'),
    motivo: Json.texto(json, 'motivo'),
    estado: Json.texto(json, 'estado'),
    fechaIngreso: Json.fecha(json, 'fechaIngreso'),
    estadoVehiculoIngreso: Json.textoONulo(json, 'estadoVehiculoIngreso'),
    observacionesIngreso:
        Json.textoONulo(json, 'observacionesIngreso') ??
        Json.textoONulo(json, 'observaciones'),
    fechaSalida: Json.fecha(json, 'fechaSalida'),
    observaciones: Json.textoONulo(json, 'observaciones'),
    registradoPor: Json.textoONulo(json, 'registradoPor'),
    salidaRegistradaPor: Json.textoONulo(json, 'salidaRegistradaPor'),
  );

  bool get abierto => estado == EstadoMantenimiento.enMantenimiento;
}
