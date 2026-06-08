import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cotizacion_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:emergencias_vehiculares/screens/home/pago_screen.dart';

class SeguimientoEmergenciaScreen extends StatefulWidget {
  final int idEmergencia;
  const SeguimientoEmergenciaScreen({super.key, required this.idEmergencia});

  @override
  State<SeguimientoEmergenciaScreen> createState() =>
      _SeguimientoEmergenciaScreenState();
}

class _SeguimientoEmergenciaScreenState
    extends State<SeguimientoEmergenciaScreen> {
  String _estado = 'pendiente';
  WebSocketChannel? _wsChannel;
  List<dynamic> _talleresCercanos = [];
  double? _latEmergencia;
  double? _lngEmergencia;
  bool _cargandoMapa = true;
  Map<String, dynamic>? _tecnico;
  Map<String, dynamic>? _tallerAsignado;
  String? _tiempoEstimado;
  int _intentosReconexion = 0;

  final Map<String, Map<String, dynamic>> _estadosInfo = {
    'pendiente': {
      'label': 'Buscando talleres...',
      'icono': Icons.search,
      'color': Colors.orange,
    },
    'buscando_taller': {
      'label': 'Buscando taller cercano',
      'icono': Icons.location_searching,
      'color': Colors.blue,
    },
    'asignada': {
      'label': 'Taller asignado',
      'icono': Icons.check_circle,
      'color': Colors.green,
    },
    'en_camino': {
      'label': 'Técnico en camino',
      'icono': Icons.directions_car,
      'color': Colors.blue,
    },
    'atendiendo': {
      'label': 'Siendo atendido',
      'icono': Icons.build,
      'color': Colors.orange,
    },
    'finalizada': {
      'label': 'Servicio finalizado',
      'icono': Icons.verified,
      'color': Colors.green,
    },
    'cancelada': {
      'label': 'Emergencia cancelada',
      'icono': Icons.cancel,
      'color': Colors.red,
    },
  };

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    _cargarDatosIniciales();
    _conectarWebSocket();
  }
  
