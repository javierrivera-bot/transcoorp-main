class NuevaContrasenaArgs {
  const NuevaContrasenaArgs({
    this.token,
    this.correo,
    this.recordar = false,
    this.voluntario = false,
  });

  final String? token;
  final String? correo;
  final bool recordar;
  final bool voluntario;
}
