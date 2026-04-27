import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:emergencias_vehiculares/services/api_service.dart';
import 'seguimiento_emergencia_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:emergencias_vehiculares/services/audio_service.dart';
import 'package:flutter/foundation.dart';

class RegistrarEmergenciaScreen extends StatefulWidget {
  const RegistrarEmergenciaScreen({super.key});

  @override
  State<RegistrarEmergenciaScreen> createState() =>
      _RegistrarEmergenciaScreenState();
}

class _RegistrarEmergenciaScreenState extends State<RegistrarEmergenciaScreen> {
  final PageController _pageController = PageController();
  int _pasoActual = 0;

  // Datos del formulario
  int? _idVehiculoSeleccionado;
  String _vehiculoNombre = '';
  String _tipoIncidente = '';
  String _prioridad = 'media';
  double? _latitud;
  double? _longitud;
  String _direccion = 'Obteniendo ubicación...';
  bool _cargandoUbicacion = false;
  final TextEditingController _descripcionCtrl = TextEditingController();
  // Fotos
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _fotos = [];

  // Audio
  //final AudioRecorder _recorder = AudioRecorder();
  bool _grabando = false;
  String? _rutaAudio;
  //Duration _duracionGrabacion = Duration.zero;

  // Vehículos del conductor
  List<dynamic> _vehiculos = [];
  bool _cargandoVehiculos = true;
  bool _enviando = false;

  final List<String> _tiposIncidente = [
    'Falla de motor',
    'Pinchazo',
    'Batería descargada',
    'Accidente',
    'Falla de frenos',
    'Transmisión',
    'Sobrecalentamiento',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
    _obtenerUbicacion();
  }

  void _cargarVehiculos() async {
    final prefs = await SharedPreferences.getInstance();
    final idUsuario = prefs.getInt('id_usuario');
    if (idUsuario == null) return;

    final conductor = await ApiService.obtenerConductorPorUsuario(idUsuario);
    if (conductor == null) return;

    final vehiculos = await ApiService.obtenerVehiculos(
      conductor['id_conductor'],
    );
    setState(() {
      _vehiculos = vehiculos ?? [];
      _cargandoVehiculos = false;
    });
  }

  Future<void> _obtenerUbicacion() async {
    setState(() => _cargandoUbicacion = true);
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      setState(() {
        _direccion = 'GPS desactivado';
        _cargandoUbicacion = false;
      });
      return;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        setState(() {
          _direccion = 'Permiso de ubicación denegado';
          _cargandoUbicacion = false;
        });
        return;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      setState(() {
        _direccion = 'Permiso denegado permanentemente';
        _cargandoUbicacion = false;
      });
      return;
    }

