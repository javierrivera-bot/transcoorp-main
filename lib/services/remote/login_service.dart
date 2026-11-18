import 'package:transcoorp/config/app_config.dart';
import 'package:transcoorp/models/login/cambiar_password_request.dart';
import 'package:transcoorp/models/login/login_request.dart';
import 'package:transcoorp/models/sesion/sesion.dart';
import 'package:transcoorp/services/remote/api_service.dart';

class LoginService {
  final ApiService _api = ApiService(baseUrl: AppConfig.apiBaseUrl);

  Future<Sesion> login(LoginRequest request) async {
    final respuesta = await _api.post('/api/auth/login', body: request.toJson());
    return _leer(respuesta);
  }

  Future<Sesion?> cambiarPassword(
    String token,
    CambiarPasswordRequest request,
  ) async {
    final respuesta = await _api.post(
      '/api/auth/cambiar-password',
      body: request.toJson(),
      headers: {'Authorization': 'Bearer $token'},
    );
    final sesion = Sesion.desdeLogin(respuesta);
    return sesion.token.isEmpty ? null : sesion;
  }

  Sesion _leer(dynamic respuesta) {
    final sesion = Sesion.desdeLogin(respuesta);
    if (sesion.token.isEmpty) {
      throw const ApiException('El servidor devolvió una respuesta inesperada.');
    }
    return sesion;
  }
}
