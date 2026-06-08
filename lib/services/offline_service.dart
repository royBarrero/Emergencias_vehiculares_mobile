import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';

class OfflineService {
  static const String _boxName = 'emergencias_pendientes';

  static Future<void> inicializar() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Future<void> guardarEmergenciaPendiente(Map<String, dynamic> datos) async {
    final box = Hive.box(_boxName);
    await box.add({
      ...datos,
      'timestamp': DateTime.now().toIso8601String(),
      'sincronizada': false,
    });
  }

  static List<Map<String, dynamic>> obtenerPendientes() {
    final box = Hive.box(_boxName);
    return box.values
        .where((e) => e['sincronizada'] == false)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> marcarSincronizada(int index) async {
    final box = Hive.box(_boxName);
    final item = Map<String, dynamic>.from(box.getAt(index)!);
    item['sincronizada'] = true;
    await box.putAt(index, item);
  }

  static Future<bool> hayConexion() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<List<Map<String, dynamic>>> sincronizarPendientes() async {
  final box = Hive.box(_boxName);
  List<Map<String, dynamic>> resultados = [];

  for (int i = 0; i < box.length; i++) {
    final item = box.getAt(i);
    if (item == null || item['sincronizada'] == true) continue;

    try {
      final datos = Map<String, dynamic>.from(item);
      datos.remove('timestamp');
      datos.remove('sincronizada');

      final resultado = await ApiService.registrarEmergencia(datos);
      if (resultado != null) {
        await marcarSincronizada(i);
        resultados.add({
          'exito': true,
          'tipo_incidente': datos['tipo_incidente'],
          'id_emergencia': resultado['id_emergencia'],
        });
      }
    } catch (e) {
      resultados.add({'exito': false, 'error': e.toString()});
    }
  }
  return resultados;
}
  static int contarPendientes() {
    final box = Hive.box(_boxName);
    return box.values.where((e) => e['sincronizada'] == false).length;
  }
}