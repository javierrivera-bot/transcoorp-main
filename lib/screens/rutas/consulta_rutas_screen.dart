import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/domain/rutas.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/filtros.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';

class ConsultaRutasScreen extends StatefulWidget {
  const ConsultaRutasScreen({super.key});

  @override
  State<ConsultaRutasScreen> createState() => _ConsultaRutasScreenState();
}

class _ConsultaRutasScreenState extends State<ConsultaRutasScreen> {
  String _consulta = '';
  String? _origen;
  bool? _activa;

  List<String> get _origenes =>
      CatalogoRutas.rutas.map((r) => r.origen).toSet().toList()..sort();

  List<Ruta> get _visibles {
    final consulta = _consulta.toLowerCase();
    return CatalogoRutas.rutas.where((ruta) {
      final pasaOrigen = _origen == null || ruta.origen == _origen;
      final pasaEstado = _activa == null || ruta.activa == _activa;
      final pasaTexto =
          consulta.isEmpty ||
          ruta.destino.toLowerCase().contains(consulta) ||
          ruta.nombre.toLowerCase().contains(consulta) ||
          ruta.codigo.toLowerCase().contains(consulta);
      return pasaOrigen && pasaEstado && pasaTexto;
    }).toList();
  }

  void _limpiar() {
    setState(() {
      _origen = null;
      _activa = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final rutas = _visibles;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: const EncabezadoModulo(
        titulo: 'Consulta de rutas',
        subtitulo: 'Recorridos autorizados de la cooperativa',
      ),
      body: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            CampoBusqueda(
              hint: 'Buscar por destino, nombre o código',
              alBuscar: (texto) => setState(() => _consulta = texto),
            ),
            const SizedBox(height: 12),
            BarraFiltros<String?>(
              seleccionado: _origen,
              alCambiar: (valor) => setState(() => _origen = valor),
              opciones: [
                const OpcionFiltro(null, 'Todos los orígenes'),
                for (final origen in _origenes) OpcionFiltro(origen, origen),
              ],
            ),
            const SizedBox(height: 8),
            BarraFiltros<bool?>(
              seleccionado: _activa,
              alCambiar: (valor) => setState(() => _activa = valor),
              opciones: const [
                OpcionFiltro(null, 'Cualquier estado'),
                OpcionFiltro(true, 'Activas'),
                OpcionFiltro(false, 'Inactivas'),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Rutas disponibles (${rutas.length})',
              style: AppTheme.montserrat(
                size: 15,
                weight: FontWeight.w600,
                color: c.primarioOscuro,
              ),
            ),
            const SizedBox(height: 10),
            if (rutas.isEmpty)
              EstadoVacio(
                icono: Icons.alt_route,
                titulo: 'Sin rutas',
                mensaje: 'Ninguna ruta coincide con los filtros aplicados.',
                textoAccion: 'Limpiar filtros',
                iconoAccion: Icons.filter_alt_off_outlined,
                alAccion: _limpiar,
              )
            else
              for (final ruta in rutas) ...[
                _TarjetaRuta(ruta: ruta),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaRuta extends StatelessWidget {
  const _TarjetaRuta({required this.ruta});

  final Ruta ruta;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return TarjetaBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primario,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ruta.codigo,
                  style: AppTheme.montserrat(
                    size: 12,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ruta.nombre,
                  style: AppTheme.montserrat(
                    size: 15,
                    weight: FontWeight.w600,
                    color: c.textoOscuro,
                  ),
                ),
              ),
              ChipEstado.activo(
                ruta.activa,
                textoActivo: 'Activa',
                textoInactivo: 'Inactiva',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Column(
                children: [
                  Icon(Icons.trip_origin, size: 16, color: c.primario),
                  Container(width: 2, height: 22, color: c.borde),
                  Icon(Icons.location_on, size: 18, color: c.verdeOscuro),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _punto(c, 'Origen', ruta.origen, ruta.puntoOrigen),
                    const SizedBox(height: 10),
                    _punto(c, 'Destino', ruta.destino, ruta.puntoDestino),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: c.bordeTarjeta),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.schedule, size: 15, color: c.textoSutil),
              const SizedBox(width: 4),
              Text(
                '${ruta.duracion} · ${ruta.distanciaKm} km',
                style: AppTheme.inter(size: 12, color: c.textoSutil),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ruta.servicio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.inter(size: 12, color: c.textoSutil),
                ),
              ),
              Text(
                Formato.moneda(ruta.tarifa),
                style: AppTheme.montserrat(
                  size: 15,
                  weight: FontWeight.w700,
                  color: c.primarioOscuro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _punto(ColoresApp c, String etiqueta, String lugar, String punto) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$etiqueta: ',
            style: AppTheme.inter(size: 12, color: c.textoSutil),
          ),
          TextSpan(
            text: lugar,
            style: AppTheme.inter(
              size: 13.5,
              weight: FontWeight.w600,
              color: c.textoOscuro,
            ),
          ),
          TextSpan(
            text: ' ($punto)',
            style: AppTheme.inter(size: 12, color: c.textoSutil),
          ),
        ],
      ),
    );
  }
}
