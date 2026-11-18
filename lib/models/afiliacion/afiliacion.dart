import 'package:transcoorp/models/comun/json.dart';

abstract final class EstadoAfiliacion {
  static const activa = 'ACTIVA';
  static const inactiva = 'INACTIVA';
  static const suspendida = 'SUSPENDIDA';
  static const finalizada = 'FINALIZADA';

  static const valores = [activa, inactiva, suspendida, finalizada];
}

class Afiliacion {
  const Afiliacion({
    required this.id,
    required this.identificacionAsociado,
    required this.placaVehiculo,
    required this.estado,
    this.fechaAfiliacion,
    this.fechaFin,
    this.fechaRegistro,
    this.ultimaActualizacion,
  });

  final int id;
  final String identificacionAsociado;
  final String placaVehiculo;
  final String estado;
  final DateTime? fechaAfiliacion;
  final DateTime? fechaFin;
  final DateTime? fechaRegistro;
  final DateTime? ultimaActualizacion;

  factory Afiliacion.fromJson(Map<String, dynamic> json) => Afiliacion(
    id: Json.entero(json, 'id'),
    identificacionAsociado: Json.texto(json, 'identificacionAsociado'),
    placaVehiculo: Json.texto(json, 'placaVehiculo'),
    estado: Json.texto(json, 'estado'),
    fechaAfiliacion: Json.fecha(json, 'fechaAfiliacion'),
    fechaFin: Json.fecha(json, 'fechaFinAfiliacion'),
    fechaRegistro: Json.fecha(json, 'fechaRegistro'),
    ultimaActualizacion: Json.fecha(json, 'ultimaFechaActualizacion'),
  );

  bool get activa => estado == EstadoAfiliacion.activa;
}
