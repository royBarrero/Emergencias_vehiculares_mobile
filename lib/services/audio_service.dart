import 'package:flutter/foundation.dart';

// Importaciones condicionales
import 'audio_service_mobile.dart' if (dart.library.html) 'audio_service_web.dart';

class AudioService {
  static AudioServiceImpl _impl = AudioServiceImpl();

  static Future<void> iniciar(String ruta) => _impl.iniciar(ruta);
  static Future<String?> detener() => _impl.detener();
  static Future<bool> tienePermiso() => _impl.tienePermiso();
  static bool get isWeb => kIsWeb;
}