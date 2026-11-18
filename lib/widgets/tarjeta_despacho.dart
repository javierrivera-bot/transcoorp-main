import 'package:flutter/material.dart';
import 'package:transcoorp/domain/app_theme.dart';
import 'package:transcoorp/domain/fechas.dart';
import 'package:transcoorp/domain/rutas.dart';
import 'package:transcoorp/models/despacho/despacho.dart';
import 'package:transcoorp/theme/colores_app.dart';
import 'package:transcoorp/widgets/chip_estado.dart';
import 'package:transcoorp/widgets/tarjeta_base.dart';

class TarjetaDespacho extends StatelessWidget {
  const TarjetaDespacho({super.key, required this.despacho, this.alTocar});

  final Despacho despacho;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final ruta = CatalogoRutas.buscar(despacho.ruta);

    return TarjetaBase(
      alTocar: alTocar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlacaVehiculo(placa: despacho.placaVehiculo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  despacho.codigo,
                  style: AppTheme.inter(
                    size: 12,
                    weight: FontWeight.w600,
                    color: c.textoSutil,
                  ),
                ),
              ),
              despacho.cancelado
                  ? const ChipEstado(texto: 'Cancelado', tono: TonoEstado.peligro)
                  : const ChipEstado(texto: 'Despachado', tono: TonoEstado.exito),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                children: [
                  Icon(Icons.trip_origin, size: 14, color: c.primario),
                  Container(width: 2, height: 16, color: c.borde),
                  Icon(Icons.location_on, size: 16, color: c.verdeOscuro),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ruta?.origen ?? despacho.ruta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(
                        size: 14,
                        weight: FontWeight.w600,
                        color: c.textoOscuro,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ruta?.destino ?? 'Ruta registrada',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(
                        size: 14,
                        weight: FontWeight.w600,
                        color: c.textoOscuro,
                      ),
                    ),
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
              Icon(Icons.event, size: 15, color: c.textoSutil),
              const SizedBox(width: 4),
              Text(
                '${Fechas.media(despacho.fecha)} · ${Fechas.horaTexto(despacho.hora)}',
                style: AppTheme.inter(size: 12, color: c.textoSutil),
              ),
              const Spacer(),
              Icon(Icons.groups_outlined, size: 16, color: c.textoSutil),
              const SizedBox(width: 4),
              Text(
                '${despacho.numeroPasajeros} pasajeros',
                style: AppTheme.inter(size: 12, color: c.textoSutil),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
