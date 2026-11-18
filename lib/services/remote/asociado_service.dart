import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/models/asociado/asociado.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/services/remote/servicio_base.dart';

class AsociadoService extends ServicioBase {
  static const _ruta = '/api/asociados';

  Future<Pagina<Asociado>> listar({
    int pagina = 1,
    int tamano = ServicioBase.tamanoPagina,
    String nombres = '',
    bool? activo,
  }) {
    return paginar(
      _ruta,
      Asociado.fromJson,
      pagina: pagina,
      tamano: tamano,
      filtros: {'nombres': nombres, if (activo != null) 'activo': '$activo'},
    );
  }

  Future<Asociado> obtenerPorId(String identificacion) =>
      obtener('$_ruta/${Uri.encodeComponent(identificacion)}', Asociado.fromJson);

  Future<Asociado> registrar({
    required String identificacion,
    required String nombres,
    required bool activo,
    required String celular,
    required String correo,
    required DateTime fechaNacimiento,
    required DateTime fechaIngreso,
  }) {
    return crear(_ruta, {
      'identificacion': identificacion,
      'nombres': nombres,
      'activo': activo,
      'celular': celular,
      'correo': correo,
      'fechaNacimiento': Fechas.api(fechaNacimiento),
      'fechaIngreso': Fechas.api(fechaIngreso),
    }, Asociado.fromJson);
  }

  Future<Asociado> editar(
    String identificacion, {
    String? celular,
    String? correo,
    DateTime? fechaNacimiento,
    bool? activo,
  }) {
    return actualizar('$_ruta/${Uri.encodeComponent(identificacion)}', {
      'celular': ?celular,
      'correo': ?correo,
      if (fechaNacimiento != null) 'fechaNacimiento': Fechas.api(fechaNacimiento),
      'activo': ?activo,
    }, Asociado.fromJson);
  }

  Future<Asociado> desafiliar(String identificacion) =>
      editar(identificacion, activo: false);

  Future<Asociado> reactivar(String identificacion) =>
      editar(identificacion, activo: true);

  Future<CredencialTemporal> generarCredencial(String identificacion) => crear(
    '$_ruta/${Uri.encodeComponent(identificacion)}/credencial-temporal',
    const {},
    CredencialTemporal.fromJson,
  );

  Future<int> total() => contar(_ruta);
}
