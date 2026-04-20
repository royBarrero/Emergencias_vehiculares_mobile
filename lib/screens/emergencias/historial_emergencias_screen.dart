import 'package:flutter/material.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';

class HistorialEmergenciasScreen extends StatefulWidget {
  const HistorialEmergenciasScreen({super.key});

  @override
  State<HistorialEmergenciasScreen> createState() => _HistorialEmergenciasScreenState();
}

class _HistorialEmergenciasScreenState extends State<HistorialEmergenciasScreen> {
  List<dynamic> _emergencias = [];
  bool _cargando = true;

  final Map<String, Color> _coloresPrioridad = {
    'baja': Colors.green,
    'media': Colors.orange,
    'alta': const Color(0xFFE53935),
  };

  final Map<String, Color> _coloresEstado = {
    'pendiente': Colors.orange,
    'buscando_taller': Colors.blue,
    'asignada': Colors.green,
    'en_camino': Colors.blue,
    'atendiendo': Colors.orange,
    'finalizada': Colors.green,
    'cancelada': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  void _cargarHistorial() async {
    final data = await ApiService.obtenerHistorialEmergencias();
    setState(() {
      _emergencias = data ?? [];
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        title: const Text('Historial de emergencias'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2c3e50)))
          : _emergencias.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No tienes emergencias registradas',
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _emergencias.length,
                  itemBuilder: (context, i) {
                    final e = _emergencias[i];
                    final colorPrioridad = _coloresPrioridad[e['prioridad']] ?? Colors.grey;
                    final colorEstado = _coloresEstado[e['estado']] ?? Colors.grey;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.warning_amber,
                                color: Color(0xFFE53935), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e['tipo_incidente'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  e['direccion_aproximada'] ?? 'Sin dirección',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: colorEstado.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        e['estado'] ?? '',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: colorEstado,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: colorPrioridad.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        e['prioridad'] ?? '',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: colorPrioridad,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}