    Position posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _latitud = posicion.latitude;
      _longitud = posicion.longitude;
      _direccion =
          'Lat: ${posicion.latitude.toStringAsFixed(4)}, Lng: ${posicion.longitude.toStringAsFixed(4)}';
      _cargandoUbicacion = false;
    });
  }

  // ── Prioridad automática ──
  String _calcularPrioridad(String tipoIncidente) {
    const alta = ['Accidente', 'Falla de frenos', 'Falla de motor'];
    const media = ['Sobrecalentamiento', 'Transmisión', 'Batería descargada'];
    if (alta.contains(tipoIncidente)) return 'alta';
    if (media.contains(tipoIncidente)) return 'media';
    return 'baja';
  }

  // ← aquí va el nuevo método
  Color _getPrioridadColor(String prioridad) {
    if (prioridad == 'alta') return const Color(0xFFE53935);
    if (prioridad == 'media') return Colors.orange;
    return Colors.green;
  }

  // ── Fotos ──
  Future<void> _tomarFoto() async {
    if (_fotos.length >= 3) {
      _mostrarError('Máximo 3 fotos');
      return;
    }
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (foto != null) {
      setState(() => _fotos.add(foto));
    }
  }

  Future<void> _elegirDeGaleria() async {
    if (_fotos.length >= 3) {
      _mostrarError('Máximo 3 fotos');
      return;
    }
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (foto != null) {
      setState(() => _fotos.add(foto));
    }
  }

  void _eliminarFoto(int index) {
    setState(() => _fotos.removeAt(index));
  }

  // ── Audio ──
 Future<void> _toggleGrabacion() async {
  if (_grabando) {
    final ruta = await AudioService.detener();
    setState(() {
      _grabando = false;
      _rutaAudio = ruta;
    });
  } else {
    final permiso = await AudioService.tienePermiso();
    if (!permiso) {
      _mostrarError('Permiso de micrófono denegado');
      return;
    }

    String ruta = 'audio_web';
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      ruta = '${dir.path}/audio_emergencia.m4a';
    }

    await AudioService.iniciar(ruta);
    setState(() {
      _grabando = true;
      _rutaAudio = null;
    });
  }
}
  // ── Subir evidencia al backend ──
  Future<void> _subirEvidencias(int idEmergencia) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token')?.trim() ?? '';

  for (final foto in _fotos) {
    final bytes = await foto.readAsBytes();
    final nombreArchivo = foto.name;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/emergencias/$idEmergencia/evidencia'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['tipo'] = 'foto';
    request.files.add(http.MultipartFile.fromBytes(
      'archivo',
      bytes,
      filename: nombreArchivo,
    ));
    await request.send();
  }

  if (_rutaAudio != null) {
    try {
      if (kIsWeb) {
        // En web el audio es una URL blob
        final response = await http.get(Uri.parse(_rutaAudio!));
        final bytes = response.bodyBytes;
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiService.baseUrl}/emergencias/$idEmergencia/evidencia'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['tipo'] = 'audio';
        request.files.add(http.MultipartFile.fromBytes(
          'archivo',
          bytes,
          filename: 'audio_emergencia.webm',
        ));
        await request.send();
      } else {
        // En móvil usar XFile
        final audioXFile = XFile(_rutaAudio!);
        final bytes = await audioXFile.readAsBytes();
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiService.baseUrl}/emergencias/$idEmergencia/evidencia'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['tipo'] = 'audio';
        request.files.add(http.MultipartFile.fromBytes(
          'archivo',
          bytes,
          filename: 'audio_emergencia.m4a',
        ));
        await request.send();
      }
    } catch (e) {
      print('Error subiendo audio: $e');
    }
  }
}

  void _siguientePaso() {
    if (_pasoActual == 0 && _idVehiculoSeleccionado == null) {
      _mostrarError('Selecciona un vehículo');
      return;
    }
    if (_pasoActual == 1 && _tipoIncidente.isEmpty) {
      _mostrarError('Selecciona el tipo de incidente');
      return;
    }
    if (_pasoActual < 2) {
      setState(() => _pasoActual++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _confirmarEmergencia();
    }
  }

  void _anteriorPaso() {
    if (_pasoActual > 0) {
      setState(() => _pasoActual--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _confirmarEmergencia() async {
    if (_latitud == null || _longitud == null) {
      _mostrarError('No se pudo obtener la ubicación GPS. Intenta de nuevo.');
      return;
    }

    setState(() => _enviando = true);

    final prioridadAuto = _calcularPrioridad(_tipoIncidente);

    final datos = {
      'id_vehiculo': _idVehiculoSeleccionado,
      'latitud': _latitud,
      'longitud': _longitud,
      'direccion_aproximada': _direccion,
      'tipo_incidente': _tipoIncidente,
      'prioridad': prioridadAuto,
      'descripcion': _descripcionCtrl.text,
    };

    final resultado = await ApiService.registrarEmergencia(datos);

    if (resultado != null) {
      await _subirEvidencias(resultado['id_emergencia']);
      setState(() => _enviando = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SeguimientoEmergenciaScreen(
            idEmergencia: resultado['id_emergencia'],
          ),
        ),
      );
    } else {
      setState(() => _enviando = false);
      _mostrarError('Error al registrar la emergencia. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        title: const Text('Nueva Emergencia'),
        elevation: 0,
        leading: _pasoActual > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _anteriorPaso,
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Column(
        children: [
          _buildIndicadorPasos(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPaso1Vehiculo(),
                _buildPaso2Incidente(),
                _buildPaso3Resumen(),
              ],
            ),
          ),
          _buildBotonAccion(),
        ],
      ),
    );
  }

  // ── Indicador de pasos ──
  Widget _buildIndicadorPasos() {
    return Container(
      color: const Color(0xFF2c3e50),
      padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      child: Row(
        children: List.generate(3, (i) {
          final activo = i == _pasoActual;
          final completado = i < _pasoActual;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completado
                        ? const Color(0xFFE53935)
                        : activo
                        ? Colors.white
                        : Colors.white24,
                  ),
                  child: Center(
                    child: completado
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: activo
                                  ? const Color(0xFF2c3e50)
                                  : Colors.white54,
                            ),
                          ),
                  ),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: completado
                          ? const Color(0xFFE53935)
                          : Colors.white24,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Paso 1: Seleccionar vehículo ──
  Widget _buildPaso1Vehiculo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona tu vehículo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '¿Con qué vehículo tuviste el problema?',

            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFFE53935),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu ubicación',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        _direccion,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_cargandoUbicacion)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _cargandoVehiculos
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2c3e50)),
                )
              : _vehiculos.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No tienes vehículos registrados',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Column(
                  children: _vehiculos.map((v) {
                    final seleccionado =
                        _idVehiculoSeleccionado == v['id_vehiculo'];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _idVehiculoSeleccionado = v['id_vehiculo'];
                        _vehiculoNombre =
                            '${v['marca']} ${v['modelo']} · ${v['placa']}';
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: seleccionado
                                ? const Color(0xFFE53935)
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2c3e50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.directions_car,
                                color: Color(0xFF2c3e50),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${v['marca']} ${v['modelo']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${v['placa']} · ${v['color'] ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (seleccionado)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFFE53935),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildPaso2Incidente() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Qué problema tienes?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona el tipo de incidente',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Tipos de incidente
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tiposIncidente.map((tipo) {
              final seleccionado = _tipoIncidente == tipo;
              return GestureDetector(
                onTap: () => setState(() {
                  _tipoIncidente = tipo;
                  _prioridad = _calcularPrioridad(tipo);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? const Color(0xFF2c3e50)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: seleccionado
                          ? const Color(0xFF2c3e50)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    tipo,
                    style: TextStyle(
                      fontSize: 13,
                      color: seleccionado ? Colors.white : Colors.black87,
                      fontWeight: seleccionado
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Prioridad automática
          if (_tipoIncidente.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getPrioridadColor(
                  _calcularPrioridad(_tipoIncidente),
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _getPrioridadColor(
                    _calcularPrioridad(_tipoIncidente),
                  ).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: _getPrioridadColor(
                      _calcularPrioridad(_tipoIncidente),
                    ),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Prioridad asignada automáticamente: ${_calcularPrioridad(_tipoIncidente).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getPrioridadColor(
                        _calcularPrioridad(_tipoIncidente),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── FOTOS ──
          const Text(
            'Fotos del problema',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Máximo 3 fotos',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Botón cámara
              Expanded(
                child: GestureDetector(
                  onTap: _tomarFoto,
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: Color(0xFF2c3e50),
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Cámara',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Botón galería
              Expanded(
                child: GestureDetector(
                  onTap: _elegirDeGaleria,
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library,
                          color: Color(0xFF2c3e50),
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Galería',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Fotos seleccionadas
          if (_fotos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Column(
              children: List.generate(_fotos.length, (i) {
                final nombreArchivo = _fotos[i].path
                    .split('/')
                    .last
                    .split('\\')
                    .last;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2c3e50).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF2c3e50).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.image,
                        color: Color(0xFF2c3e50),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nombreArchivo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _eliminarFoto(i),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFFE53935),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],

          const SizedBox(height: 24),

          // ── AUDIO ──
          const Text(
            'Descripción por audio',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleGrabacion,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _grabando ? Colors.grey : const Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _grabando ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _grabando
                            ? 'Grabando...'
                            : _rutaAudio != null
                            ? 'Audio grabado ✓'
                            : 'Toca el micrófono para grabar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _grabando
                              ? const Color(0xFFE53935)
                              : Colors.black87,
                        ),
                      ),
                      if (_rutaAudio != null)
                        const Text(
                          'Listo para enviar',
                          style: TextStyle(fontSize: 11, color: Colors.green),
                        ),
                    ],
                  ),
                ),
                if (_rutaAudio != null)
                  GestureDetector(
                    onTap: () => setState(() => _rutaAudio = null),
                    child: const Icon(Icons.delete_outline, color: Colors.grey),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Descripción adicional
          const Text(
            'Descripción adicional (opcional)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descripcionCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe el problema con más detalle...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioridadBtn(String valor, String label, Color color) {
    final seleccionado = _prioridad == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _prioridad = valor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: seleccionado ? color.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: seleccionado ? color : Colors.grey.shade300,
              width: seleccionado ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: seleccionado ? color : Colors.grey,
                fontWeight: seleccionado ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Paso 3: Resumen ──
  Widget _buildPaso3Resumen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirmar emergencia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Revisa los datos antes de enviar',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: Column(
              children: [
                _buildFilaResumen(
                  Icons.directions_car,
                  'Vehículo',
                  _vehiculoNombre,
                ),
                const Divider(height: 20),
                _buildFilaResumen(
                  Icons.warning_amber,
                  'Incidente',
                  _tipoIncidente,
                ),
                const Divider(height: 20),
                _buildFilaResumen(
                  Icons.flag,
                  'Prioridad',
                  _prioridad.toUpperCase(),
                  color: _prioridad == 'alta'
                      ? const Color(0xFFE53935)
                      : _prioridad == 'media'
                      ? Colors.orange
                      : Colors.green,
                ),
                if (_descripcionCtrl.text.isNotEmpty) ...[
                  const Divider(height: 20),
                  _buildFilaResumen(
                    Icons.notes,
                    'Descripción',
                    _descripcionCtrl.text,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFE53935), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Al confirmar se notificará a talleres cercanos y se compartirá tu ubicación.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFC62828)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaResumen(
    IconData icono,
    String label,
    String valor, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icono, color: const Color(0xFF2c3e50), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color ?? const Color(0xFF1a1a2e),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Botón de acción ──
  Widget _buildBotonAccion() {
    final labels = ['Siguiente', 'Siguiente', 'Confirmar emergencia'];
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _enviando ? null : _siguientePaso,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _enviando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  labels[_pasoActual],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
