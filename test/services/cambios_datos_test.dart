import 'package:flutter_test/flutter_test.dart';
import 'package:transcoorp/services/local/cambios_datos.dart';

void main() {
  test('notificarConductores avisa a las pantallas suscritas', () {
    final notificador = CambiosDatos.conductores;
    final valorInicial = notificador.value;
    var avisos = 0;

    void escuchar() => avisos++;
    notificador.addListener(escuchar);
    addTearDown(() => notificador.removeListener(escuchar));

    CambiosDatos.notificarConductores();

    expect(notificador.value, valorInicial + 1);
    expect(avisos, 1);
  });
}
