import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/services/remote/servicio_base.dart';

class DatosVehiculo {
  const DatosVehiculo({
    required this.placa,
    required this.identificacionConductor,
    required this.tipo,
    required this.marca,
    required this.modelo,
    required this.capacidadPasajeros,
    required this.tarjetaPropiedad,
    required this.tarifaId,
    required this.activo,
    required this.vigenciaSoat,
    required this.vigenciaTrm,
    required this.fechaIngreso,
  });

  final String placa;
  final String? identificacionConductor;
  final String tipo;
  final String marca;
  final String modelo;
  final int capacidadPasajeros;
  final String tarjetaPropiedad;
  final int tarifaId;
  final bool activo;
  final DateTime vigenciaSoat;
  final DateTime vigenciaTrm;
  final DateTime fechaIngreso;
}

class VehiculoService extends ServicioBase {
  static const _ruta = '/api/vehiculos';

  static const tipos = [
    'Camioneta',
    'Campero',
    'Buseta',
    'Microbús',
    'Furgón',
    'Chiva',
  ];

  Future<Pagina<Vehiculo>> listar({
    int pagina = 1,
    int tamano = ServicioBase.tamanoPagina,
    String placa = '',
    String tipo = '',
  }) {
    return paginar(
      _ruta,
      Vehiculo.fromJson,
      pagina: pagina,
      tamano: tamano,
      filtros: {'placa': placa, 'tipo': tipo},
    );
  }

  Future<List<Vehiculo>> todos({bool soloActivos = true}) async {
    final pagina = await listar(tamano: ServicioBase.tamanoMaximo);
    return soloActivos
        ? pagina.items.where((v) => v.activo).toList()
        : pagina.items;
  }

  Future<Vehiculo> obtenerPorPlaca(String placa) =>
      obtener('$_ruta/${Uri.encodeComponent(placa)}', Vehiculo.fromJson);

  Future<Vehiculo> registrar(DatosVehiculo datos) {
    return crear(_ruta, {
      'placa': datos.placa,
      'identificacionConductor': datos.identificacionConductor,
      'tipo': datos.tipo,
      'marca': datos.marca,
      'modelo': datos.modelo,
      'capacidadPasajeros': datos.capacidadPasajeros,
      'tarjetaPropiedad': datos.tarjetaPropiedad,
      'tarifaId': datos.tarifaId,
      'activo': datos.activo,
      'vigenciaSoat': Fechas.api(datos.vigenciaSoat),
      'vigenciaTrm': Fechas.api(datos.vigenciaTrm),
      'fechaIngreso': Fechas.api(datos.fechaIngreso),
    }, Vehiculo.fromJson);
  }

  Future<Vehiculo> editar(
    String placa, {
    required String? identificacionConductor,
    required int? tarifaId,
    required bool activo,
    required DateTime vigenciaSoat,
    required DateTime vigenciaTrm,
  }) {
    return actualizar('$_ruta/${Uri.encodeComponent(placa)}', {
      'identificacionConductor': identificacionConductor,
      'tarifaId': ?tarifaId,
      'activo': activo,
      'vigenciaSoat': Fechas.api(vigenciaSoat),
      'vigenciaTrm': Fechas.api(vigenciaTrm),
    }, Vehiculo.fromJson);
  }

  Future<int> total() => contar(_ruta);
}
