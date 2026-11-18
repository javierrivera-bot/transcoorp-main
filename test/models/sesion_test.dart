import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:transcoorp/models/sesion/sesion.dart';

String _tokenConExp(DateTime exp) {
  final payload = base64Url.encode(
    utf8.encode(jsonEncode({'exp': exp.millisecondsSinceEpoch ~/ 1000})),
  );
  return 'header.$payload.firma';
}

Map<String, dynamic> _respuesta({
  required String token,
  String rol = 'gerente',
  bool requiereCambioPassword = false,
  Object? expiraEn,
}) {
  final data = <String, dynamic>{
    'token': token,
    'rol': rol,
    'username': 'juan',
    'requiereCambioPassword': requiereCambioPassword,
    'identificacion': '0401234567',
    'empresa': {'razonSocial': 'TRANSCOOP'},
  };
  if (expiraEn != null) data['expiraEn'] = expiraEn;
  return {'data': data};
}

void main() {
  group('Sesion.desdeLogin', () {
    test('lee el token, normaliza el rol y la empresa', () {
      final sesion = Sesion.desdeLogin(
        _respuesta(
          token: _tokenConExp(DateTime.now().add(const Duration(hours: 1))),
        ),
      );

      expect(sesion.username, 'juan');
      expect(sesion.rol, 'GERENTE');
      expect(sesion.empresa, 'TRANSCOOP');
      expect(sesion.identificacion, '0401234567');
      expect(sesion.valida, isTrue);
    });

    test('la fecha de expiración viene del claim exp del JWT', () {
      final exp = DateTime.now().add(const Duration(hours: 2));
      final sesion = Sesion.desdeLogin(_respuesta(token: _tokenConExp(exp)));

      expect(sesion.expira, isNotNull);
      expect(
        sesion.expira!.difference(exp).inSeconds.abs(),
        lessThanOrEqualTo(2),
      );
    });

    test('un token vencido no es válido', () {
      final sesion = Sesion.desdeLogin(
        _respuesta(
          token: _tokenConExp(DateTime.now().subtract(const Duration(hours: 1))),
        ),
      );
      expect(sesion.valida, isFalse);
    });

    test('usa expiraEn cuando el token no es un JWT', () {
      final expiraEn =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
      final sesion = Sesion.desdeLogin(
        _respuesta(token: 'token-opaco', expiraEn: expiraEn),
      );

      expect(sesion.expira, isNotNull);
      expect(sesion.valida, isTrue);
    });
  });

  test('toJson y fromJson conservan los datos de la sesión', () {
    final original = Sesion(
      token: 'abc123',
      rol: Rol.asociado,
      username: 'socio1',
      requiereCambioPassword: false,
      identificacion: '0401234567',
      empresa: 'TRANSCOOP',
      expira: DateTime(2027, 1, 1, 12),
    );

    final restaurada = Sesion.fromJson(original.toJson());

    expect(restaurada.token, original.token);
    expect(restaurada.rol, original.rol);
    expect(restaurada.username, original.username);
    expect(restaurada.identificacion, original.identificacion);
    expect(restaurada.empresa, original.empresa);
    expect(restaurada.expira, original.expira);
  });

  test('getters de rol', () {
    final asociado = Sesion(
      token: 't',
      rol: Rol.asociado,
      username: 'u',
      requiereCambioPassword: false,
    );
    final gerente = Sesion(
      token: 't',
      rol: Rol.gerente,
      username: 'u',
      requiereCambioPassword: false,
    );

    expect(asociado.esAsociado, isTrue);
    expect(asociado.esAdministrativo, isFalse);
    expect(asociado.rolLegible, 'Asociado');
    expect(gerente.puedeSancionar, isTrue);
    expect(gerente.esAdministrativo, isTrue);
    expect(Rol.etiqueta('OTRO'), 'OTRO');
  });

  test('un token vacío no es válido', () {
    final sesion = Sesion(
      token: '',
      rol: Rol.admin,
      username: 'u',
      requiereCambioPassword: false,
    );
    expect(sesion.valida, isFalse);
  });
}
