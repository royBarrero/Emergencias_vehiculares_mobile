import 'package:flutter/material.dart';
import 'package:emergencias_vehiculares/services/api_service.dart';

class RecuperarScreen extends StatefulWidget {
  const RecuperarScreen({super.key});

  @override
  State<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends State<RecuperarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;
  int _paso = 1; // 1=correo, 2=token, 3=nueva contraseña
  String _token = '';

  void _solicitarToken() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _cargando = true);

      final respuesta = await ApiService.solicitarRecuperacion(
        _correoController.text,
      );

      setState(() => _cargando = false);

      if (respuesta != null) {
        setState(() {
          _token = respuesta['token'] ?? '';
          _paso = 2;
            _tokenController.text = _token;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token generado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No existe una cuenta con ese correo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _verificarToken() async {
    if (_tokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el token')),
      );
      return;
    }

    setState(() => _cargando = true);

    final valido = await ApiService.verificarToken(_tokenController.text);

    setState(() => _cargando = false);

    if (valido) {
      setState(() => _paso = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token inválido o expirado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cambiarPassword() async {
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mínimo 6 caracteres')),
      );
      return;
    }

    setState(() => _cargando = true);

    final ok = await ApiService.cambiarContrasena(
      _tokenController.text,
      _passwordController.text,
    );

    setState(() => _cargando = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cambiar la contraseña'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
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
                      Icons.lock_reset,
                      size: 38,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Recuperar contraseña',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _paso == 1 ? 'Paso 1: Ingresa tu correo' :
                    _paso == 2 ? 'Paso 2: Verifica el token' :
                    'Paso 3: Nueva contraseña',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      // PASO 1 - CORREO
                      if (_paso == 1) ...[
                        const Text(
                          'Ingresa tu correo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a1a2e),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Te enviaremos un token para recuperar tu cuenta',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _correoController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'correo@ejemplo.com',
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2c3e50)),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) {
                            if (v!.isEmpty) return 'Ingresa tu correo';
                            if (!v.contains('@')) return 'Correo no válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _solicitarToken,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2c3e50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _cargando
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Enviar token',
                                    style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ],

                      // PASO 2 - TOKEN
                      if (_paso == 2) ...[
                        const Text(
                          'Verifica el token',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a1a2e),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ingresa el token que recibiste',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        if (_token.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFF2c3e50), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Token: $_token',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tokenController,
                          decoration: InputDecoration(
                            hintText: 'Ingresa el token',
                            prefixIcon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF2c3e50)),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _verificarToken,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2c3e50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _cargando
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Verificar token',
                                    style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ],

                      // PASO 3 - NUEVA CONTRASEÑA
                      if (_paso == 3) ...[
                        const Text(
                          'Nueva contraseña',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a1a2e),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ingresa tu nueva contraseña',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Nueva contraseña',
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2c3e50)),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _cambiarPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2c3e50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _cargando
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Cambiar contraseña',
                                    style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text(
                          'Volver al login',
                          style: TextStyle(
                            color: Color(0xFF2c3e50),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}