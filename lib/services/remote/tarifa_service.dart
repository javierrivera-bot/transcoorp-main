import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/tarifa/tarifa.dart';
import 'package:transcoorp/services/remote/servicio_base.dart';

class TarifaService extends ServicioBase {
  static const _ruta = '/api/tarifas';

  Future<Pagina<Tarifa>> listar({
    int pagina = 1,
    int tamano = ServicioBase.tamanoPagina,
    bool? activo,
  }) {
    return paginar(
      _ruta,
      Tarifa.fromJson,
      pagina: pagina,
      tamano: tamano,
      filtros: {if (activo != null) 'activo': '$activo'},
    );
  }

  Future<List<Tarifa>> activas() async {
    final pagina = await listar(tamano: ServicioBase.tamanoMaximo, activo: true);
    return pagina.items;
  }

  Future<Tarifa> obtenerPorId(int id) => obtener('$_ruta/$id', Tarifa.fromJson);

  Future<Tarifa> registrar({
    required double aportesGastosVarios,
    required double fondoReposicion,
    required double aporteSocialSocio,
    required bool activo,
  }) {
    return crear(_ruta, {
      'aportesGastosVarios': aportesGastosVarios,
      'fondoReposicion': fondoReposicion,
      'aporteSocialSocio': aporteSocialSocio,
      'activo': activo,
    }, Tarifa.fromJson);
  }

  Future<void> inactivar(int id) => eliminar('$_ruta/$id');
}
