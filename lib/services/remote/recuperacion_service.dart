
class RecuperacionService {
  
  static const bool simulado = true;

  
  static const String codigoDemostracion = '123456';

  static const Duration _espera = Duration(milliseconds: 700);

  Future<void> enviarCodigo(String correo) async {
    await Future<void>.delayed(_espera);
  }

  Future<bool> verificarCodigo(String correo, String codigo) async {
    await Future<void>.delayed(_espera);
    return codigo == codigoDemostracion;
  }

  Future<void> restablecerContrasena(String correo, String nuevaPassword) async {
    await Future<void>.delayed(_espera);
  }
}
