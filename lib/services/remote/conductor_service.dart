import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/conductor/conductor.dart';
import 'package:transcoorp/services/remote/servicio_base.dart';

class DatosConductor {
  const DatosConductor({
    required this.identificacion,
    required this.nombres,
    required this.fechaNacimiento,
    required this.activo,
    required this.numeroLicencia,
    required this.categoriaLicencia,
    required this.vigenciaLicencia,
    required this.celular,
    required this.correo,
  });

  final String identificacion;
  final String nombres;
  final DateTime fechaNacimiento;
  final bool activo;
  final String numeroLicencia;
  final String categoriaLicencia;
  final DateTime vigenciaLicencia;
  final String celular;
  final String correo;

  Map<String, dynamic> toJson({bool incluirIdentificacion = true}) => {
    if (incluirIdentificacion) 'identificacion': identificacion,
    'nombres': nombres,
    'fechaNacimiento': Fechas.api(fechaNacimiento),
    'activo': activo,
    'numeroLicencia': numeroLicencia,
    'categoriaLicencia': categoriaLicencia,
    'vigenciaLicencia': Fechas.api(vigenciaLicencia),
    'celular': celular,
    'correo': correo,
  };
}

class ConductorService extends ServicioBase {
  static const _ruta = '/api/conductores';

  Future<Pagina<Conductor>> listar({
    int pagina = 1,
    int tamano = ServicioBase.tamanoPagina,
    String nombres = '',
    bool? activo,
  }) {
    return paginar(
      _ruta,
      Conductor.fromJson,
      pagina: pagina,
      tamano: tamano,
      filtros: {'nombres': nombres, if (activo != null) 'activo': '$activo'},
    );
  }

  Future<List<Conductor>> todos({bool soloActivos = true}) async {
    final pagina = await listar(
      tamano: ServicioBase.tamanoMaximo,
      activo: soloActivos ? true : null,
    );
    return pagina.items;
  }

  Future<Conductor> obtenerPorId(String identificacion) => obtener(
    '$_ruta/${Uri.encodeComponent(identificacion)}',
    Conductor.fromJson,
  );

  Future<Conductor> registrar(DatosConductor datos) =>
      crear(_ruta, datos.toJson(), Conductor.fromJson);

  Future<Conductor> editar(DatosConductor datos) => actualizar(
    '$_ruta/${Uri.encodeComponent(datos.identificacion)}',
    datos.toJson(incluirIdentificacion: false),
    Conductor.fromJson,
  );

  Future<int> total() => contar(_ruta, filtros: const {'activo': 'true'});
}
