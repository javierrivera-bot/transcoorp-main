import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/routes/app_routes.dart';
import 'package:transcoorp/screens/inicio/dashboard_screen.dart';
import 'package:transcoorp/screens/mi_cuenta/inicio_asociado_screen.dart';
import 'package:transcoorp/screens/mi_cuenta/mis_vehiculos_screen.dart';
import 'package:transcoorp/screens/mi_cuenta/mis_viajes_screen.dart';
import 'package:transcoorp/screens/perfil/perfil_screen.dart';
import 'package:transcoorp/screens/planillas/listado_planillas_screen.dart';
import 'package:transcoorp/screens/vehiculos/listado_vehiculos_screen.dart';
import 'package:transcoorp/services/local/gestor_sesion.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/marco_pantalla.dart';

class _Pestana {
  const _Pestana(this.icono, this.iconoActivo, this.texto);

  final IconData icono;
  final IconData iconoActivo;
  final String texto;
}

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  int _indice = 0;
  final Set<int> _visitadas = {0};

  static const _pestanasAdministrativas = [
    _Pestana(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Inicio'),
    _Pestana(Icons.directions_bus_outlined, Icons.directions_bus, 'Vehículos'),
    _Pestana(Icons.description_outlined, Icons.description, 'Planillas'),
    _Pestana(Icons.person_outline, Icons.person, 'Perfil'),
  ];

  static const _pestanasAsociado = [
    _Pestana(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Inicio'),
    _Pestana(Icons.directions_car_outlined, Icons.directions_car, 'Mis vehículos'),
    _Pestana(Icons.route_outlined, Icons.route, 'Viajes'),
    _Pestana(Icons.person_outline, Icons.person, 'Perfil'),
  ];

  @override
  void initState() {
    super.initState();
    if (GestorSesion.actual == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (ruta) => false,
        );
      });
    }
  }

  void _irA(int indice) {
    setState(() {
      _indice = indice;
      _visitadas.add(indice);
    });
  }

  List<Widget> _paginas(bool esAsociado) {
    void alVolver() => _irA(0);
    if (esAsociado) {
      return [
        InicioAsociadoScreen(alCambiarPestana: _irA),
        MisVehiculosScreen(alVolver: alVolver),
        MisViajesScreen(alVolver: alVolver),
        PerfilScreen(alVolver: alVolver),
      ];
    }
    return [
      DashboardScreen(alCambiarPestana: _irA),
      ListadoVehiculosScreen(alVolver: alVolver),
      ListadoPlanillasScreen(alVolver: alVolver),
      PerfilScreen(alVolver: alVolver),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sesion = GestorSesion.actual;
    if (sesion == null) {
      return Scaffold(backgroundColor: context.colores.fondo);
    }

    final paginas = _paginas(sesion.esAsociado);
    final pestanas = sesion.esAsociado
        ? _pestanasAsociado
        : _pestanasAdministrativas;

    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          for (var i = 0; i < paginas.length; i++)
            _visitadas.contains(i) ? paginas[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _BarraNavegacion(
        pestanas: pestanas,
        indice: _indice,
        alSeleccionar: _irA,
      ),
    );
  }
}

class _BarraNavegacion extends StatelessWidget {
  const _BarraNavegacion({
    required this.pestanas,
    required this.indice,
    required this.alSeleccionar,
  });

  final List<_Pestana> pestanas;
  final int indice;
  final ValueChanged<int> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      decoration: BoxDecoration(
        color: c.superficie,
        border: Border(top: BorderSide(color: c.bordeTarjeta)),
      ),
      child: SafeArea(
        top: false,
        child: ContenidoCentrado(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                for (var i = 0; i < pestanas.length; i++)
                  Expanded(
                    child: _ItemNavegacion(
                      pestana: pestanas[i],
                      activo: i == indice,
                      alTocar: () => alSeleccionar(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemNavegacion extends StatelessWidget {
  const _ItemNavegacion({
    required this.pestana,
    required this.activo,
    required this.alTocar,
  });

  final _Pestana pestana;
  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final color = activo ? c.primarioOscuro : c.textoGris;

    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              decoration: BoxDecoration(
                color: activo ? c.badgeFondo : Colors.transparent,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Icon(
                activo ? pestana.iconoActivo : pestana.icono,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pestana.texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.inter(
                size: 11,
                weight: activo ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
