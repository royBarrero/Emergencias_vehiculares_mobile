import 'package:flutter/material.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';
import 'seguimiento_emergencia_screen.dart';

class SeleccionarTallerScreen extends StatefulWidget {
  final int idEmergencia;

  const SeleccionarTallerScreen({super.key, required this.idEmergencia});

  @override
  State<SeleccionarTallerScreen> createState() =>
      _SeleccionarTallerScreenState();
}

class _SeleccionarTallerScreenState extends State<SeleccionarTallerScreen> {
  List<dynamic> _talleres = [];
  bool _cargando = true;
  bool _enviando = false;
  int? _tallerSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarTalleres();
  }

  void _cargarTalleres() async {
    final talleres =
        await ApiService.obtenerTalleresCercanos(widget.idEmergencia);
    setState(() {
      _talleres = talleres ?? [];
      _cargando = false;
    });
  }

  void _confirmarSeleccion() async {
    if (_tallerSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un taller para continuar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    final ok = await ApiService.seleccionarTaller(
      widget.idEmergencia,
      _tallerSeleccionado!,
    );

    setState(() => _enviando = false);

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SeguimientoEmergenciaScreen(
            idEmergencia: widget.idEmergencia,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al seleccionar el taller. Intenta de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        title: const Text('Seleccionar Taller'),
        elevation: 0,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2c3e50)),
            )
          : _talleres.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.car_repair,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay talleres disponibles cerca',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Intenta más tarde o amplía tu búsqueda',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _cargando = true);
                          _cargarTalleres();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2c3e50),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header informativo
                    Container(
                      color: const Color(0xFF2c3e50),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${_talleres.length} talleres disponibles cerca de ti',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Lista de talleres
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _talleres.length,
                        itemBuilder: (context, index) {
                          final taller = _talleres[index];
                          final seleccionado =
                              _tallerSeleccionado == taller['id_taller'];
                          final distancia =
                              taller['distancia_km']?.toStringAsFixed(1) ?? '?';
                          final servicios =
                              (taller['servicios'] as List<dynamic>?)
                                      ?.join(', ') ??
                                  'Sin servicios';
                          final calificacion =
                              taller['calificacion_promedio']?.toStringAsFixed(1) ??
                                  '0.0';

                          return GestureDetector(
                            onTap: () => setState(
                                () => _tallerSeleccionado = taller['id_taller']),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: seleccionado
                                      ? const Color(0xFFE53935)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: seleccionado
                                                ? const Color(0xFFE53935)
                                                    .withOpacity(0.1)
                                                : const Color(0xFF2c3e50)
                                                    .withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.car_repair,
                                            color: seleccionado
                                                ? const Color(0xFFE53935)
                                                : const Color(0xFF2c3e50),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                taller['nombre_taller'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: Color(0xFF1a1a2e),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                taller['direccion'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (seleccionado)
                                          const Icon(Icons.check_circle,
                                              color: Color(0xFFE53935),
                                              size: 24),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Distancia y calificación
                                    Row(
                                      children: [
                                        _buildChip(
                                          Icons.near_me,
                                          '$distancia km',
                                          const Color(0xFF2c3e50),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildChip(
                                          Icons.star,
                                          calificacion,
                                          Colors.amber,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Servicios
                                    Row(
                                      children: [
                                        const Icon(Icons.build,
                                            size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            servicios,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Botón confirmar
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _enviando ? null : _confirmarSeleccion,
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
                              : const Text(
                                  'Confirmar selección',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildChip(IconData icono, String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}