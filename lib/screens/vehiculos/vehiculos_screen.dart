import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';

class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});

  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
  List<dynamic> _vehiculos = [];
  bool _cargando = true;
  int _idConductor = 0;

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  void _cargarVehiculos() async {
    final prefs = await SharedPreferences.getInstance();
    final idUsuario = prefs.getInt('id_usuario') ?? 0;

    final conductor = await ApiService.obtenerConductorPorUsuario(idUsuario);
    if (conductor != null) {
      _idConductor = conductor['id_conductor'];
      final vehiculos = await ApiService.obtenerVehiculos(_idConductor);
      setState(() {
        _vehiculos = vehiculos ?? [];
        _cargando = false;
      });
    } else {
      setState(() => _cargando = false);
    }
  }

  void _mostrarFormulario({Map<String, dynamic>? vehiculo}) {
    final _marcaController = TextEditingController(text: vehiculo?['marca'] ?? '');
    final _modeloController = TextEditingController(text: vehiculo?['modelo'] ?? '');
    final _anioController = TextEditingController(text: vehiculo?['anio']?.toString() ?? '');
    final _placaController = TextEditingController(text: vehiculo?['placa'] ?? '');
    final _colorController = TextEditingController(text: vehiculo?['color'] ?? '');
    String _tipoSeleccionado = vehiculo?['tipo_vehiculo'] ?? 'auto';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vehiculo == null ? 'Agregar vehículo' : 'Editar vehículo',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a1a2e),
                  ),
                ),
                const SizedBox(height: 20),

                _buildCampo(_marcaController, 'Marca', Icons.directions_car),
                const SizedBox(height: 12),
                _buildCampo(_modeloController, 'Modelo', Icons.model_training),
                const SizedBox(height: 12),
                _buildCampo(_anioController, 'Año', Icons.calendar_today,
                    tipo: TextInputType.number),
                const SizedBox(height: 12),
                _buildCampo(_placaController, 'Placa', Icons.confirmation_number),
                const SizedBox(height: 12),
                _buildCampo(_colorController, 'Color', Icons.color_lens),
                const SizedBox(height: 12),

                const Text('Tipo de vehículo',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _tipoSeleccionado,
                      isExpanded: true,
                      items: ['auto', 'moto', 'camioneta'].map((tipo) =>
                        DropdownMenuItem(value: tipo, child: Text(tipo))
                      ).toList(),
                      onChanged: (val) => setModalState(() => _tipoSeleccionado = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final datos = {
                        'id_conductor': _idConductor,
                        'marca': _marcaController.text,
                        'modelo': _modeloController.text,
                        'anio': int.tryParse(_anioController.text),
                        'placa': _placaController.text,
                        'color': _colorController.text,
                        'tipo_vehiculo': _tipoSeleccionado,
                      };

                      if (vehiculo == null) {
                        await ApiService.registrarVehiculo(datos);
                      } else {
                        await ApiService.actualizarVehiculo(
                            vehiculo['id_vehiculo'], datos);
                      }

                      Navigator.pop(context);
                      _cargarVehiculos();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2c3e50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      vehiculo == null ? 'Agregar' : 'Guardar cambios',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _eliminarVehiculo(int idVehiculo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: const Text('¿Estás seguro que deseas eliminar este vehículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await ApiService.eliminarVehiculo(idVehiculo);
              Navigator.pop(context);
              _cargarVehiculos();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCampo(TextEditingController controller, String hint, IconData icono,
      {TextInputType tipo = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: tipo,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icono, color: const Color(0xFF2c3e50)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: const Color(0xFFF5F5F5),
  appBar: AppBar(
    backgroundColor: const Color(0xFF2c3e50),
    foregroundColor: Colors.white,
    title: const Text('Mis Vehículos'),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.pop(context),
    ),
  ),
  body: Column(
    children: [
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _vehiculos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_car_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No tienes vehículos registrados',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _mostrarFormulario(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2c3e50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Agregar vehículo',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _vehiculos.length,
                        itemBuilder: (context, index) {
                          final v = _vehiculos[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
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
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2c3e50).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.directions_car,
                                      color: Color(0xFF2c3e50)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${v['marca']} ${v['modelo']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Color(0xFF1a1a2e),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Placa: ${v['placa']} • ${v['color'] ?? ''} • ${v['tipo_vehiculo'] ?? ''}',
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'editar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'eliminar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline,
                                              size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Eliminar',
                                              style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'editar') {
                                      _mostrarFormulario(vehiculo: v);
                                    } else {
                                      _eliminarVehiculo(v['id_vehiculo']);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _vehiculos.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _mostrarFormulario(),
              backgroundColor: const Color(0xFF2c3e50),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}