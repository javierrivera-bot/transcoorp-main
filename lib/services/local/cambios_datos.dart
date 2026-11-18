import 'package:flutter/foundation.dart';

abstract final class CambiosDatos {
  static final ValueNotifier<int> conductores = ValueNotifier<int>(0);

  static void notificarConductores() => conductores.value++;
}
