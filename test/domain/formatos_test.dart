import 'package:flutter_test/flutter_test.dart';
import 'package:transcoorp/domain/formatos.dart';

void main() {
  group('Formato.moneda', () {
    test(r'agrupa miles con punto y prefija $', () {
      expect(Formato.moneda(1234567), r'$ 1.234.567');
      expect(Formato.moneda(1000), r'$ 1.000');
      expect(Formato.moneda(0), r'$ 0');
    });

    test('conserva el signo negativo', () {
      expect(Formato.moneda(-1500), r'-$ 1.500');
    });

    test('redondea decimales', () {
      expect(Formato.moneda(1234.6), r'$ 1.235');
    });
  });

  group('Formato.iniciales', () {
    test('toma la primera letra de las dos primeras palabras', () {
      expect(Formato.iniciales('Juan Carlos Pérez'), 'JC');
      expect(Formato.iniciales('  ana   maría  '), 'AM');
    });

    test('una sola palabra y vacío', () {
      expect(Formato.iniciales('Juan'), 'J');
      expect(Formato.iniciales('   '), '?');
    });
  });

  test('capitalizar normaliza guiones bajos y mayúsculas', () {
    expect(Formato.capitalizar('ESTADO_ACTIVO'), 'Estado activo');
    expect(Formato.capitalizar('  VIAJE '), 'Viaje');
    expect(Formato.capitalizar(''), '');
  });

  test('valorO usa el alternativo para nulos y vacíos', () {
    expect(Formato.valorO(null), 'No registrado');
    expect(Formato.valorO('   '), 'No registrado');
    expect(Formato.valorO('Juan'), 'Juan');
    expect(Formato.valorO(null, '-'), '-');
  });
}
