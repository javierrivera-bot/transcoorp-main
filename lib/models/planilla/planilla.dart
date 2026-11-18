import 'package:transcoorp/models/comun/json.dart';

abstract final class EstadoPlanilla {
  static const activa = 'ACTIVA';
  static const finalizada = 'FINALIZADA';
  static const anulada = 'ANULADA';
}

abstract final class TipoPlanilla {
  static const viaje = 'VIAJE';
  static const despacho = 'DESPACHO';
  static const especial = 'ESPECIAL';

  static const valores = [viaje, despacho, especial];

  static String etiqueta(String tipo) => switch (tipo) {
    viaje => 'Viaje',
    despacho => 'Despacho',
    especial => 'Especial',
    _ => tipo,
  };
}

class Planilla {
  const Planilla({
    required this.numero,
    required this.placaVehiculo,
    required this.tipo,
    required this.estado,
    required this.estadoPago,
    this.fecha,
    this.hora,
    this.identificacionConductor,
    this.nombreConductor,
    this.registradoPor,
    this.tarifaId,
    this.fechaRegistro,
    this.valorPagado = 0,
    this.fechaPago,
    this.registradoPorPago,
  });

  final int numero;
  final String placaVehiculo;
  final String tipo;
  final String estado;
  final String estadoPago;
  final DateTime? fecha;
  final String? hora;
  final String? identificacionConductor;
  final String? nombreConductor;
  final String? registradoPor;
  final int? tarifaId;
  final DateTime? fechaRegistro;
  final double valorPagado;
  final DateTime? fechaPago;
  final String? registradoPorPago;

  factory Planilla.fromJson(Map<String, dynamic> json) {
    final conductor = Json.objeto(json, 'conductor');
    return Planilla(
      numero: Json.entero(json, 'numero'),
      placaVehiculo: Json.texto(json, 'placaVehiculo'),
      tipo: Json.texto(json, 'tipo'),
      estado: Json.texto(json, 'estado'),
      estadoPago: Json.texto(json, 'estadoPago'),
      fecha: Json.fecha(json, 'fecha'),
      hora: Json.textoONulo(json, 'hora'),
      identificacionConductor:
          Json.textoONulo(conductor, 'Identificacion') ??
          Json.textoONulo(conductor, 'identificacion'),
      nombreConductor:
          Json.textoONulo(conductor, 'Nombre del conductor') ??
          Json.textoONulo(conductor, 'nombreDelConductor') ??
          Json.textoONulo(conductor, 'nombres'),
      registradoPor: Json.textoONulo(json, 'registradoPor'),
      tarifaId: Json.enteroONulo(json, 'tarifaId'),
      fechaRegistro: Json.fecha(json, 'fechaRegistro'),
      valorPagado: Json.decimal(json, 'valorPagado'),
      fechaPago: Json.fecha(json, 'fechaPago'),
      registradoPorPago: Json.textoONulo(json, 'registradoPorPago'),
    );
  }

  bool get anulada => estado == EstadoPlanilla.anulada;

  bool get pagada => estadoPago == 'PAGADA';

  String get codigo => 'PL-${numero.toString().padLeft(5, '0')}';
}

class RechazoPlanilla {
  const RechazoPlanilla({required this.placa, required this.motivo});

  final String placa;
  final String motivo;

  factory RechazoPlanilla.fromJson(Map<String, dynamic> json) =>
      RechazoPlanilla(
        placa: Json.texto(json, 'placaVehiculo'),
        motivo: Json.texto(json, 'motivo'),
      );
}

class ResultadoPlanillaMasiva {
  const ResultadoPlanillaMasiva({
    required this.totalSolicitadas,
    required this.totalRegistradas,
    required this.correctas,
    required this.rechazadas,
  });

  final int totalSolicitadas;
  final int totalRegistradas;
  final List<Planilla> correctas;
  final List<RechazoPlanilla> rechazadas;

  factory ResultadoPlanillaMasiva.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> lista(String clave) {
      final valor = json[clave];
      return valor is List
          ? valor.whereType<Map<String, dynamic>>().toList()
          : const [];
    }

    return ResultadoPlanillaMasiva(
      totalSolicitadas: Json.entero(json, 'totalSolicitadas'),
      totalRegistradas: Json.entero(json, 'totalRegistradas'),
      correctas: lista('correctas').map(Planilla.fromJson).toList(),
      rechazadas: lista('rechazadas').map(RechazoPlanilla.fromJson).toList(),
    );
  }
}

class Pago {
  const Pago({
    required this.id,
    required this.numeroPlanilla,
    required this.valorPagado,
    this.fechaPago,
    this.registradoPor,
    this.fechaRegistro,
  });

  final int id;
  final int numeroPlanilla;
  final double valorPagado;
  final DateTime? fechaPago;
  final String? registradoPor;
  final DateTime? fechaRegistro;

  factory Pago.fromJson(Map<String, dynamic> json) => Pago(
    id: Json.entero(json, 'id'),
    numeroPlanilla: Json.entero(json, 'numeroPlanilla'),
    valorPagado: Json.decimal(json, 'valorPagado'),
    fechaPago: Json.fecha(json, 'fechaPago'),
    registradoPor: Json.textoONulo(json, 'registradoPor'),
    fechaRegistro: Json.fecha(json, 'fechaRegistro'),
  );
}
