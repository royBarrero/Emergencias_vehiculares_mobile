import 'package:record/record.dart';


class AudioServiceImpl {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> tienePermiso() async {
    return await _recorder.hasPermission();
  }

  Future<void> iniciar(String ruta) async {
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: ruta,
    );
  }

  Future<String?> detener() async {
    return await _recorder.stop();
  }
}