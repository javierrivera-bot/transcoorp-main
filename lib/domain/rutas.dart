class Ruta {
  const Ruta({
    required this.codigo,
    required this.nombre,
    required this.origen,
    required this.puntoOrigen,
    required this.destino,
    required this.puntoDestino,
    required this.servicio,
    required this.tarifa,
    required this.duracion,
    required this.distanciaKm,
    required this.activa,
  });

  final String codigo;
  final String nombre;
  final String origen;
  final String puntoOrigen;
  final String destino;
  final String puntoDestino;
  final String servicio;
  final double tarifa;
  final String duracion;
  final int distanciaKm;
  final bool activa;

  String get trayecto => '$origen → $destino';

  String get etiqueta => '$codigo · $trayecto';
}

abstract final class CatalogoRutas {
  static const List<Ruta> rutas = [
    Ruta(
      codigo: 'TP-04',
      nombre: 'Troncal Principal 04',
      origen: 'San Gabriel',
      puntoOrigen: 'Terminal Central',
      destino: 'Tulcán',
      puntoDestino: 'Parada Norte',
      servicio: 'Turno Interparroquial',
      tarifa: 8000,
      duracion: '50 min',
      distanciaKm: 38,
      activa: true,
    ),
    Ruta(
      codigo: 'RA-02',
      nombre: 'Ruta Alimentadora Norte',
      origen: 'San Gabriel',
      puntoOrigen: 'Sector San Gabriel',
      destino: 'Recinto La Florida',
      puntoDestino: 'Parque Central',
      servicio: 'Turno Rural Mixto',
      tarifa: 6000,
      duracion: '35 min',
      distanciaKm: 21,
      activa: true,
    ),
    Ruta(
      codigo: 'RM-07',
      nombre: 'Ruta Mixta Comunitaria',
      origen: 'Parada Norte',
      puntoOrigen: 'Bahía de Carga',
      destino: 'Comunidad El Esfuerzo',
      puntoDestino: 'Casa Comunal',
      servicio: 'Pasajeros y Carga',
      tarifa: 7000,
      duracion: '45 min',
      distanciaKm: 27,
      activa: true,
    ),
    Ruta(
      codigo: 'FE-09',
      nombre: 'Frecuencia Extraordinaria',
      origen: 'Tulcán',
      puntoOrigen: 'Terminal',
      destino: 'El Carmelo',
      puntoDestino: 'Plaza Principal',
      servicio: 'Turno Especial',
      tarifa: 5500,
      duracion: '40 min',
      distanciaKm: 24,
      activa: false,
    ),
  ];

  static List<Ruta> get activas => rutas.where((r) => r.activa).toList();

  static Ruta? buscar(String texto) {
    for (final ruta in rutas) {
      if (texto == ruta.etiqueta ||
          texto == ruta.codigo ||
          texto == ruta.nombre ||
          texto == ruta.trayecto) {
        return ruta;
      }
    }
    return null;
  }
}
