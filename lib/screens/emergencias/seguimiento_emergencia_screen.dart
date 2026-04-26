import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Timer? _timer;
  List<dynamic> _talleresCercanos = [];
  double? _latEmergencia;
  double? _lngEmergencia;
  bool _cargandoMapa = true;
  Map<String, dynamic>? _tecnico;
  Map<String, dynamic>? _tallerAsignado;

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
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _consultarEstado(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      });
      if (detalle['id_tecnico'] != null) {
        _cargarTecnicoYTaller(detalle['id_tecnico'], detalle['id_taller']);
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

  void _consultarEstado() async {
    final data = await ApiService.obtenerEstadoEmergencia(widget.idEmergencia);
    if (data != null && mounted) {
      setState(() => _estado = data['estado']);

      if (_estado == 'en_camino' && _tecnico == null) {
        final detalle = await ApiService.obtenerDetalleEmergencia(
          widget.idEmergencia,
        );
        if (detalle != null && detalle['id_tecnico'] != null) {
          _cargarTecnicoYTaller(detalle['id_tecnico'], detalle['id_taller']);
        }
      }

      if (_estado == 'finalizada' || _estado == 'cancelada') {
        _timer?.cancel();
      }
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

            // Botón volver cuando finaliza
            if (_estado == 'finalizada' || _estado == 'cancelada')
              Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2c3e50),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
