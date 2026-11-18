import 'package:transcoorp/config/app_config.dart';
import 'package:transcoorp/models/comun/json.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/cabeceras_autenticadas.dart';

abstract class ServicioBase {
  static const int tamanoPagina = 20;
  static const int tamanoMaximo = 100;

  final ApiService api = ApiService(baseUrl: AppConfig.apiBaseUrl);

  Map<String, String> get cabeceras => cabecerasAutenticadas();

  Future<Pagina<T>> paginar<T>(
    String ruta,
    T Function(Map<String, dynamic> json) convertir, {
    int pagina = 1,
    int tamano = tamanoPagina,
    Map<String, String> filtros = const {},
  }) async {
    final respuesta = await api.get(
      ruta,
      queryParameters: {
        ...filtros,
        'page': '$pagina',
        'pageSize': '$tamano',
      },
      headers: cabeceras,
    );
    return _convertir(() => Pagina<T>.desdeRespuesta(respuesta, convertir));
  }

  Future<T> obtener<T>(
    String ruta,
    T Function(Map<String, dynamic> json) convertir,
  ) async {
    final respuesta = await api.get(ruta, headers: cabeceras);
    return _convertir(() => convertir(Json.datos(respuesta)));
  }

  Future<T> crear<T>(
    String ruta,
    Map<String, dynamic> cuerpo,
    T Function(Map<String, dynamic> json) convertir,
  ) async {
    final respuesta = await api.post(ruta, body: cuerpo, headers: cabeceras);
    return _convertir(() => convertir(Json.datos(respuesta)));
  }

  Future<T> actualizar<T>(
    String ruta,
    Map<String, dynamic> cuerpo,
    T Function(Map<String, dynamic> json) convertir,
  ) async {
    final respuesta = await api.put(ruta, body: cuerpo, headers: cabeceras);
    return _convertir(() => convertir(Json.datos(respuesta)));
  }

  Future<void> eliminar(String ruta, {Map<String, dynamic>? cuerpo}) async {
    await api.delete(ruta, body: cuerpo, headers: cabeceras);
  }

  Future<int> contar(String ruta, {Map<String, String> filtros = const {}}) async {
    final pagina = await paginar<Map<String, dynamic>>(
      ruta,
      (json) => json,
      tamano: 1,
      filtros: filtros,
    );
    return pagina.totalItems;
  }

  T _convertir<T>(T Function() accion) {
    try {
      return accion();
    } on TypeError {
      throw const ApiException('El servidor devolvió una respuesta inesperada.');
    }
  }
}
