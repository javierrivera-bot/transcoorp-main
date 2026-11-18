import 'package:flutter_test/flutter_test.dart';
import 'package:transcoorp/models/comun/pagina.dart';

void main() {
  test('desdeRespuesta lee items y paginación anidados', () {
    final respuesta = {
      'data': {
        'items': [
          {'id': 1},
          {'id': 2},
        ],
        'pagination': {
          'page': 2,
          'totalPages': 5,
          'totalItems': 93,
        },
      },
    };

    final pagina = Pagina<int>.desdeRespuesta(
      respuesta,
      (json) => json['id'] as int,
    );

    expect(pagina.items, [1, 2]);
    expect(pagina.pagina, 2);
    expect(pagina.totalPaginas, 5);
    expect(pagina.totalItems, 93);
    expect(pagina.hayMas, isTrue);
  });

  test('sin paginación usa valores por defecto', () {
    final pagina = Pagina<String>.desdeRespuesta(
      [
        {'valor': 'a'},
        {'valor': 'b'},
      ],
      (json) => json['valor'] as String,
    );

    expect(pagina.items, ['a', 'b']);
    expect(pagina.pagina, 1);
    expect(pagina.totalPaginas, 1);
    expect(pagina.totalItems, 2);
    expect(pagina.hayMas, isFalse);
  });

  test('hayMas es falso en la última página', () {
    final pagina = Pagina<int>(
      items: const [1],
      pagina: 3,
      totalPaginas: 3,
      totalItems: 41,
    );
    expect(pagina.hayMas, isFalse);
  });
}
