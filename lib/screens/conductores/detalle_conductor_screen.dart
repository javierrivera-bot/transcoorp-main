import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/conductor/conductor.dart';
import 'package:transcoorp/models/sancion/sancion.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/conductores/formulario_conductor_screen.dart';
import 'package:transcoorp/screens/sanciones/detalle_sancion_screen.dart';
import 'package:transcoorp/screens/sanciones/formulario_sancion_screen.dart';
import 'package:transcoorp/screens/sanciones/listado_sanciones_screen.dart';
import 'package:transcoorp/services/local/gestor_sesion.dart';
import 'package:transcoorp/services/remote/api_service.dart';
import 'package:transcoorp/services/remote/conductor_service.dart';
import 'package:transcoorp/services/remote/sancion_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/barra_acciones.dart';
import 'package:transcoorp/widgets/boton_principal.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/seccion_detalle.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';

class DetalleConductorScreen extends StatefulWidget {
  const DetalleConductorScreen({super.key, required this.conductor});

  final Conductor conductor;

  @override
  State<DetalleConductorScreen> createState() => _DetalleConductorScreenState();
}

class _DetalleConductorScreenState extends State<DetalleConductorScreen> {
  final ConductorService _servicio = ConductorService();
  final SancionService _sanciones = SancionService();

  late Conductor _conductor = widget.conductor;
  List<Sancion>? _historial;
  String? _errorHistorial;

  Sancion? get _vigente {
    for (final sancion in _historial ?? const <Sancion>[]) {
      if (sancion.vigente) return sancion;
    }
    return null;
  }

  Sancion? get _programada {
    for (final sancion in _historial ?? const <Sancion>[]) {
      if (sancion.estadoVista == EstadoSancionVista.programada) return sancion;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  Future<void> _refrescar() async {
    try {
      final conductor = await _servicio.obtenerPorId(_conductor.identificacion);
      if (mounted) setState(() => _conductor = conductor);
    } on ApiException catch (_) {}
    await _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _errorHistorial = null);
    try {
      final historial = await _sanciones.historial(_conductor.identificacion);
      historial.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
      if (mounted) setState(() => _historial = historial);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorHistorial = e.message);
    }
  }

  Future<void> _editar() async {
    final actualizado = await abrir<Conductor>(
      context,
      FormularioConductorScreen(conductor: _conductor),
    );
    if (actualizado == null || !mounted) return;
    setState(() => _conductor = actualizado);
    mostrarExito(context, 'Datos del conductor actualizados.');
  }

