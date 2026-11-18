import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/comun/json.dart';

class Asociado {
  const Asociado({
    required this.identificacion,
    required this.nombres,
    required this.activo,
    this.username,
    this.estadoCredencial,
    this.celular,
    this.correo,
    this.fechaNacimiento,
    this.fechaIngreso,
    this.fechaRegistro,
    this.ultimaActualizacion,
  });

  final String identificacion;
  final String nombres;
  final bool activo;
  final String? username;
  final String? estadoCredencial;
  final String? celular;
  final String? correo;
  final DateTime? fechaNacimiento;
  final DateTime? fechaIngreso;
  final DateTime? fechaRegistro;
  final DateTime? ultimaActualizacion;

  factory Asociado.fromJson(Map<String, dynamic> json) => Asociado(
    identificacion: Json.texto(json, 'identificacion'),
    nombres: Json.texto(json, 'nombres'),
    activo: Json.booleano(json, 'activo'),
    username: Json.textoONulo(json, 'username'),
    estadoCredencial: Json.textoONulo(json, 'estadoCredencial'),
    celular: Json.textoONulo(json, 'celular'),
    correo: Json.textoONulo(json, 'correo'),
    fechaNacimiento: Json.fecha(json, 'fechaNacimiento'),
    fechaIngreso: Json.fecha(json, 'fechaIngreso'),
    fechaRegistro: Json.fecha(json, 'fechaRegistro'),
    ultimaActualizacion: Json.fecha(json, 'ultimaFechaActualizacion'),
  );

  String get iniciales => Formato.iniciales(nombres);
}

class CredencialTemporal {
  const CredencialTemporal({
    required this.username,
    required this.password,
    this.expira,
  });

  final String username;
  final String password;
  final DateTime? expira;

  factory CredencialTemporal.fromJson(Map<String, dynamic> json) =>
      CredencialTemporal(
        username: Json.texto(json, 'username'),
        password: Json.texto(json, 'passwordTemporal'),
        expira: Json.fecha(json, 'expiraEn'),
      );
}
