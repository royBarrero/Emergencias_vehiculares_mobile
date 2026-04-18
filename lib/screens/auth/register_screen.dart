import 'package:flutter/material.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenciaController = TextEditingController();
  final _direccionController = TextEditingController();
  bool _obscurePassword = true;
  bool _cargando = false;

  void _registrar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _cargando = true);

      final respuesta = await ApiService.registrarConductor({
        'nombre': _nombreController.text,
        'correo': _correoController.text,
        'contrasena': _passwordController.text,
        'telefono': _telefonoController.text,
        'licencia': _licenciaController.text,
        'direccion': _direccionController.text,
      });

      setState(() => _cargando = false);

      if (respuesta != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro exitoso. Inicia sesión.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El correo ya está registrado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // HEADER
              Container(
                width: double.infinity,
                color: const Color(0xFF2c3e50),
                padding: const EdgeInsets.only(top: 60, bottom: 64, left: 32, right: 32),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add,
                        size: 38,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Crear cuenta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Regístrate como conductor',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // FORM CARD
              Transform.translate(
                offset: const Offset(0, -32),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Datos personales',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1a1a2e),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildField(
                        controller: _nombreController,
                        hint: 'Nombre completo',
                        icono: Icons.person_outline,
                        validator: (v) => v!.isEmpty ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 12),

                      _buildField(
                        controller: _correoController,
                        hint: 'Correo electrónico',
                        icono: Icons.email_outlined,
                        tipo: TextInputType.emailAddress,
                        validator: (v) {
                          if (v!.isEmpty) return 'Ingresa tu correo';
                          if (!v.contains('@')) return 'Correo no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildField(
                        controller: _telefonoController,
                        hint: 'Teléfono',
                        icono: Icons.phone_outlined,
                        tipo: TextInputType.phone,
                        validator: (v) => null,
                      ),
                      const SizedBox(height: 12),

                      // PASSWORD
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2c3e50)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2c3e50)),
                          ),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Ingresa tu contraseña';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildField(
                        controller: _licenciaController,
                        hint: 'Número de licencia (opcional)',
                        icono: Icons.card_membership_outlined,
                        validator: (v) => null,
                      ),
                      const SizedBox(height: 12),

                      _buildField(
                        controller: _direccionController,
                        hint: 'Dirección (opcional)',
                        icono: Icons.location_on_outlined,
                        validator: (v) => null,
                      ),
                      const SizedBox(height: 24),

                      // BOTON REGISTRAR
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _registrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2c3e50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _cargando
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Crear cuenta',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿Ya tienes cuenta? ',
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text(
                              'Inicia sesión',
                              style: TextStyle(
                                color: Color(0xFF2c3e50),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
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
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icono,
    TextInputType tipo = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2c3e50)),
        ),
      ),
      validator: validator,
    );
  }
}