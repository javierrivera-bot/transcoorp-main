import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/mantenimiento/mantenimiento.dart';
import 'package:transcoorp/services/remote/servicio_base.dart';

class MantenimientoService extends ServicioBase {
  static const _ruta = '/api/mantenimientos';

  static const estadosIngreso = [
    'Operativo con novedades',
    'Requiere revisión preventiva',
    'Averiado, no operativo',
    'Siniestrado',
  ];

  Future<Pagina<Mantenimiento>> listar({
    int pagina = 1,
    int tamano = ServicioBase.tamanoPagina,
    String placa = '',
    String? estado,
  }) {
    return paginar(
      _ruta,
      Mantenimiento.fromJson,
      pagina: pagina,
      tamano: tamano,
      filtros: {'Placa': placa, 'Estado': ?estado},
    );
  }

  Future<Mantenimiento?> abiertoDe(String placa) async {
    final pagina = await listar(
      placa: placa,
      estado: EstadoMantenimiento.enMantenimiento,
      tamano: 5,
    );
    for (final mantenimiento in pagina.items) {
      if (mantenimiento.placaVehiculo == placa && mantenimiento.abierto) {
        return mantenimiento;
      }
    }
    return null;
  }

  Future<Mantenimiento> registrarIngreso({
    required String placaVehiculo,
    required DateTime fechaIngreso,
    required String motivo,
    required String estadoVehiculo,
    required String observaciones,
  }) {
    return crear(_ruta, {
      'placaVehiculo': placaVehiculo,
      'fechaIngreso': Fechas.apiFechaHora(fechaIngreso),
      'motivo': motivo,
      'estadoVehiculoIngreso': estadoVehiculo,
      'observaciones': observaciones,
    }, Mantenimiento.fromJson);
  }

  Future<Mantenimiento> registrarSalida(
    int id, {
    required DateTime fechaSalida,
    required String observaciones,
  }) {
    return actualizar('$_ruta/$id', {
      'fechaSalida': Fechas.apiFechaHora(fechaSalida),
      'observaciones': observaciones,
    }, Mantenimiento.fromJson);
  }
}