void _conectarWebSocket() {
  final wsUrl = Uri.parse(
    'ws://192.168.1.10:8000/ws/emergencia/${widget.idEmergencia}'
  );
  _intentosReconexion = 0;
  _wsChannel = WebSocketChannel.connect(wsUrl);
  _wsChannel!.stream.listen(
    (mensaje) {
      _intentosReconexion = 0;
      final data = jsonDecode(mensaje) as Map<String, dynamic>;
      print('WS data recibida: $data');
      if (!mounted) return;
      setState(() {
        _estado = data['estado'];
        if (data['tiempo_estimado_reparacion'] != null) {
          _tiempoEstimado = data['tiempo_estimado_reparacion'];
        }
      });

      if (data['estado'] == 'en_camino' && _tecnico == null) {
        print('Cargando tecnico: ${data['id_tecnico']}, taller: ${data['id_taller']}');
        _cargarTecnicoYTaller(data['id_tecnico'], data['id_taller']);
      }
      if (data['estado'] == 'finalizada') {
        Future.delayed(const Duration(seconds: 1), _mostrarCalificacion);
        _wsChannel?.sink.close();
      }
      if (data['estado'] == 'cancelada') {
        _wsChannel?.sink.close();
      }
    },
    onError: (error) {
      _intentosReconexion++;
      if (_intentosReconexion <= 5) {
        Future.delayed(const Duration(seconds: 3), _conectarWebSocket);
      }
    },
    onDone: () {
if (_estado != 'finalizada' && _estado != 'cancelada' && mounted) {
        _intentosReconexion++;
        if (_intentosReconexion <= 5) {
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _estado != 'finalizada' && _estado != 'cancelada') {
              _conectarWebSocket();
            }
          });
        }
      }
    },
  );
}
  @override
  void dispose() {
   _wsChannel?.sink.close();
    super.dispose();
  }

  void _cargarDatosIniciales() async {
    final detalle = await ApiService.obtenerDetalleEmergencia(
      widget.idEmergencia,
    );
    if (detalle != null && mounted) {
      setState(() {
  _latEmergencia = detalle['latitud']?.toDouble();
  _lngEmergencia = detalle['longitud']?.toDouble();
  _estado = detalle['estado'] ?? 'pendiente';
  _tiempoEstimado = detalle['tiempo_estimado_reparacion'];
});
      if (detalle['id_tecnico'] != null) {
        _cargarTecnicoYTaller(detalle['id_tecnico'], detalle['id_taller']);
      } else if (detalle['id_taller'] != null) {
        final taller = await ApiService.obtenerTaller(detalle['id_taller']);
        if (mounted) setState(() => _tallerAsignado = taller);
      }
    }

    final talleres = await ApiService.obtenerTalleresCercanos(
      widget.idEmergencia,
    );
    if (talleres != null && mounted) {
      setState(() {
        _talleresCercanos = talleres;
        _cargandoMapa = false;
      });
    } else {
      setState(() => _cargandoMapa = false);
    }
  }

  void _cargarTecnicoYTaller(int idTecnico, int idTaller) async {
    final tecnico = await ApiService.obtenerTecnico(idTecnico);
    final taller = await ApiService.obtenerTaller(idTaller);
    if (mounted) {
      setState(() {
        _tecnico = tecnico;
        _tallerAsignado = taller;
      });
    }
  }


  double _calcularDistancia(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  String _calcularTiempoAproximado(double distanciaKm) {
    final minutos = (distanciaKm / 40 * 60).round();
    if (minutos < 60) return '$minutos min';
    return '${(minutos / 60).round()} h ${minutos % 60} min';
  }

  void _llamarTecnico() async {
    if (_tecnico?['telefono'] == null) return;
    final uri = Uri.parse('tel:${_tecnico!['telefono']}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
  void _mostrarDialogoCancelacion() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 34),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Cancelar el servicio?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se aplicará un recargo por cancelación',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'El técnico ya se encuentra en camino hacia tu ubicación. De acuerdo a nuestra política, se cobrará un monto fijo de:',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                SizedBox(height: 8),
                Text(
                  'Bs 70',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'por cancelación de servicio en camino',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'No cancelar',
                  style: TextStyle(
                    color: Color(0xFF2c3e50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) _mostrarQRCancelacion();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
void _mostrarQRCancelacion() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pago de recargo',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Escanea el QR para pagar el recargo por cancelación',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_2, size: 140, color: Color(0xFF2c3e50)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Bs 70',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Recargo por cancelación de servicio',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Una vez realizado el pago, confirma para continuar.',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _procesarCancelacion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Ya pagué — Confirmar cancelación',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  );
}
Future<void> _procesarCancelacion() async {
  // Registrar pago de recargo por cancelación
  final detalle = await ApiService.obtenerDetalleEmergencia(widget.idEmergencia);
  if (detalle != null) {
    await ApiService.registrarPago({
      'id_emergencia': widget.idEmergencia,
      'monto_total': 70.0,
      'comision': 7.0,
      'monto_neto': 63.0,
      'metodo_pago': 'efectivo',
      'estado': 'pendiente',
    });
  }

  // Cancelar la emergencia
  final ok = await ApiService.actualizarEstadoEmergencia(
    widget.idEmergencia,
    {'estado': 'cancelada'},
  );

  if (ok && mounted) {
    setState(() => _estado = 'cancelada');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Servicio cancelado. Se cobrará Bs 70 por recargo.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }
}
  void _mostrarCalificacion() {
  int _estrellas = 0;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('¡Servicio completado!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                    color: Color(0xFF2c3e50))),
            const SizedBox(height: 8),
            const Text('¿Cómo calificarías el servicio?',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setDialogState(() => _estrellas = index + 1),
                  child: Icon(
                    index < _estrellas ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFB300),
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _estrellas == 0 ? 'Toca para calificar' :
              _estrellas == 1 ? 'Malo' :
              _estrellas == 2 ? 'Regular' :
              _estrellas == 3 ? 'Bueno' :
              _estrellas == 4 ? 'Muy bueno' : '¡Excelente!',
              style: TextStyle(
                fontSize: 13,
                color: _estrellas == 0 ? Colors.grey : const Color(0xFFFFB300),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _estrellas == 0 ? null : () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2c3e50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text('Enviar calificación'),
            ),
          ),
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final info = _estadosInfo[_estado] ?? _estadosInfo['pendiente']!;
    final color = info['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        title: const Text('Seguimiento'),
        leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.pop(context),
    ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Estado actual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      info['icono'] as IconData,
                      size: 36,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    info['label'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Emergencia #${widget.idEmergencia}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  if (_estado == 'pendiente' ||
                      _estado == 'buscando_taller') ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(color: Color(0xFF2c3e50)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Vista cuando técnico está en camino
            if (_estado == 'en_camino' || _estado == 'atendiendo') ...[
              if (_tecnico != null)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Técnico asignado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2c3e50).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF2c3e50),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tecnico!['nombre'] ?? 'Técnico',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _tallerAsignado?['nombre_taller'] ??
                                      'Taller asignado',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_tecnico!['telefono'] != null)
                            GestureDetector(
                              onTap: _llamarTecnico,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Minimapa con ruta
                      if (_latEmergencia != null &&
                          _tallerAsignado?['latitud'] != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 220,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                  (_latEmergencia! +
                                          (_tallerAsignado!['latitud']
                                              as double)) /
                                      2,
                                  (_lngEmergencia! +
                                          (_tallerAsignado!['longitud']
                                              as double)) /
                                      2,
                                ),
                                initialZoom: 13,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.emergencias.vehiculares',
                                ),
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: [
                                        LatLng(
                                          _latEmergencia!,
                                          _lngEmergencia!,
                                        ),
                                        LatLng(
                                          _tallerAsignado!['latitud']
                                              .toDouble(),
                                          _tallerAsignado!['longitud']
                                              .toDouble(),
                                        ),
                                      ],
                                      color: const Color(0xFF2c3e50),
                                      strokeWidth: 3,
                                      pattern: StrokePattern.dotted(),
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(
                                        _latEmergencia!,
                                        _lngEmergencia!,
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.directions_car,
                                        color: Color(0xFFE53935),
                                        size: 32,
                                      ),
                                    ),
                                    Marker(
                                      point: LatLng(
                                        _tallerAsignado!['latitud'].toDouble(),
                                        _tallerAsignado!['longitud'].toDouble(),
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.build_circle,
                                        color: Color(0xFF2c3e50),
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2c3e50).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'Distancia',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '${_calcularDistancia(_latEmergencia!, _lngEmergencia!, _tallerAsignado!['latitud'].toDouble(), _tallerAsignado!['longitud'].toDouble()).toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2c3e50),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey.shade300,
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Tiempo aprox.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _calcularTiempoAproximado(
                                      _calcularDistancia(
                                        _latEmergencia!,
                                        _lngEmergencia!,
                                        _tallerAsignado!['latitud'].toDouble(),
                                        _tallerAsignado!['longitud'].toDouble(),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2c3e50),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey.shade300,
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Taller',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _tallerAsignado!['nombre_taller'] ??
                                        'Asignado',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2c3e50),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
           // CU30: Tiempo estimado de reparación
            if (_estado == 'en_camino' || _estado == 'atendiendo' || _estado == 'finalizada') ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.orange, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tiempo estimado de reparación',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            _tiempoEstimado ?? 'Por confirmar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _tiempoEstimado != null
                                  ? Colors.orange.shade800
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Mapa talleres cercanos cuando está pendiente
            if (_estado == 'pendiente' || _estado == 'buscando_taller') ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFE53935),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Talleres cercanos disponibles (${_talleresCercanos.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2c3e50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_cargandoMapa)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2c3e50),
                        ),
                      )
                    else if (_latEmergencia != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 220,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                _latEmergencia!,
                                _lngEmergencia!,
                              ),
                              initialZoom: 13,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.emergencias.vehiculares',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      _latEmergencia!,
                                      _lngEmergencia!,
                                    ),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: Color(0xFFE53935),
                                      size: 32,
                                    ),
                                  ),
                                  ..._talleresCercanos.map(
                                    (t) => Marker(
                                      point: LatLng(
                                        t['latitud'].toDouble(),
                                        t['longitud'].toDouble(),
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.build_circle,
                                        color: Color(0xFF2c3e50),
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    ..._talleresCercanos.map(
                      (t) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2c3e50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.build,
                                color: Color(0xFF2c3e50),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['nombre_taller'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    t['direccion'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${t['distancia_km']} km',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2c3e50),
                                  ),
                                ),
                                Text(
                                  '⭐ ${t['calificacion_promedio']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
// Botones de acción cuando taller está asignado
if (_estado == 'asignada' && _tallerAsignado != null)
  Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CotizacionScreen(
                  idEmergencia: widget.idEmergencia,
                  idTaller: _tallerAsignado!['id_taller'],
                  nombreTaller: _tallerAsignado!['nombre_taller'] ?? 'Taller asignado',
                ),
              ),
            ),
            icon: const Icon(Icons.request_quote),
            label: const Text('Solicitar cotización',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
           onPressed: () async {
              await ApiService.actualizarEstadoEmergencia(
                widget.idEmergencia,
                {'atencion_directa': true},
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El taller fue notificado. Espera la confirmación.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.flash_on, color: Color(0xFF2c3e50)),
            label: const Text(
              'Continuar sin cotizar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2c3e50),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF2c3e50), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'El taller recibirá tu solicitud y asignará un técnico directamente.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    ),
  ),
  // Botón cancelar cuando técnico está en camino
            if (_estado == 'en_camino')
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _mostrarDialogoCancelacion(),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text(
                      'Cancelar servicio',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            // Botón volver cuando finaliza
            if (_estado == 'finalizada')
  Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PagoScreen(
                  idEmergencia: widget.idEmergencia,
                  montoTotal: 150.0, // monto de prueba
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('💳 Realizar pago'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2c3e50),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Volver al inicio'),
          ),
        ),
      ],
    ),
  ),

if (_estado == 'cancelada')
  Padding(
    padding: const EdgeInsets.all(24),
    child: ElevatedButton(
      onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Volver al inicio'),
    ),
  ),
          ],
        ),
      ),
    );
  }
}
