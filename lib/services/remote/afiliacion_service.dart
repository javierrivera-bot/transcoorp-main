import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/afiliacion/afiliacion.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/services/remote/servicio_base.dart';

class AfiliacionService extends ServicioBase {
  static const _ruta = '/api/afiliaciones';

  Future<Pagina<Afiliacion>> listar({
    int pagina = 1,
    int tamano = ServicioBase.tamanoPagina,
    String asociado = '',
    String vehiculo = '',
    String? estado,
  }) {
    return paginar(
      _ruta,
      Afiliacion.fromJson,
      pagina: pagina,
      tamano: tamano,
      filtros: {'asociado': asociado, 'vehiculo': vehiculo, 'estado': ?estado},
    );
  }

  Future<Afiliacion> obtenerPorId(int id) =>
      obtener('$_ruta/$id', Afiliacion.fromJson);

  Future<Afiliacion> registrar({
    required String identificacionAsociado,
    required String placaVehiculo,
    required DateTime fechaAfiliacion,
    DateTime? fechaFin,
    String estado = EstadoAfiliacion.activa,
  }) {
    return crear(_ruta, {
      'identificacionAsociado': identificacionAsociado,
      'placaVehiculo': placaVehiculo,
      'fechaAfiliacion': Fechas.api(fechaAfiliacion),
      'fechaFinAfiliacion': fechaFin == null ? null : Fechas.api(fechaFin),
      'estado': estado,
    }, Afiliacion.fromJson);
  }

  Future<Afiliacion> editar(
    Afiliacion afiliacion, {
    required DateTime fechaAfiliacion,
    DateTime? fechaFin,
    required String estado,
  }) {
    return actualizar('$_ruta/${afiliacion.id}', {
      'identificacionAsociado': afiliacion.identificacionAsociado,
      'placaVehiculo': afiliacion.placaVehiculo,
      'fechaAfiliacion': Fechas.api(fechaAfiliacion),
      'fechaFinAfiliacion': fechaFin == null ? null : Fechas.api(fechaFin),
      'estado': estado,
    }, Afiliacion.fromJson);
  }

  Future<Afiliacion> finalizar(Afiliacion afiliacion, DateTime fechaFin) {
    return editar(
      afiliacion,
      fechaAfiliacion: afiliacion.fechaAfiliacion ?? Fechas.hoy,
      fechaFin: fechaFin,
      estado: EstadoAfiliacion.finalizada,
    );
  }

  Future<void> desafiliar(int id, DateTime fechaFin) => eliminar(
    '$_ruta/$id',
    cuerpo: {'fechaFinAfiliacion': Fechas.api(fechaFin)},
  );
}
