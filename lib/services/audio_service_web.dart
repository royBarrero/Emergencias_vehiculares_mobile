import 'dart:async';
import 'dart:html' as html;

class AudioServiceImpl {
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _chunks = [];
  String? _audioUrl;
  Completer<String?>? _completer;

  Future<bool> tienePermiso() async {
    try {
      await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> iniciar(String ruta) async {
    _chunks = [];
    _audioUrl = null;

    final stream = await html.window.navigator.mediaDevices!
        .getUserMedia({'audio': true});

    _mediaRecorder = html.MediaRecorder(stream);
    _completer = Completer<String?>();

    _mediaRecorder!.addEventListener('dataavailable', (event) {
      final blob = (event as html.BlobEvent).data;
      if (blob != null && blob.size > 0) {
        _chunks.add(blob);
      }
    });

    _mediaRecorder!.addEventListener('stop', (event) async {
      if (_chunks.isNotEmpty) {
        final blob = html.Blob(_chunks, 'audio/webm');
        _audioUrl = html.Url.createObjectUrl(blob);
        _completer?.complete(_audioUrl);
      } else {
        _completer?.complete(null);
      }
    });

    _mediaRecorder!.start();
  }

  Future<String?> detener() async {
    if (_mediaRecorder == null) return null;
    _mediaRecorder!.stop();
    return await _completer?.future;
  }
}