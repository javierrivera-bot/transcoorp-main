import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/comun/json.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/planilla/planilla.dart';
import 'package:transcoorp/services/remote/servicio_base.dart';

class PlanillaService extends ServicioBase {
  static const _ruta = '/api/planillas';
  static const _rutaPagos = '/api/pagos';

  Future<Pagina<Planilla>> listar({
    int pagina = 1,
    int tamano = ServicioBase.tamanoPagina,
    DateTime? fecha,
    String vehiculo = '',
    String? estado,
  }) {
    return paginar(
      _ruta,
      Planilla.fromJson,
      pagina: pagina,
      tamano: tamano,
      filtros: {
        if (fecha != null) 'fecha': Fechas.api(fecha),
        'vehiculo': vehiculo,
        'estado': ?estado,
      },
    );
  }

  Future<Planilla> obtenerPorNumero(int numero) =>
      obtener('$_ruta/$numero', Planilla.fromJson);

  Future<ResultadoPlanillaMasiva> generarMasivas({
    required DateTime fecha,
    required List<String> placas,
    required String tipo,
    required int? tarifaId,
  }) async {
    final respuesta = await api.post(
      '$_ruta/masivas',
      body: {
        'fecha': Fechas.api(fecha),
        'placasVehiculos': placas,
        'tipo': tipo,
        'tarifaId': tarifaId,
      },
      headers: cabeceras,
    );
    return ResultadoPlanillaMasiva.fromJson(Json.datos(respuesta));
  }

  Future<void> anular(int numero, String motivo) =>
      eliminar('$_ruta/$numero', cuerpo: {'motivo': motivo});

  Future<Pagina<Pago>> listarPagos({
    int pagina = 1,
    int tamano = ServicioBase.tamanoPagina,
    String numeroPlanilla = '',
    String placa = '',
    DateTime? desde,
    DateTime? hasta,
  }) {
    return paginar(
      _rutaPagos,
      Pago.fromJson,
      pagina: pagina,
      tamano: tamano,
      filtros: {
        'NumeroPlanilla': numeroPlanilla,
        'Placa': placa,
        if (desde != null) 'Desde': Fechas.api(desde),
        if (hasta != null) 'Hasta': Fechas.api(hasta),
      },
    );
  }

  Future<Pago> registrarPago({
    required int numeroPlanilla,
    required DateTime fechaPago,
  }) {
    return crear(_rutaPagos, {
      'numeroPlanilla': numeroPlanilla,
      'fechaPago': Fechas.api(fechaPago),
    }, Pago.fromJson);
  }
}
