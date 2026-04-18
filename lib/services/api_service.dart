import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://emergencias-vehiculares-api.onrender.com';

  // LOGIN
 static Future<Map<String, dynamic>?> login(String correo, String contrasena) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correo,
        'contrasena': contrasena,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Guardar datos del usuario
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access_token']);
      await prefs.setString('nombre', data['nombre']);
      await prefs.setInt('id_usuario', data['id_usuario']);
      await prefs.setInt('id_rol', data['id_rol']);
      
      return data;
    }
    return null;
  } catch (e) {
    return null;
  }
}

  // REGISTRO CONDUCTOR
  static Future<Map<String, dynamic>?> registrarConductor(Map<String, dynamic> datos) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conductores/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // OBTENER VEHICULOS
  static Future<List<dynamic>?> obtenerVehiculos(int idConductor) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehiculos/conductor/$idConductor'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // REGISTRAR VEHICULO
  static Future<Map<String, dynamic>?> registrarVehiculo(Map<String, dynamic> datos) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vehiculos/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  static Future<Map<String, dynamic>?> solicitarRecuperacion(String correo) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/recuperacion/solicitar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  } catch (e) {
    return null;
  }
}

static Future<bool> verificarToken(String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/recuperacion/verificar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

static Future<bool> cambiarContrasena(String token, String nuevaContrasena) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/recuperacion/cambiar-contrasena'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'nueva_contrasena': nuevaContrasena}),
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
static Future<Map<String, dynamic>?> obtenerConductorPorUsuario(int idUsuario) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/conductores/por-usuario/$idUsuario'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  } catch (e) {
    return null;
  }
}

static Future<bool> eliminarVehiculo(int idVehiculo) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/vehiculos/$idVehiculo'),
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

static Future<Map<String, dynamic>?> actualizarVehiculo(
    int idVehiculo, Map<String, dynamic> datos) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/vehiculos/$idVehiculo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  } catch (e) {
    return null;
  }
}
}