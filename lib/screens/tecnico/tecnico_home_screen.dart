import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';
import 'dart:async';

class TecnicoHomeScreen extends StatefulWidget {
  const TecnicoHomeScreen({super.key});

  @override
  State<TecnicoHomeScreen> createState() => _TecnicoHomeScreenState();
}

class _TecnicoHomeScreenState extends State<TecnicoHomeScreen> {
  String _nombre = 'Técnico';
  Map<String, dynamic>? _emergenciaAsignada;
  Map<String, dynamic>? _tecnico;
  bool _cargando = true;
  Timer? _timer;
  List<dynamic> _historialTecnico = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _cargarEmergencia());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _cargarDatos() async {
  final prefs = await SharedPreferences.getInstance();
  final nombre = prefs.getString('nombre') ?? 'Técnico';
  final token = prefs.getString('token');
  print('TOKEN TECNICO: $token');  // ← agregar
  final idUsuario = prefs.getInt('id_usuario') ?? 0;
  setState(() => _nombre = nombre);
    final tecnico = await ApiService.obtenerTecnicoPorUsuario(idUsuario);
    if (tecnico != null && mounted) {
      setState(() => _tecnico = tecnico);
      await _cargarEmergencia();
      await _cargarHistorial();
    }
    setState(() => _cargando = false);
  }
  Future<void> _cargarEmergencia() async {
    if (_tecnico == null) return;
    final emergencia = await ApiService.obtenerEmergenciaTecnico(
        _tecnico!['id_tecnico']);
    if (mounted) {
      setState(() => _emergenciaAsignada = emergencia);
    }
    
  }
Future<void> _cargarHistorial() async {
  if (_tecnico == null) return;
  final data = await ApiService.obtenerEmergenciasTecnico(_tecnico!['id_tecnico']);
  if (mounted) {
    setState(() => _historialTecnico = data ?? []);
  }
}
  void _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F5F5),
    body: Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFF2c3e50),
          padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hola! 👋',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(_nombre,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w600)),
                  const Text('Técnico',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
              IconButton(
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
        ),

        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2c3e50)))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _emergenciaAsignada == null
                            ? _buildSinEmergencia()
                            : _buildEmergenciaAsignada(),
                      ),

                      if (_historialTecnico.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text('Servicios realizados',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                      color: Color(0xFF2c3e50))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('${_historialTecnico.length}',
                                    style: const TextStyle(fontSize: 12,
                                        color: Colors.green, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _historialTecnico.length,
                          itemBuilder: (context, index) {
                            final e = _historialTecnico[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.verified, color: Colors.green, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e['tipo_incidente'] ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600, fontSize: 13)),
                                        Text(e['direccion_aproximada'] ?? 'Sin dirección',
                                            style: const TextStyle(
                                                color: Colors.grey, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Finalizado',
                                        style: TextStyle(fontSize: 11, color: Colors.green,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    ),
  );
}
  Widget _buildSinEmergencia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 44, color: Colors.green),
          ),
          const SizedBox(height: 16),
          const Text('Sin emergencias asignadas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: Color(0xFF2c3e50))),
          const SizedBox(height: 8),
          const Text('Estás disponible',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmergenciaAsignada() {
    final e = _emergenciaAsignada!;
    final estado = e['estado'] ?? 'asignada';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tarjeta emergencia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🚨 EMERGENCIA ASIGNADA',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              color: Color(0xFFE53935))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetalleFila(Icons.warning_amber, 'Incidente', e['tipo_incidente'] ?? ''),
                _buildDetalleFila(Icons.location_on, 'Ubicación',
                    e['direccion_aproximada'] ?? 'Sin dirección'),
                _buildDetalleFila(Icons.flag, 'Prioridad',
                    (e['prioridad'] ?? '').toUpperCase()),
                if (e['descripcion'] != null && e['descripcion'] != '')
                  _buildDetalleFila(Icons.notes, 'Descripción', e['descripcion']),
                if (e['telefono_conductor'] != null)
                  _buildDetalleFila(Icons.phone, 'Conductor', e['telefono_conductor']),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botones de acción según estado
          if (estado == 'asignada' || estado == 'en_camino')
            _buildBoton(
              'Marcar como atendiendo',
              Icons.build,
              Colors.orange,
              () => _actualizarEstado('atendiendo'),
            ),

          if (estado == 'atendiendo')
            _buildBoton(
              'Proceder al cobro',
              Icons.payment,
              Colors.green,
              () => _mostrarPantallaPago(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetalleFila(IconData icono, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: const Color(0xFF2c3e50)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                    color: Color(0xFF1a1a2e))),
          ),
        ],
      ),
    );
  }

  Widget _buildBoton(String label, IconData icono, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icono),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _actualizarEstado(String nuevoEstado) async {
  if (_emergenciaAsignada == null) return;
  final id = _emergenciaAsignada!['id_emergencia'];
  await ApiService.actualizarEstadoEmergencia(id, {'estado': nuevoEstado});
  _cargarEmergencia();
}

  void _mostrarPantallaPago() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _PantallaPago(
      emergencia: _emergenciaAsignada!,
      onFinalizar: (double monto, String metodo) async {
        Navigator.pop(context);
        await ApiService.registrarPago({
          'id_emergencia': _emergenciaAsignada!['id_emergencia'],
          'monto_total': monto,
          'metodo_pago': metodo,
        });
        await _actualizarEstado('finalizada');
        await _cargarHistorial();
      },
    ),
  );
}
}

class _PantallaPago extends StatefulWidget {
  final Map<String, dynamic> emergencia;
  final Function(double monto, String metodo) onFinalizar;
  const _PantallaPago({required this.emergencia, required this.onFinalizar});

  @override
  State<_PantallaPago> createState() => _PantallaPagoState();
}

class _PantallaPagoState extends State<_PantallaPago> {
  String _metodoPago = '';
  final _montoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Cobro del servicio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                    color: Color(0xFF2c3e50))),
            const SizedBox(height: 20),

            // Monto
            const Text('Monto cobrado (Bs.)',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ej: 150',
                prefixText: 'Bs. ',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Método de pago
            const Text('Método de pago',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _metodoPago = 'efectivo'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _metodoPago == 'efectivo'
                            ? const Color(0xFF2c3e50)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _metodoPago == 'efectivo'
                              ? const Color(0xFF2c3e50)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.money,
                              color: _metodoPago == 'efectivo'
                                  ? Colors.white
                                  : Colors.grey,
                              size: 28),
                          const SizedBox(height: 6),
                          Text('Efectivo',
                              style: TextStyle(
                                  color: _metodoPago == 'efectivo'
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _metodoPago = 'qr'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _metodoPago == 'qr'
                            ? const Color(0xFF2c3e50)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _metodoPago == 'qr'
                              ? const Color(0xFF2c3e50)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code,
                              color: _metodoPago == 'qr'
                                  ? Colors.white
                                  : Colors.grey,
                              size: 28),
                          const SizedBox(height: 6),
                          Text('QR',
                              style: TextStyle(
                                  color: _metodoPago == 'qr'
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // QR estático si elige QR
            if (_metodoPago == 'qr') ...[
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_2, size: 120,
                          color: Color(0xFF2c3e50)),
                      const SizedBox(height: 8),
                      const Text('Escanea para pagar',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('EmergenciasVial · ${widget.emergencia['tipo_incidente']}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _metodoPago.isEmpty || _montoController.text.isEmpty
    ? null
    : () {
        final monto = double.tryParse(_montoController.text) ?? 0;
        widget.onFinalizar(monto, _metodoPago);
      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text('Finalizar servicio',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}