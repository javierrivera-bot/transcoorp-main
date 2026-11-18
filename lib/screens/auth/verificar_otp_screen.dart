import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/auth.dart';
import 'package:transcoorp/models/login/nueva_contrasena_args.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/recuperacion_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/boton_principal.dart';
import 'package:transcoorp/widgets/encabezado_seguridad.dart';

class VerificarOtpScreen extends StatefulWidget {
  const VerificarOtpScreen({super.key, required this.correo});

  final String correo;

  @override
  State<VerificarOtpScreen> createState() => _VerificarOtpScreenState();
}

class _VerificarOtpScreenState extends State<VerificarOtpScreen> {
  static const int _longitud = 6;
  static const int _duracionSegundos = 300;

  ColoresApp get _c => context.colores;

  void _arrancarTemporizador() {
    _temporizador?.cancel();
    _segundos = _duracionSegundos;
    _temporizador = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _segundos--;
      });
      if (_segundos <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> verificarCodigo() async {
    final error = Auth.validarOtp(_codigo);
    if (error != null) {
      setState(() => _errorCodigo = error);
      return;
    }
    if (_segundos <= 0) {
      setState(() => _errorCodigo = 'El código expiró. Solicita uno nuevo.');
      return;
    }

    setState(() => _cargando = true);

    try {
      final valido = await _servicio.verificarCodigo(widget.correo, _codigo);
      if (!mounted) return;
      if (!valido) {
        setState(() {
          _errorCodigo = 'El código no es correcto. Revísalo e intenta de nuevo.';
        });
        return;
      }
      Navigator.pushNamed(
        context,
        AppRoutes.nuevaContrasena,
        arguments: NuevaContrasenaArgs(correo: widget.correo),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorCodigo = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> reenviarCodigo() async {
    setState(() {
      _cargando = true;
      _errorCodigo = null;
    });

    try {
      await _servicio.enviarCodigo(widget.correo);
      if (!mounted) return;
      for (final controlador in _controladores) {
        controlador.clear();
      }
      _focos.first.requestFocus();
      setState(_arrancarTemporizador);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorCodigo = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void alCambiarCaja(int indice, String valor) {
    if (valor.isNotEmpty && indice < _longitud - 1) {
      _focos[indice + 1].requestFocus();
    }
    setState(() {
      _errorCodigo = null;
    });
  }

  int _segundos = _duracionSegundos;
  bool _cargando = false;
  String? _errorCodigo;
  Timer? _temporizador;

  final RecuperacionService _servicio = RecuperacionService();

  final List<TextEditingController> _controladores = List.generate(
    _longitud,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focos = List.generate(_longitud, (_) => FocusNode());

  String get _codigo => _controladores.map((c) => c.text).join();

  String get _tiempo {
    final minutos = (_segundos ~/ 60).toString().padLeft(2, '0');
    final segundos = (_segundos % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  @override
  void initState() {
    super.initState();
    _arrancarTemporizador();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    for (final controlador in _controladores) {
      controlador.dispose();
    }
    for (final foco in _focos) {
      foco.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c.fondo,
      appBar: const EncabezadoSeguridad(titulo: 'Verificar código'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 402),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'Ingresa el código de 6 dígitos que enviamos a ',
                      style: AppTheme.inter(
                        size: 14,
                        color: _c.textoSecundario,
                      ),
                      children: [
                        TextSpan(
                          text: Auth.enmascararCorreo(widget.correo),
                          style: AppTheme.inter(
                            size: 14,
                            weight: FontWeight.w600,
                            color: _c.textoTitulo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _tarjeta(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjeta() {
    final vigente = _segundos > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _c.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _c.bordeTarjeta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_longitud, _caja),
          ),
          if (_errorCodigo != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorCodigo!,
              textAlign: TextAlign.center,
              style: AppTheme.inter(size: 12, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            vigente ? 'El código expira en $_tiempo' : 'El código expiró',
            textAlign: TextAlign.center,
            style: AppTheme.inter(
              size: 12,
              weight: FontWeight.w600,
              color: vigente ? _c.textoSecundario : Colors.redAccent,
            ),
          ),
          if (RecuperacionService.simulado) ...[
            const SizedBox(height: 8),
            Text(
              'Modo demostración: el código es '
              '${RecuperacionService.codigoDemostracion}.',
              textAlign: TextAlign.center,
              style: AppTheme.inter(size: 12, color: _c.textoSecundario),
            ),
          ],
          const SizedBox(height: 20),
          BotonPrincipal(
            texto: 'Verificar código',
            alPresionar: verificarCodigo,
            cargando: _cargando,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _cargando ? null : reenviarCodigo,
            child: Text(
              'Reenviar código',
              style: AppTheme.inter(
                size: 14,
                weight: FontWeight.w600,
                color: _c.primario,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _caja(int indice) {
    OutlineInputBorder borde(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );

    return SizedBox(
      width: 44,
      height: 56,
      child: Focus(
        onKeyEvent: (nodo, evento) {
          if (evento is KeyDownEvent &&
              evento.logicalKey == LogicalKeyboardKey.backspace &&
              _controladores[indice].text.isEmpty &&
              indice > 0) {
            _controladores[indice - 1].clear();
            _focos[indice - 1].requestFocus();
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _controladores[indice],
          focusNode: _focos[indice],
          enabled: !_cargando,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (valor) => alCambiarCaja(indice, valor),
          style: AppTheme.montserrat(
            size: 20,
            weight: FontWeight.w700,
            color: _c.primarioOscuro,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '•',
            hintStyle: AppTheme.montserrat(
              size: 20,
              weight: FontWeight.w700,
              color: _c.hint,
            ),
            filled: true,
            fillColor: _c.fondo,
            contentPadding: EdgeInsets.zero,
            border: borde(_c.borde),
            enabledBorder: borde(_c.borde),
            disabledBorder: borde(_c.borde),
            focusedBorder: borde(_c.primario),
          ),
        ),
      ),
    );
  }
}