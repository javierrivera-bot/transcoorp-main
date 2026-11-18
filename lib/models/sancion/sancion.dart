import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/comun/json.dart';

enum EstadoSancionVista { programada, vigente, finalizada, anulada }

abstract final class EstadoSancion {
  static const activa = 'ACTIVA';
  static const cumplida = 'CUMPLIDA';
  static const anulada = 'ANULADA';
}

class Sancion {
  const Sancion({
    required this.id,
    required this.identificacionConductor,
    required this.nombresConductor,
    required this.motivoCompleto,
    required this.estado,
    required this.fechaInicio,
    required this.fechaFin,
    this.registradoPor,
    this.fechaRegistro,
    this.ultimaActualizacion,
  });

  static const separadorObservaciones = '\n\nObservaciones: ';

  final int id;
  final String identificacionConductor;
  final String nombresConductor;
  final String motivoCompleto;
  final String estado;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? registradoPor;
  final DateTime? fechaRegistro;
  final DateTime? ultimaActualizacion;

  factory Sancion.fromJson(Map<String, dynamic> json) => Sancion(
    id: Json.entero(json, 'id'),
    identificacionConductor: Json.texto(json, 'identificacionConductor'),
    nombresConductor: Json.texto(json, 'nombresConductor'),
    motivoCompleto: Json.texto(json, 'motivo'),
    estado: Json.texto(json, 'estado'),
    fechaInicio: Json.fecha(json, 'fechaInicio') ?? Fechas.hoy,
    fechaFin: Json.fecha(json, 'fechaFin') ?? Fechas.hoy,
    registradoPor: Json.textoONulo(json, 'registradoPor'),
    fechaRegistro: Json.fecha(json, 'fechaRegistro'),
    ultimaActualizacion: Json.fecha(json, 'ultimaFechaActualizacion'),
  );

  static String componerMotivo(String motivo, String observaciones) {
    final extra = observaciones.trim();
    if (extra.isEmpty) return motivo.trim();
    return '${motivo.trim()}$separadorObservaciones$extra';
  }

  String get motivo => motivoCompleto.split(separadorObservaciones).first;

  String? get observaciones {
    final partes = motivoCompleto.split(separadorObservaciones);
    return partes.length > 1 ? partes.sublist(1).join(' ') : null;
  }

  EstadoSancionVista get estadoVista {
    if (estado == EstadoSancion.anulada) return EstadoSancionVista.anulada;
    if (estado == EstadoSancion.cumplida) return EstadoSancionVista.finalizada;
    final hoy = Fechas.hoy;
    if (hoy.isBefore(Fechas.soloFecha(fechaInicio))) {
      return EstadoSancionVista.programada;
    }
    if (hoy.isAfter(Fechas.soloFecha(fechaFin))) {
      return EstadoSancionVista.finalizada;
    }
    return EstadoSancionVista.vigente;
  }

  bool get vigente => estadoVista == EstadoSancionVista.vigente;

  int get duracionDias =>
      Fechas.soloFecha(fechaFin).difference(Fechas.soloFecha(fechaInicio)).inDays + 1;
}
