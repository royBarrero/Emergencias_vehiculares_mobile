import 'dart:async';
import 'package:flutter/material.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';

class SeguimientoEmergenciaScreen extends StatefulWidget {
  final int idEmergencia;
  const SeguimientoEmergenciaScreen({super.key, required this.idEmergencia});

  @override
  State<SeguimientoEmergenciaScreen> createState() => _SeguimientoEmergenciaScreenState();
}

class _SeguimientoEmergenciaScreenState extends State<SeguimientoEmergenciaScreen> {
  String _estado = 'pendiente';
  Timer? _timer;

  final Map<String, Map<String, dynamic>> _estadosInfo = {
    'pendiente': {'label': 'Buscando talleres...', 'icono': Icons.search, 'color': Colors.orange},
    'buscando_taller': {'label': 'Buscando taller cercano', 'icono': Icons.location_searching, 'color': Colors.blue},
    'asignada': {'label': 'Taller asignado', 'icono': Icons.check_circle, 'color': Colors.green},
    'en_camino': {'label': 'Técnico en camino', 'icono': Icons.directions_car, 'color': Colors.blue},
    'atendiendo': {'label': 'Siendo atendido', 'icono': Icons.build, 'color': Colors.orange},
    'finalizada': {'label': 'Servicio finalizado', 'icono': Icons.verified, 'color': Colors.green},
    'cancelada': {'label': 'Emergencia cancelada', 'icono': Icons.cancel, 'color': Colors.red},
  };

  @override
  void initState() {
    super.initState();
    _consultarEstado();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _consultarEstado());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _consultarEstado() async {
    final data = await ApiService.obtenerEstadoEmergencia(widget.idEmergencia);
    if (data != null && mounted) {
      setState(() => _estado = data['estado']);
      if (_estado == 'finalizada' || _estado == 'cancelada') {
        _timer?.cancel();
      }
    }
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
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(info['icono'] as IconData, size: 48, color: color),
              ),
              const SizedBox(height: 24),
              Text(
                info['label'] as String,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2c3e50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Emergencia #${widget.idEmergencia}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              if (_estado == 'pendiente' || _estado == 'buscando_taller')
                const CircularProgressIndicator(color: Color(0xFF2c3e50)),
              const SizedBox(height: 32),
              if (_estado == 'finalizada' || _estado == 'cancelada')
                ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2c3e50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Volver al inicio'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}