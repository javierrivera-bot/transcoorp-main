import 'package:transcoorp/models/comun/json.dart';
import 'package:transcoorp/models/vehiculo/vehiculo.dart';
import 'package:transcoorp/services/remote/servicio_base.dart';

class MiCuentaService extends ServicioBase {
  Future<List<VehiculoAsociado>> misVehiculos() async {
    final respuesta = await api.get(
      '/api/mi-cuenta/vehiculos',
      headers: cabeceras,
    );
    return Json.lista(respuesta).map(VehiculoAsociado.fromJson).toList();
  }
}
