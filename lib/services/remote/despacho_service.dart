import 'package:flutter/material.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/despacho/despacho.dart';
import 'package:transcoorp/services/remote/servicio_base.dart';

class DespachoService extends ServicioBase {
  static const _ruta = '/api/despachos';
  static const _rutaMisDespachos = '/api/mi-cuenta/despachos';

  Future<Pagina<Despacho>> listar({
    int pagina = 1,
    int tamano = ServicioBase.tamanoPagina,
    DateTime? fecha,
    String vehiculo = '',
    String ruta = '',
  }) {
    return paginar(
      _ruta,
      Despacho.fromJson,
      pagina: pagina,
      tamano: tamano,
      filtros: {
        if (fecha != null) 'fecha': Fechas.api(fecha),
        'vehiculo': vehiculo,
        'ruta': ruta,
      },
    );
  }

  Future<Despacho> obtenerPorId(int id) =>
      obtener('$_ruta/$id', Despacho.fromJson);

  Future<Despacho> registrar({
    required String ruta,
    required String placaVehiculo,
    required DateTime fecha,
    required TimeOfDay hora,
    required int numeroPasajeros,
  }) {
    return crear(_ruta, {
      'ruta': ruta,
      'placaVehiculo': placaVehiculo,
      'fecha': Fechas.api(fecha),
      'hora': Fechas.horaApi(hora),
      'numeroPasajeros': numeroPasajeros,
    }, Despacho.fromJson);
  }

  Future<void> cancelar(int id, String motivo) =>
      eliminar('$_ruta/$id', cuerpo: {'motivo': motivo});

  Future<Pagina<Despacho>> misDespachos({
    int pagina = 1,
    int tamano = ServicioBase.tamanoPagina,
    DateTime? desde,
    DateTime? hasta,
    String placa = '',
  }) {
    return paginar(
      _rutaMisDespachos,
      Despacho.fromJson,
      pagina: pagina,
      tamano: tamano,
      filtros: {
        if (desde != null) 'Desde': Fechas.api(desde),
        if (hasta != null) 'Hasta': Fechas.api(hasta),
        'Placa': placa,
      },
    );
  }
}
