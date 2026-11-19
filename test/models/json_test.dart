import 'package:flutter_test/flutter_test.dart';
import 'package:transcoorp/models/comun/json.dart';

void main() {
  group('Json.datos', () {
    test('devuelve el objeto data cuando existe', () {
      expect(
        Json.datos({'data': {'id': 1}}),
        {'id': 1},
      );
    });

    test('devuelve el mapa original si no hay data map', () {
      final original = {'id': 1};
      expect(Json.datos(original), same(original));
      expect(Json.datos('otro'), isEmpty);
    });
  });

  group('Json.lista', () {
    test('lee listas directas y bajo data/items', () {
      final items = [
        {'id': 1},
        {'id': 2},
      ];
      expect(Json.lista(items), items);
      expect(Json.lista({'data': items}), items);
      expect(Json.lista({'data': {'items': items}}), items);
      expect(Json.lista({'items': items}), items);
    });

    test('filtra elementos que no son mapas', () {
      expect(
        Json.lista([{'id': 1}, 'texto', 3]),
        [
          {'id': 1},
        ],
      );
    });

    test('respuesta inválida da lista vacía', () {
      expect(Json.lista(null), isEmpty);
      expect(Json.lista({'otro': []}), isEmpty);
    });
  });

  group('convertidores escalares', () {
    final json = <String, dynamic>{
      'texto': '  Juan  ',
      'vacio': '   ',
      'entero': 7,
      'enteroTexto': '12',
      'decimalTexto': '12.5',
      'numero': 3.9,
      'booleano': true,
      'fecha': '2026-11-17T10:20:30Z',
      'objeto': {'id': 4},
    };

    test('texto y textoONulo', () {
      expect(Json.texto(json, 'texto'), '  Juan  ');
      expect(Json.texto(json, 'ausente'), '');
      expect(Json.textoONulo(json, 'vacio'), isNull);
      expect(Json.textoONulo(json, 'texto'), 'Juan');
    });

    test('enteros', () {
      expect(Json.entero(json, 'entero'), 7);
      expect(Json.entero(json, 'numero'), 3);
      expect(Json.entero(json, 'enteroTexto'), 12);
      expect(Json.entero(json, 'decimalTexto'), 0);
      expect(Json.entero(json, 'ausente'), 0);
      expect(Json.enteroONulo(json, 'ausente'), isNull);
      expect(Json.enteroONulo(json, 'entero'), 7);
    });

    test('decimales y booleanos', () {
      expect(Json.decimal(json, 'numero'), 3.9);
      expect(Json.decimal(json, 'decimalTexto'), 12.5);
      expect(Json.decimal(json, 'ausente'), 0.0);
      expect(Json.booleano(json, 'booleano'), isTrue);
      expect(Json.booleano(json, 'ausente'), isFalse);
    });

    test('fecha y objeto', () {
      final fecha = Json.fecha(json, 'fecha');
      expect(fecha, isNotNull);
      expect(fecha!.year, 2026);
      expect(Json.fecha(json, 'ausente'), isNull);
      expect(Json.objeto(json, 'objeto'), {'id': 4});
      expect(Json.objeto(json, 'ausente'), isEmpty);
    });
  });
}
