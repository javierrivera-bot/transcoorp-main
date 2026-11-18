import 'package:transcoorp/models/comun/json.dart';

class Despacho {
  const Despacho({
    required this.id,
    required this.ruta,
    required this.placaVehiculo,
    required this.numeroPasajeros,
    required this.estado,
    this.fecha,
    this.hora,
    this.fechaRegistro,
    this.registradoPor,
    this.fechaCancelacion,
    this.canceladoPor,
    this.motivoCancelacion,
  });

  final int id;
  final String ruta;
  final String placaVehiculo;
  final int numeroPasajeros;
  final String estado;
  final DateTime? fecha;
  final String? hora;
  final DateTime? fechaRegistro;
  final String? registradoPor;
  final DateTime? fechaCancelacion;
  final String? canceladoPor;
  final String? motivoCancelacion;

  factory Despacho.fromJson(Map<String, dynamic> json) => Despacho(
    id: Json.entero(json, 'id'),
    ruta: Json.texto(json, 'ruta'),
    placaVehiculo: Json.texto(json, 'placaVehiculo'),
    numeroPasajeros: Json.entero(json, 'numeroPasajeros'),
    estado: Json.texto(json, 'estado'),
    fecha: Json.fecha(json, 'fecha'),
    hora: Json.textoONulo(json, 'hora'),
    fechaRegistro: Json.fecha(json, 'fechaRegistro'),
    registradoPor: Json.textoONulo(json, 'registradoPor'),
    fechaCancelacion: Json.fecha(json, 'fechaCancelacion'),
    canceladoPor: Json.textoONulo(json, 'canceladoPor'),
    motivoCancelacion: Json.textoONulo(json, 'motivoCancelacion'),
  );

  bool get cancelado => estado == 'CANCELADO';

  String get codigo => 'DSP-${id.toString().padLeft(5, '0')}';
}
