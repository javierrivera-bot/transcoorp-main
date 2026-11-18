import 'dart:convert';

import 'package:transcoorp/models/comun/json.dart';

abstract final class Rol {
  static const admin = 'ADMIN';
  static const gerente = 'GERENTE';
  static const asistente = 'ASISTENTE';
  static const asociado = 'ASOCIADO';

  static String etiqueta(String rol) => switch (rol) {
    admin => 'Administrador de plataforma',
    gerente => 'Gerente',
    asistente => 'Asistente administrativo',
    asociado => 'Asociado',
    _ => rol,
  };
}

class Sesion {
  const Sesion({
    required this.token,
    required this.rol,
    required this.username,
    required this.requiereCambioPassword,
    this.identificacion,
    this.empresa,
    this.expira,
  });

  final String token;
  final String rol;
  final String username;
  final bool requiereCambioPassword;
  final String? identificacion;
  final String? empresa;
  final DateTime? expira;

  factory Sesion.desdeLogin(dynamic respuesta) {
    final json = Json.datos(respuesta);
    final token = Json.texto(json, 'token');
    final empresa = Json.objeto(json, 'empresa');
    return Sesion(
      token: token,
      rol: Json.texto(json, 'rol').toUpperCase(),
      username: Json.texto(json, 'username'),
      requiereCambioPassword: Json.booleano(json, 'requiereCambioPassword'),
      identificacion: Json.textoONulo(json, 'identificacion'),
      empresa: Json.textoONulo(empresa, 'razonSocial'),
      expira: _expiracion(token, json['expiraEn']),
    );
  }

  factory Sesion.fromJson(Map<String, dynamic> json) => Sesion(
    token: Json.texto(json, 'token'),
    rol: Json.texto(json, 'rol'),
    username: Json.texto(json, 'username'),
    requiereCambioPassword: false,
    identificacion: Json.textoONulo(json, 'identificacion'),
    empresa: Json.textoONulo(json, 'empresa'),
    expira: Json.fecha(json, 'expira'),
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'rol': rol,
    'username': username,
    'identificacion': identificacion,
    'empresa': empresa,
    'expira': expira?.toIso8601String(),
  };

  bool get valida =>
      token.isNotEmpty && (expira == null || DateTime.now().isBefore(expira!));

  bool get esAsociado => rol == Rol.asociado;

  bool get esAdministrativo => !esAsociado;

  bool get puedeSancionar => rol == Rol.gerente || rol == Rol.asistente;

  String get rolLegible => Rol.etiqueta(rol);

  static DateTime? _expiracion(String token, dynamic expiraEn) {
    final partes = token.split('.');
    if (partes.length == 3) {
      try {
        final carga = utf8.decode(
          base64Url.decode(base64Url.normalize(partes[1])),
        );
        final json = jsonDecode(carga);
        if (json is Map && json['exp'] is num) {
          return DateTime.fromMillisecondsSinceEpoch(
            (json['exp'] as num).toInt() * 1000,
          );
        }
      } catch (_) {}
    }

    if (expiraEn is num && expiraEn > 0) {
      final valor = expiraEn.toInt();
      if (valor > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(valor);
      }
      if (valor > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(valor * 1000);
      }
      return DateTime.now().add(Duration(seconds: valor));
    }
    return null;
  }
}
