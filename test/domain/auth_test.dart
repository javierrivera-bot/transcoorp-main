import 'package:flutter_test/flutter_test.dart';
import 'package:transcoorp/domain/auth.dart';

void main() {
  group('validaciones de acceso', () {
    test('validarUsuario', () {
      expect(Auth.validarUsuario('   '), isNotNull);
      expect(Auth.validarUsuario('juan pérez'), isNotNull);
      expect(Auth.validarUsuario('socio1'), isNull);
    });

    test('validarContrasena', () {
      expect(Auth.validarContrasena(''), isNotNull);
      expect(Auth.validarContrasena('12345'), isNotNull);
      expect(Auth.validarContrasena('123456'), isNull);
    });

    test('validarCorreo', () {
      expect(Auth.validarCorreo(''), isNotNull);
      expect(Auth.validarCorreo('correo'), isNotNull);
      expect(Auth.validarCorreo('socio@transcoop.com'), isNull);
    });

    test('validarOtp exige 6 dígitos', () {
      expect(Auth.validarOtp('12345'), isNotNull);
      expect(Auth.validarOtp('1234567'), isNotNull);
      expect(Auth.validarOtp('123456'), isNull);
    });

    test('nueva contraseña y confirmación', () {
      expect(Auth.validarNuevaContrasena('abc'), isNotNull);
      expect(Auth.validarNuevaContrasena('Abcdefghijkl1'), isNull);
      expect(Auth.validarConfirmacion('Abcdefghijkl1', ''), isNotNull);
      expect(
        Auth.validarConfirmacion('Abcdefghijkl1', 'OtraClave12345'),
        isNotNull,
      );
      expect(
        Auth.validarConfirmacion('Abcdefghijkl1', 'Abcdefghijkl1'),
        isNull,
      );
    });
  });

  test('enmascararCorreo oculta el centro de la parte local', () {
    expect(Auth.enmascararCorreo('juan@transcoop.com'), 'j***n@transcoop.com');
    expect(Auth.enmascararCorreo('a@transcoop.com'), 'a@transcoop.com');
    expect(Auth.enmascararCorreo('sin-correo'), 'sin-correo');
  });

  test('nivel de seguridad y etiqueta', () {
    expect(Auth.nivelSeguridad('abc'), 0);
    expect(Auth.nivelSeguridad('Abcdefghijkl'), 2);
    expect(Auth.nivelSeguridad('Abcdefghijkl1'), 3);
    expect(Auth.etiquetaSeguridad(0), 'Básica');
    expect(Auth.etiquetaSeguridad(2), 'Media');
    expect(Auth.etiquetaSeguridad(3), 'Segura');
  });
}
