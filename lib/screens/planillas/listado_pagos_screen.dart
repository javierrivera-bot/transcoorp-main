import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/planilla/planilla.dart';
import 'package:transcoorp/screens/planillas/registro_pago_sheet.dart';
import 'package:transcoorp/services/remote/planilla_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/filtros.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';
import 'package:transcoorp/widgets/vista_paginada.dart';

class ListadoPagosScreen extends StatefulWidget {
  const ListadoPagosScreen({super.key});

  @override
  State<ListadoPagosScreen> createState() => _ListadoPagosScreenState();
}

class _ListadoPagosScreenState extends State<ListadoPagosScreen> {
  final PlanillaService _servicio = PlanillaService();
  late final ControladorPaginado<Pago> _controlador = ControladorPaginado(_cargar);

  String _numero = '';
  DateTime? _desde;
  DateTime? _hasta;

  @override
  void initState() {
    super.initState();
    _controlador.recargar();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<Pagina<Pago>> _cargar(int pagina) => _servicio.listarPagos(
    pagina: pagina,
    numeroPlanilla: _numero,
    desde: _desde,
    hasta: _hasta,
  );

  Future<void> _registrar() async {
    final pago = await mostrarRegistroPago(context);
    if (pago == null || !mounted) return;
    mostrarExito(
      context,
      'Pago de ${Formato.moneda(pago.valorPagado)} registrado para la planilla ${pago.numeroPlanilla}.',
    );
    _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Pagos de planillas',
        subtitulo: 'Recaudo registrado por planilla',
        acciones: [
          AccionEncabezado(
            icono: Icons.add_card,
            tooltip: 'Registrar pago',
            alPresionar: _registrar,
          ),
        ],
      ),
      body: PantallaLista(
        filtros: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoBusqueda(
              hint: 'Buscar por número de planilla',
              teclado: TextInputType.number,
              alBuscar: (texto) {
                _numero = texto.replaceAll(RegExp(r'\D'), '');
                _controlador.recargar();
              },
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FiltroFecha(
                    etiqueta: 'Desde',
                    valor: _desde,
                    alCambiar: (fecha) {
                      setState(() => _desde = fecha);
                      _controlador.recargar();
                    },
                  ),
                  const SizedBox(width: 8),
                  FiltroFecha(
                    etiqueta: 'Hasta',
                    valor: _hasta,
                    alCambiar: (fecha) {
                      setState(() => _hasta = fecha);
                      _controlador.recargar();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        lista: VistaPaginada<Pago>(
          controlador: _controlador,
          constructor: (context, pago) => _TarjetaPago(pago: pago),
          vacio: EstadoVacio(
            icono: Icons.receipt_long_outlined,
            titulo: 'Sin pagos registrados',
            mensaje: 'Los pagos de planillas aparecerán en esta sección.',
            textoAccion: 'Registrar pago',
            alAccion: _registrar,
          ),
        ),
      ),
    );
  }
}

class _TarjetaPago extends StatelessWidget {
  const _TarjetaPago({required this.pago});

  final Pago pago;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return TarjetaBase(
      child: Row(
        children: [
          IconoCaja(
            icono: Icons.paid_outlined,
            tamano: 44,
            color: c.verdeOscuro,
            fondo: c.verde.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planilla PL-${pago.numeroPlanilla.toString().padLeft(5, '0')}',
                  style: AppTheme.montserrat(
                    size: 14.5,
                    weight: FontWeight.w600,
                    color: c.textoOscuro,
                  ),
                ),
                Text(
                  'Pagada el ${Fechas.corta(pago.fechaPago)}${pago.registradoPor == null ? '' : ' · ${pago.registradoPor}'}',
                  style: AppTheme.inter(size: 12, color: c.textoSutil),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formato.moneda(pago.valorPagado),
                style: AppTheme.montserrat(
                  size: 15,
                  weight: FontWeight.w700,
                  color: c.primarioOscuro,
                ),
              ),
              const SizedBox(height: 4),
              const ChipEstado(texto: 'Pagado', tono: TonoEstado.exito),
            ],
          ),
        ],
      ),
    );
  }
}
