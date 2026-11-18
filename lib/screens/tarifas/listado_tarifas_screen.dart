import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/formatos.dart';
import 'package:transcoorp/models/comun/pagina.dart';
import 'package:transcoorp/models/tarifa/tarifa.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/tarifas/detalle_tarifa_screen.dart';
import 'package:transcoorp/screens/tarifas/formulario_tarifa_screen.dart';
import 'package:transcoorp/services/remote/tarifa_service.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/dialogos.dart';
import 'package:transcoorp/widgets/encabezado_modulo.dart';
import 'package:transcoorp/widgets/estados_vista.dart';
import 'package:transcoorp/widgets/filtros.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';
import 'package:transcoorp/widgets/vista_paginada.dart';

class ListadoTarifasScreen extends StatefulWidget {
  const ListadoTarifasScreen({super.key});

  @override
  State<ListadoTarifasScreen> createState() => _ListadoTarifasScreenState();
}

class _ListadoTarifasScreenState extends State<ListadoTarifasScreen> {
  final TarifaService _servicio = TarifaService();
  late final ControladorPaginado<Tarifa> _controlador =
      ControladorPaginado(_cargar);

  bool? _activo;

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

  Future<Pagina<Tarifa>> _cargar(int pagina) =>
      _servicio.listar(pagina: pagina, activo: _activo);

  Future<void> _registrar() async {
    final creada = await abrir<Tarifa>(context, const FormularioTarifaScreen());
    if (creada == null || !mounted) return;
    mostrarExito(context, '${creada.nombre} registrada por ${Formato.moneda(creada.total)}.');
    _controlador.recargar();
  }

  Future<void> _verDetalle(Tarifa tarifa) async {
    await abrir(context, DetalleTarifaScreen(tarifa: tarifa));
    if (mounted) _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Tarifas',
        subtitulo: 'Aportes y fondos regulados por asamblea',
        acciones: [
          AccionEncabezado(
            icono: Icons.add,
            tooltip: 'Registrar tarifa',
            alPresionar: _registrar,
          ),
        ],
      ),
      body: PantallaLista(
        filtros: BarraFiltros<bool?>(
          seleccionado: _activo,
          alCambiar: (valor) {
            setState(() => _activo = valor);
            _controlador.recargar();
          },
          opciones: const [
            OpcionFiltro(null, 'Todas'),
            OpcionFiltro(true, 'Activas'),
            OpcionFiltro(false, 'Inactivas'),
          ],
        ),
        lista: VistaPaginada<Tarifa>(
          controlador: _controlador,
          constructor: (context, tarifa) => _TarjetaTarifa(
            tarifa: tarifa,
            alTocar: () => _verDetalle(tarifa),
          ),
          vacio: EstadoVacio(
            icono: Icons.payments_outlined,
            titulo: 'Sin tarifas',
            mensaje: _activo == null
                ? 'Define la primera tarifa para generar planillas.'
                : 'No hay tarifas con el estado seleccionado.',
            textoAccion: 'Registrar tarifa',
            alAccion: _registrar,
          ),
        ),
      ),
    );
  }
}

class _TarjetaTarifa extends StatelessWidget {
  const _TarjetaTarifa({required this.tarifa, required this.alTocar});

  final Tarifa tarifa;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return TarjetaBase(
      alTocar: alTocar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconoCaja(icono: Icons.payments_outlined, tamano: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarifa.nombre,
                      style: AppTheme.montserrat(
                        size: 15,
                        weight: FontWeight.w600,
                        color: c.textoOscuro,
                      ),
                    ),
                    Text(
                      'Registrada el ${Fechas.corta(tarifa.fechaRegistro)}',
                      style: AppTheme.inter(size: 12, color: c.textoSutil),
                    ),
                  ],
                ),
              ),
              ChipEstado.activo(
                tarifa.activo,
                textoActivo: 'Activa',
                textoInactivo: 'Inactiva',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _componente(c, 'Aportes gastos varios', tarifa.aportesGastosVarios),
          _componente(c, 'Fondo de reposición', tarifa.fondoReposicion),
          _componente(c, 'Aporte social del socio', tarifa.aporteSocialSocio),
          Divider(height: 20, color: c.bordeTarjeta),
          Row(
            children: [
              Text(
                'Total',
                style: AppTheme.inter(
                  size: 13,
                  weight: FontWeight.w600,
                  color: c.textoGris,
                ),
              ),
              const Spacer(),
              Text(
                Formato.moneda(tarifa.total),
                style: AppTheme.montserrat(
                  size: 18,
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

  Widget _componente(ColoresApp c, String nombre, double valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(nombre, style: AppTheme.inter(size: 12.5, color: c.textoSutil)),
          const Spacer(),
          Text(
            Formato.moneda(valor),
            style: AppTheme.inter(
              size: 12.5,
              weight: FontWeight.w500,
              color: c.textoOscuro,
            ),
          ),
        ],
      ),
    );
  }
}
