import 'package:transcoorp/models/sesion/sesion.dart';
import 'package:transcoorp/services/local/secure_storage_service.dart';

abstract final class GestorSesion {
  static final SecureStorageService _almacen = SecureStorageService();

  static Sesion? _actual;

  static Sesion? get actual => _actual;

  static Future<void> iniciar(Sesion sesion, {required bool recordar}) async {
    _actual = sesion;
    if (recordar) {
      await _almacen.guardarSesion(sesion);
    } else {
      await _almacen.borrarSesion();
    }
  }

  static Future<Sesion?> restaurar() async {
    final sesion = await _almacen.leerSesion();
    if (sesion == null || !sesion.valida) {
      await _almacen.borrarSesion();
      _actual = null;
      return null;
    }
    _actual = sesion;
    return sesion;
  }

  static Future<void> reemplazarToken(Sesion nueva) async {
    final anterior = _actual;
    if (anterior == null) return;
    final sesion = Sesion(
      token: nueva.token,
      rol: nueva.rol.isEmpty ? anterior.rol : nueva.rol,
      username: nueva.username.isEmpty ? anterior.username : nueva.username,
      requiereCambioPassword: false,
      identificacion: nueva.identificacion ?? anterior.identificacion,
      empresa: nueva.empresa ?? anterior.empresa,
      expira: nueva.expira ?? anterior.expira,
    );
    final guardada = await _almacen.leerSesion();
    _actual = sesion;
    if (guardada != null) await _almacen.guardarSesion(sesion);
  }

  static Future<void> cerrar() async {
    _actual = null;
    await _almacen.borrarSesion();
  }
}
