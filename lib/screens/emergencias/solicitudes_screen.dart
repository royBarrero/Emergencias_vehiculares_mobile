import 'package:flutter/material.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';
import 'seguimiento_emergencia_screen.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  List<dynamic> _emergencias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEmergencias();
  }

  void _cargarEmergencias() async {
    final data = await ApiService.obtenerHistorialEmergencias();
    setState(() {
      _emergencias = data ?? [];
      _cargando = false;
    });
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'asignada':
        return Colors.blue;
      case 'en_camino':
        return Colors.blue;
      case 'atendiendo':
        return Colors.orange;
      case 'finalizada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getColorPrioridad(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return const Color(0xFFE53935);
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.search;
      case 'asignada':
        return Icons.check_circle_outline;
      case 'en_camino':
        return Icons.directions_car;
      case 'atendiendo':
        return Icons.build;
      case 'finalizada':
        return Icons.verified;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  void _verDetalle(Map<String, dynamic> emergencia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _DetalleEmergenciaSheet(emergencia: emergencia),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        title: const Text('Mis Solicitudes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2c3e50)),
            )
          : _emergencias.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tienes solicitudes registradas',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _emergencias.length,
              itemBuilder: (context, index) {
                final e = _emergencias[index];
                final estado = e['estado'] ?? 'pendiente';
                final prioridad = e['prioridad'] ?? 'baja';
                final activa = estado != 'finalizada' && estado != 'cancelada';

                return GestureDetector(
                  onTap: () => _verDetalle(Map<String, dynamic>.from(e)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: activa
                          ? Border.all(
                              color: _getColorEstado(estado).withOpacity(0.4),
                              width: 1.5,
                            )
                          : null,
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
                            color: _getColorEstado(estado).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getIconoEstado(estado),
                            color: _getColorEstado(estado),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e['tipo_incidente'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF1a1a2e),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e['direccion_aproximada'] ?? 'Sin dirección',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getColorEstado(
                                        estado,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      estado,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _getColorEstado(estado),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getColorPrioridad(
                                        prioridad,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      prioridad,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _getColorPrioridad(prioridad),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _DetalleEmergenciaSheet extends StatefulWidget {
  final Map<String, dynamic> emergencia;
  const _DetalleEmergenciaSheet({required this.emergencia});

  @override
  State<_DetalleEmergenciaSheet> createState() =>
      _DetalleEmergenciaSheetState();
}

class _DetalleEmergenciaSheetState extends State<_DetalleEmergenciaSheet> {
  Map<String, dynamic>? _detalle;
  Map<String, dynamic>? _taller;
  Map<String, dynamic>? _tecnico;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  void _cargarDetalle() async {
    final data = await ApiService.obtenerDetalleEmergencia(
      widget.emergencia['id_emergencia'],
    );
    if (mounted && data != null) {
      Map<String, dynamic>? taller;
      Map<String, dynamic>? tecnico;

      if (data['id_taller'] != null) {
        taller = await ApiService.obtenerTaller(data['id_taller']);
      }
      if (data['id_tecnico'] != null) {
        tecnico = await ApiService.obtenerTecnico(data['id_tecnico']);
      }

      setState(() {
        _detalle = data;
        _taller = taller;
        _tecnico = tecnico;
        _cargando = false;
      });
    } else {
      setState(() => _cargando = false);
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'asignada':
        return Colors.blue;
      case 'en_camino':
        return Colors.blue;
      case 'atendiendo':
        return Colors.orange;
      case 'finalizada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.emergencia;
    final estado = e['estado'] ?? 'pendiente';
    final activa = estado != 'finalizada' && estado != 'cancelada';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Título
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e['tipo_incidente'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getColorEstado(estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      estado,
                      style: TextStyle(
                        color: _getColorEstado(estado),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Info básica
              _buildFila(
                '📍 Ubicación',
                e['direccion_aproximada'] ?? 'Sin dirección',
              ),
              _buildFila('⚠️ Prioridad', (e['prioridad'] ?? '').toUpperCase()),

              if (_cargando)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF2c3e50)),
                  ),
                )
              else if (_detalle != null) ...[
                if (_taller != null)
                  _buildFila(
                    '🔧 Taller',
                    _taller!['nombre_taller'] ?? 'Taller asignado',
                  ),
                if (_tecnico != null)
                  _buildFila(
                    '👨‍🔧 Técnico',
                    _tecnico!['nombre'] ?? 'Técnico asignado',
                  ),
                if (_detalle!['descripcion'] != null &&
                    _detalle!['descripcion'] != '')
                  _buildFila('📝 Descripción', _detalle!['descripcion']),

                // Pago
                if (estado == 'finalizada') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💰 Información de pago',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2c3e50),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Monto del servicio',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'A coordinar con el taller',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estado del pago',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Pendiente de confirmación',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),

              // Botón ver seguimiento si está activa
              if (activa)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SeguimientoEmergenciaScreen(
                            idEmergencia: e['id_emergencia'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.track_changes),
                    label: const Text('Ver seguimiento'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2c3e50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1a1a2e),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
