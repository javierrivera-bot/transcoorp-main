import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transcoorp/domain/fechas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fechas', () {
    test('soloFecha elimina la hora', () {
      final fecha = DateTime(2026, 11, 17, 15, 42, 10);
      expect(Fechas.soloFecha(fecha), DateTime(2026, 11, 17));
    });

    test('corta y media', () {
      final fecha = DateTime(2026, 11, 7);
      expect(Fechas.corta(fecha), '07/11/2026');
      expect(Fechas.media(fecha), '7 Nov 2026');
      expect(Fechas.corta(null), '—');
      expect(Fechas.media(null), '—');
    });

    test('api y apiFechaHora', () {
      expect(Fechas.api(DateTime(2026, 1, 2)), '2026-01-02');
      expect(
        Fechas.apiFechaHora(DateTime(2026, 1, 2, 3, 4)),
        '2026-01-02T03:04:00',
      );
    });

    test('horaApi', () {
      expect(Fechas.horaApi(const TimeOfDay(hour: 9, minute: 5)), '09:05:00');
    });

    test('hora12 en medianoche, mediodía y tarde', () {
      expect(Fechas.hora12(DateTime(2026, 1, 1, 0, 0)), '12:00 AM');
      expect(Fechas.hora12(DateTime(2026, 1, 1, 12, 0)), '12:00 PM');
      expect(Fechas.hora12(DateTime(2026, 1, 1, 13, 5)), '01:05 PM');
    });

    test('horaTexto convierte y respeta valores inválidos', () {
      expect(Fechas.horaTexto('14:30:00'), '02:30 PM');
      expect(Fechas.horaTexto('08:00'), '08:00 AM');
      expect(Fechas.horaTexto(null), '—');
      expect(Fechas.horaTexto('abc'), 'abc');
    });

    test('fechaLarga usa el día y mes en español', () {
      expect(
        Fechas.fechaLarga(DateTime(2026, 11, 17)),
        'Martes, 17 Noviembre 2026',
      );
      expect(Fechas.fechaLargaSegura(null), '—');
    });

    test('saludo por franja horaria', () {
      expect(Fechas.saludo(DateTime(2026, 1, 1, 8)), 'Buenos días');
      expect(Fechas.saludo(DateTime(2026, 1, 1, 15)), 'Buenas tardes');
      expect(Fechas.saludo(DateTime(2026, 1, 1, 21)), 'Buenas noches');
    });

    test('vencida y diasHasta', () {
      final hoy = Fechas.hoy;
      expect(Fechas.vencida(hoy.subtract(const Duration(days: 1))), isTrue);
      expect(Fechas.vencida(hoy), isFalse);
      expect(Fechas.vencida(hoy.add(const Duration(days: 1))), isFalse);
      expect(Fechas.vencida(null), isFalse);
      expect(
        Fechas.diasHasta(hoy.add(const Duration(days: 3))),
        3,
      );
    });
  });
}
