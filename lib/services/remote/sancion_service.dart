import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/sancion/sancion.dart';
import 'package:transcoorp/services/remote/servicio_base.dart';

class SancionService extends ServicioBase {
  static const _ruta = '/api/sanciones';

  Future<Pagina<Sancion>> listar({
    int pagina = 1,
    int tamano = ServicioBase.tamanoPagina,
    String conductor = '',
    String? estado,
  }) {
    return paginar(
      _ruta,
      Sancion.fromJson,
      pagina: pagina,
      tamano: tamano,
      filtros: {'conductor': conductor, 'estado': ?estado},
    );
  }

  Future<Map<String, Sancion>> vigentesPorConductor() async {
    final pagina = await listar(
      tamano: ServicioBase.tamanoMaximo,
      estado: EstadoSancion.activa,
    );
    return {
      for (final sancion in pagina.items.where((s) => s.vigente))
        sancion.identificacionConductor: sancion,
    };
  }

  Future<List<Sancion>> historial(String identificacionConductor) async {
    final pagina = await listar(
      tamano: ServicioBase.tamanoMaximo,
      conductor: identificacionConductor,
    );
    return pagina.items
        .where((s) => s.identificacionConductor == identificacionConductor)
        .toList();
  }

  Future<Sancion> obtenerPorId(int id) =>
      obtener('$_ruta/$id', Sancion.fromJson);

  Future<Sancion> registrar({
    required String identificacionConductor,
    required String motivo,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) {
    return crear(_ruta, {
      'identificacionConductor': identificacionConductor,
      'motivo': motivo,
      'fechaInicio': Fechas.api(fechaInicio),
      'fechaFin': Fechas.api(fechaFin),
    }, Sancion.fromJson);
  }

  Future<Sancion> anular(Sancion sancion) {
    return actualizar('$_ruta/${sancion.id}', {
      'motivo': sancion.motivoCompleto,
      'fechaInicio': Fechas.api(sancion.fechaInicio),
      'fechaFin': Fechas.api(sancion.fechaFin),
      'estado': EstadoSancion.anulada,
    }, Sancion.fromJson);
  }
}
