import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/comun/json.dart';

class Vehiculo {
  const Vehiculo({
    required this.placa,
    required this.activo,
    this.identificacionConductor,
    this.tipo,
    this.marca,
    this.modelo,
    this.capacidadPasajeros = 0,
    this.tarjetaPropiedad,
    this.tarifaId,
    this.tarifaTotal,
    this.vigenciaSoat,
    this.vigenciaTrm,
    this.fechaIngreso,
    this.fechaRegistro,
    this.ultimaActualizacion,
  });

  final String placa;
  final bool activo;
  final String? identificacionConductor;
  final String? tipo;
  final String? marca;
  final String? modelo;
  final int capacidadPasajeros;
  final String? tarjetaPropiedad;
  final int? tarifaId;
  final double? tarifaTotal;
  final DateTime? vigenciaSoat;
  final DateTime? vigenciaTrm;
  final DateTime? fechaIngreso;
  final DateTime? fechaRegistro;
  final DateTime? ultimaActualizacion;

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    final tarifa = Json.objeto(json, 'tarifa');
    return Vehiculo(
      placa: Json.texto(json, 'placa'),
      activo: Json.booleano(json, 'activo'),
      identificacionConductor: Json.textoONulo(json, 'identificacionConductor'),
      tipo: Json.textoONulo(json, 'tipo'),
      marca: Json.textoONulo(json, 'marca'),
      modelo: Json.textoONulo(json, 'modelo'),
      capacidadPasajeros: Json.entero(json, 'capacidadPasajeros'),
      tarjetaPropiedad: Json.textoONulo(json, 'tarjetaPropiedad'),
      tarifaId: tarifa.isEmpty
          ? Json.enteroONulo(json, 'tarifaId')
          : Json.enteroONulo(tarifa, 'id'),
      tarifaTotal: tarifa.isEmpty ? null : Json.decimal(tarifa, 'total'),
      vigenciaSoat: Json.fecha(json, 'vigenciaSoat'),
      vigenciaTrm: Json.fecha(json, 'vigenciaTrm'),
      fechaIngreso: Json.fecha(json, 'fechaIngreso'),
      fechaRegistro: Json.fecha(json, 'fechaRegistro'),
      ultimaActualizacion: Json.fecha(json, 'ultimaFechaActualizacion'),
    );
  }

  String get descripcion {
    final partes = [marca, modelo].whereType<String>().join(' ');
    return partes.isEmpty ? 'Sin marca registrada' : partes;
  }

  bool get soatVencido => Fechas.vencida(vigenciaSoat);

  bool get trmVencida => Fechas.vencida(vigenciaTrm);

  bool get documentosAlDia => !soatVencido && !trmVencida;
}

class VehiculoAsociado {
  const VehiculoAsociado({
    required this.placa,
    required this.activo,
    this.identificacionConductor,
    this.tipo,
    this.marca,
    this.modelo,
    this.fechaAfiliacion,
  });

  final String placa;
  final bool activo;
  final String? identificacionConductor;
  final String? tipo;
  final String? marca;
  final String? modelo;
  final DateTime? fechaAfiliacion;

  factory VehiculoAsociado.fromJson(Map<String, dynamic> json) =>
      VehiculoAsociado(
        placa: Json.texto(json, 'placa'),
        activo: Json.booleano(json, 'activo'),
        identificacionConductor: Json.textoONulo(
          json,
          'identificacionConductor',
        ),
        tipo: Json.textoONulo(json, 'tipo'),
        marca: Json.textoONulo(json, 'marca'),
        modelo: Json.textoONulo(json, 'modelo'),
        fechaAfiliacion: Json.fecha(json, 'fechaAfiliacion'),
      );

  String get descripcion {
    final partes = [marca, modelo].whereType<String>().join(' ');
    return partes.isEmpty ? 'Sin marca registrada' : partes;
  }
}
