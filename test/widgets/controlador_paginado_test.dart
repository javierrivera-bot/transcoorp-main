import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/widgets/vista_paginada.dart';

Pagina<int> _pagina(int numero, {int totalPaginas = 3}) => Pagina<int>(
  items: [numero * 10, numero * 10 + 1],
  pagina: numero,
  totalPaginas: totalPaginas,
  totalItems: totalPaginas * 2,
);

void main() {
  test('cargarMas pide la primera página y expone el resultado', () async {
    final pedidas = <int>[];
    final controlador = ControladorPaginado<int>((pagina) async {
      pedidas.add(pagina);
      return _pagina(pagina);
    });

    await controlador.cargarMas();

    expect(pedidas, [1]);
    expect(controlador.items, [10, 11]);
    expect(controlador.totalItems, 6);
    expect(controlador.hayMas, isTrue);
    expect(controlador.iniciado, isTrue);
    expect(controlador.vacio, isFalse);
  });

  test('cargarMas acumula páginas', () async {
    final controlador = ControladorPaginado<int>((pagina) async => _pagina(pagina));

    await controlador.cargarMas();
    await controlador.cargarMas();

    expect(controlador.items, [10, 11, 20, 21]);
  });

  test('no pide más páginas cuando no hay más', () async {
    final pedidas = <int>[];
    final controlador = ControladorPaginado<int>((pagina) async {
      pedidas.add(pagina);
      return _pagina(pagina, totalPaginas: 1);
    });

    await controlador.cargarMas();
    await controlador.cargarMas();

    expect(pedidas, [1]);
    expect(controlador.hayMas, isFalse);
  });

  test('recargar descarta lo anterior y vuelve a la página 1', () async {
    final pedidas = <int>[];
    final controlador = ControladorPaginado<int>((pagina) async {
      pedidas.add(pagina);
      return _pagina(pagina);
    });

    await controlador.cargarMas();
    await controlador.cargarMas();
    await controlador.recargar();

    expect(pedidas, [1, 2, 1]);
    expect(controlador.items, [10, 11]);
    expect(controlador.error, isNull);
  });

  test('un ApiException se expone como error y deja de cargar', () async {
    final controlador = ControladorPaginado<int>((pagina) async {
      throw const ApiException('No se pudo cargar');
    });

    await controlador.cargarMas();

    expect(controlador.error, 'No se pudo cargar');
    expect(controlador.cargando, isFalse);
    expect(controlador.iniciado, isTrue);
    expect(controlador.vacio, isTrue);
  });

  test('una recarga descarta la respuesta de una petición anterior', () async {
    final completer = Completer<Pagina<int>>();
    final controlador = ControladorPaginado<int>((pagina) => completer.future);

    final primera = controlador.cargarMas();
    final recarga = controlador.recargar();
    completer.complete(_pagina(1, totalPaginas: 1));
    await Future.wait([primera, recarga]);

    expect(controlador.items, [10, 11]);
    expect(controlador.error, isNull);
  });
}
