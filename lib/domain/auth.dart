class Auth {
  static String? validarUsuario(String usuario) {
    final valor = usuario.trim();
    if (valor.isEmpty) {
      return 'Ingresa tu usuario o cédula';
    }
    if (valor.contains(RegExp(r'\s'))) {
      return 'El usuario no puede tener espacios';
    }
    return null;
  }

  static String? validarContrasena(String contrasena) {
    if (contrasena.isEmpty) {
      return 'Ingresa tu contraseña';
    }
    if (contrasena.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  static String? validarCorreo(String correo) {
    final valor = correo.trim();
    if (valor.isEmpty) {
      return 'Ingresa tu correo institucional';
    }
    final esCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valor);
    if (!esCorreo) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  static String? validarOtp(String codigo) {
    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
      return 'Ingresa los 6 dígitos del código';
    }
    return null;
  }

  static String enmascararCorreo(String correo) {
    final partes = correo.trim().split('@');
    if (partes.length != 2 || partes[0].length < 2) {
      return correo;
    }
    final local = partes[0];
    return '${local[0]}***${local[local.length - 1]}@${partes[1]}';
  }

  static bool cumpleMinimo(String c) => c.length >= 12;
  static bool cumpleMayuscula(String c) => RegExp(r'[A-Z]').hasMatch(c);
  static bool cumpleMinuscula(String c) => RegExp(r'[a-z]').hasMatch(c);
  static bool cumpleMayusMinus(String c) =>
      cumpleMayuscula(c) && cumpleMinuscula(c);
  static bool cumpleNumero(String c) => RegExp(r'\d').hasMatch(c);

  static int nivelSeguridad(String c) {
    var nivel = 0;
    if (cumpleMinimo(c)) nivel++;
    if (cumpleMayusMinus(c)) nivel++;
    if (cumpleNumero(c)) nivel++;
    return nivel;
  }

  static String etiquetaSeguridad(int nivel) {
    if (nivel == 3) return 'Segura';
    if (nivel == 2) return 'Media';
    return 'Básica';
  }

  static String? validarNuevaContrasena(String c) {
    if (c.isEmpty) {
      return 'Ingresa tu nueva contraseña';
    }
    if (!cumpleMinimo(c) || !cumpleMayusMinus(c) || !cumpleNumero(c)) {
      return 'La contraseña no cumple los requisitos';
    }
    return null;
  }

  static String? validarConfirmacion(String c, String confirmacion) {
    if (confirmacion.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (c != confirmacion) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}
