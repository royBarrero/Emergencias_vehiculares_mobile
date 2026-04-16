import 'dart:convert';
import 'package:http/http.dart' as http;

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
        return jsonDecode(response.body);
      } else {
        return null;
      }
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
}