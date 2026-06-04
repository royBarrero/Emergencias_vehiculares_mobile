import 'package:flutter/material.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';
import 'seleccionar_taller_screen.dart';
import 'dart:async';

class CotizacionScreen extends StatefulWidget {
  final int idEmergencia;
  final int idTaller;
  final String nombreTaller;

  const CotizacionScreen({
    super.key,
    required this.idEmergencia,
    required this.idTaller,
    required this.nombreTaller,
  });

  @override
  State<CotizacionScreen> createState() => _CotizacionScreenState();
}

class _CotizacionScreenState extends State<CotizacionScreen> {
  Map<String, dynamic>? _cotizacion;
  bool _cargando = true;
  bool _procesando = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _solicitarYEsperar();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _solicitarYEsperar() async {
    final cotizacion = await ApiService.solicitarCotizacion(
      widget.idEmergencia,
      widget.idTaller,
    );
    if (mounted) {
      setState(() {
        _cotizacion = cotizacion;
        _cargando = false;
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _verificarCotizacion());
  }

  void _verificarCotizacion() async {
    final cotizacion = await ApiService.obtenerCotizacion(widget.idEmergencia);
    if (cotizacion != null && mounted) {
      setState(() => _cotizacion = cotizacion);
      if (cotizacion['estado'] == 'enviada') {
        _timer.cancel();
      }
    }
  }

  void _decidir(String accion) async {
    if (_cotizacion == null) return;
    setState(() => _procesando = true);
    final ok = await ApiService.decidirCotizacion(_cotizacion!['id_cotizacion'], accion);
    setState(() => _procesando = false);

    if (ok) {
      if (accion == 'aceptar') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotización aceptada'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, 'aceptada');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotización rechazada'), backgroundColor: Colors.orange),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SeleccionarTallerScreen(idEmergencia: widget.idEmergencia),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoCot = _cotizacion?['estado'] ?? 'solicitada';
    final cotizacionEnviada = estadoCot == 'enviada';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        title: const Text('Cotización'),
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2c3e50)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header taller
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2c3e50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.car_repair, color: Color(0xFF2c3e50)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.nombreTaller,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 2),
                              _buildEstadoBadge(estadoCot),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Estado del proceso
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estado del proceso',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2c3e50))),
                        const SizedBox(height: 14),
                        _buildPasoEstado(Icons.check_circle, 'Solicitud enviada', true, Colors.green),
                        _buildLinea(estadoCot != 'solicitada'),
                        _buildPasoEstado(Icons.access_time, 'En revisión por el taller',
                            estadoCot != 'solicitada', Colors.orange),
                        _buildLinea(cotizacionEnviada || estadoCot == 'aceptada' || estadoCot == 'rechazada'),
                        _buildPasoEstado(Icons.description, 'Cotización disponible',
                            cotizacionEnviada || estadoCot == 'aceptada', Colors.blue),
                      ],
                    ),
                  ),

                  if (!cotizacionEnviada && estadoCot == 'solicitada') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'El taller está revisando la ficha técnica y las evidencias del incidente.',
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator(color: Color(0xFF2c3e50))),
                  ],

                  // Detalle cotización cuando está enviada
                  if (cotizacionEnviada) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              const Text('Nueva cotización disponible',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildFilaCotizacion('Taller', widget.nombreTaller),
                          const Divider(height: 20),
                          _buildFilaCotizacion('Servicio', _cotizacion!['descripcion_servicio'] ?? '-'),
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on, size: 18, color: Color(0xFF2c3e50)),
                              const SizedBox(width: 8),
                              const Text('Monto estimado', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              const Spacer(),
                              Text(
                                'Bs ${_cotizacion!['monto_estimado']?.toStringAsFixed(0) ?? '-'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF2c3e50)),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildFilaCotizacion('Tiempo estimado', _cotizacion!['tiempo_estimado'] ?? '-'),
                          if (_cotizacion!['observacion'] != null) ...[
                            const Divider(height: 20),
                            _buildFilaCotizacion('Observación', _cotizacion!['observacion']),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botones de decisión
                    const Text('¿Desea confirmar la cotización?',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2c3e50))),
                    const SizedBox(height: 4),
                    const Text('Al aceptar, el taller iniciará la atención de su vehículo.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _procesando ? null : () => _decidir('aceptar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _procesando
                            ? const SizedBox(height: 18, width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Aceptar cotización',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _procesando ? null : () => _decidir('rechazar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Rechazar cotización',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _procesando ? null : () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeleccionarTallerScreen(idEmergencia: widget.idEmergencia),
                          ),
                        ),
                        child: const Text('Buscar otro taller',
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    String label;
    switch (estado) {
      case 'solicitada': color = Colors.orange; label = 'En revisión'; break;
      case 'enviada': color = Colors.green; label = 'Recibida'; break;
      case 'aceptada': color = Colors.blue; label = 'Aceptada'; break;
      case 'rechazada': color = Colors.red; label = 'Rechazada'; break;
      default: color = Colors.grey; label = estado;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPasoEstado(IconData icono, String texto, bool completado, Color color) {
    return Row(
      children: [
        Icon(icono, size: 20, color: completado ? color : Colors.grey.shade300),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(texto,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: completado ? FontWeight.w600 : FontWeight.normal,
                    color: completado ? const Color(0xFF2c3e50) : Colors.grey)),
            if (completado && texto == 'Solicitud enviada')
              Text('Hoy', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (!completado && texto == 'En revisión por el taller')
              const Text('En curso', style: TextStyle(fontSize: 11, color: Colors.orange)),
            if (!completado && texto == 'Cotización disponible')
              const Text('Pendiente', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildLinea(bool activo) {
    return Padding(
      padding: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
      child: Container(width: 2, height: 22,
          color: activo ? Colors.green.withOpacity(0.4) : Colors.grey.shade200),
    );
  }

  Widget _buildFilaCotizacion(String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(valor,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1a1a2e))),
        ),
      ],
    );
  }
}