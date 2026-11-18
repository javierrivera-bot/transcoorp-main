import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/comun/json.dart';

class Conductor {
  const Conductor({
    required this.identificacion,
    required this.nombres,
    required this.activo,
    this.fechaNacimiento,
    this.numeroLicencia,
    this.categoriaLicencia,
    this.vigenciaLicencia,
    this.celular,
    this.correo,
    this.fechaRegistro,
    this.ultimaActualizacion,
  });

  final String identificacion;
  final String nombres;
  final bool activo;
  final DateTime? fechaNacimiento;
  final String? numeroLicencia;
  final String? categoriaLicencia;
  final DateTime? vigenciaLicencia;
  final String? celular;
  final String? correo;
  final DateTime? fechaRegistro;
  final DateTime? ultimaActualizacion;

  factory Conductor.fromJson(Map<String, dynamic> json) => Conductor(
    identificacion: Json.texto(json, 'identificacion'),
    nombres: Json.texto(json, 'nombres'),
    activo: Json.booleano(json, 'activo'),
    fechaNacimiento: Json.fecha(json, 'fechaNacimiento'),
    numeroLicencia: Json.textoONulo(json, 'numeroLicencia'),
    categoriaLicencia: Json.textoONulo(json, 'categoriaLicencia'),
    vigenciaLicencia: Json.fecha(json, 'vigenciaLicencia'),
    celular: Json.textoONulo(json, 'celular'),
    correo: Json.textoONulo(json, 'correo'),
    fechaRegistro: Json.fecha(json, 'fechaRegistro'),
    ultimaActualizacion: Json.fecha(json, 'ultimaFechaActualizacion'),
  );

  String get iniciales => Formato.iniciales(nombres);

  bool get licenciaVencida => Fechas.vencida(vigenciaLicencia);
}