  Future<void> _sancionar() async {
    final registrada = await abrir<Sancion>(
      context,
      FormularioSancionScreen(conductor: _conductor),
    );
    if (registrada == null || !mounted) return;
    mostrarExito(context, 'Sanción registrada para ${_conductor.nombres}.');
    _cargarHistorial();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final d = _conductor;
    final vigente = _vigente;
    final puedeSancionar = GestorSesion.actual?.puedeSancionar ?? false;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Perfil del conductor',
        subtitulo: 'C.C. ${d.identificacion}',
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: ContenidoCentrado(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (vigente != null) ...[
                Aviso(
                  titulo: 'Conductor sancionado',
                  mensaje:
                      'No disponible para trabajar hasta el ${Fechas.corta(vigente.fechaFin)}.\nMotivo: ${vigente.motivo}',
                  tono: TonoEstado.peligro,
                  icono: Icons.gavel,
                ),
                const SizedBox(height: 12),
              ] else if (_programada != null) ...[
                Aviso(
                  titulo: 'Sanción programada',
                  mensaje:
                      'Del ${Fechas.corta(_programada!.fechaInicio)} al ${Fechas.corta(_programada!.fechaFin)}.',
                  tono: TonoEstado.alerta,
                  icono: Icons.schedule,
                ),
                const SizedBox(height: 12),
              ],
              _cabecera(c, d, vigente),
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Información personal',
                icono: Icons.person_outline,
                children: [
                  FilaDato(
                    icono: Icons.badge_outlined,
                    etiqueta: 'Identificación',
                    valor: d.identificacion,
                  ),
                  FilaDato(
                    icono: Icons.cake_outlined,
                    etiqueta: 'Fecha de nacimiento',
                    valor: Fechas.corta(d.fechaNacimiento),
                  ),
                  FilaDato(
                    icono: Icons.phone_outlined,
                    etiqueta: 'Celular',
                    valor: Formato.valorO(d.celular),
                  ),
                  FilaDato(
                    icono: Icons.mail_outline,
                    etiqueta: 'Correo electrónico',
                    valor: Formato.valorO(d.correo),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Datos de licencia',
                icono: Icons.credit_card,
                etiqueta: ChipEstado(
                  texto: d.licenciaVencida ? 'Vencida' : 'Vigente',
                  tono: d.licenciaVencida ? TonoEstado.alerta : TonoEstado.exito,
                ),
                children: [
                  FilaDato(
                    etiqueta: 'Número de licencia',
                    valor: Formato.valorO(d.numeroLicencia),
                    destacado: true,
                  ),
                  GrillaDatos(
                    datos: [
                      FilaDato(
                        etiqueta: 'Categoría',
                        valor: Formato.valorO(d.categoriaLicencia),
                        destacado: true,
                      ),
                      FilaDato(
                        etiqueta: 'Vigencia',
                        valor: Fechas.corta(d.vigenciaLicencia),
                        destacado: true,
                      ),
                    ],
                  ),
                  if (d.licenciaVencida)
                    const Aviso(
                      titulo: 'Licencia vencida',
                      mensaje:
                          'Actualiza la vigencia antes de asignarlo a un vehículo.',
                      tono: TonoEstado.alerta,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _seccionSanciones(c),
              const SizedBox(height: 16),
              PieTrazabilidad(
                registro: Fechas.corta(d.fechaRegistro),
                actualizacion: Fechas.corta(
                  d.ultimaActualizacion ?? d.fechaRegistro,
                ),
              ),
              if (puedeSancionar) ...[
                const SizedBox(height: 20),
                BotonSecundario(
                  texto: vigente == null
                      ? 'Aplicar nueva sanción'
                      : 'Ya tiene una sanción vigente',
                  icono: Icons.gavel,
                  peligro: true,
                  alPresionar: vigente == null ? _sancionar : null,
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: PieAcciones(
        children: [
          BotonSecundario(
            texto: 'Historial',
            icono: Icons.history,
            alPresionar: () => abrir(
              context,
              ListadoSancionesScreen(conductor: d.identificacion),
            ),
          ),
          BotonPrincipal(texto: 'Editar', alPresionar: _editar),
        ],
      ),
    );
  }

  Widget _cabecera(ColoresApp c, Conductor d, Sancion? vigente) {
    return TarjetaBase(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarIniciales(texto: d.iniciales, tamano: 62),
              if (vigente != null)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.rojoAlerta,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.block, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ChipEstado.activo(d.activo),
                    if (vigente != null)
                      const ChipEstado(
                        texto: 'Sancionado',
                        tono: TonoEstado.peligro,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  d.nombres,
                  style: AppTheme.montserrat(
                    size: 18,
                    weight: FontWeight.w700,
                    color: c.textoOscuro,
                  ),
                ),
                Text(
                  vigente == null && d.activo && !d.licenciaVencida
                      ? 'Disponible para operar'
                      : 'No disponible para asignaciones',
                  style: AppTheme.inter(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: vigente == null && d.activo && !d.licenciaVencida
                        ? c.verdeOscuro
                        : AppColors.rojoAlerta,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionSanciones(ColoresApp c) {
    final historial = _historial;
    final List<Widget> contenido;

    if (_errorHistorial != null) {
      contenido = [
        Text(
          _errorHistorial!,
          style: AppTheme.inter(size: 13, color: AppColors.rojoAlerta),
        ),
        TextButton.icon(
          onPressed: _cargarHistorial,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Reintentar'),
        ),
      ];
    } else if (historial == null) {
      contenido = const [
        Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      ];
    } else if (historial.isEmpty) {
      contenido = [
        Text(
          'Sin sanciones registradas.',
          style: AppTheme.inter(size: 13, color: c.textoSecundario),
        ),
      ];
    } else {
      contenido = [
        for (final sancion in historial.take(3))
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await abrir(context, DetalleSancionScreen(sancion: sancion));
              if (mounted) _cargarHistorial();
            },
            child: FilaDato(
              icono: Icons.gavel_outlined,
              etiqueta:
                  '${Fechas.corta(sancion.fechaInicio)} — ${Fechas.corta(sancion.fechaFin)}',
              valor: sancion.motivo,
              complemento: ChipSancion(sancion: sancion),
            ),
          ),
      ];
    }

    return SeccionDetalle(
      titulo: 'Sanciones',
      icono: Icons.gavel_outlined,
      etiqueta: historial != null && historial.length > 3
          ? Text(
              '${historial.length} en total',
              style: AppTheme.inter(size: 12, color: c.textoSutil),
            )
          : null,
      children: contenido,
    );
  }
}
