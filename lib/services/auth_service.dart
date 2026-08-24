import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

class AuthService {
  static const String baseUrl = 'http://localhost:3000/api/auth';
  static const int _sessionDurationMinutes = 5;

  static bool get isLoggedIn {
    final session = _getSession();
    if (session == null) return false;
    // Check if session expired
    final expiry = DateTime.tryParse(session['expiry'] ?? '');
    if (expiry == null || DateTime.now().isAfter(expiry)) {
      logout();
      return false;
    }
    return true;
  }

  static bool get isAdmin {
    final session = _getSession();
    return session?['role'] == 'admin';
  }

  static String get userName {
    final session = _getSession();
    return session?['name'] ?? '';
  }

  static int? get userId {
    final session = _getSession();
    final id = session?['id'];
    if (id == null) return null;
    return id is int ? id : int.tryParse(id.toString());
  }

  static Map<String, dynamic>? _getSession() {
    final stored = html.window.localStorage['helmet_session'];
    if (stored == null || stored.isEmpty) return null;
    try {
      return json.decode(stored);
    } catch (e) {
      return null;
    }
  }

  static void _saveSession(Map<String, dynamic> userData) {
    final expiry = DateTime.now().add(const Duration(minutes: _sessionDurationMinutes));
    userData['expiry'] = expiry.toIso8601String();
    html.window.localStorage['helmet_session'] = json.encode(userData);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _saveSession(data);
        return {'success': true};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Login gagal'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Tidak dapat terhubung ke server'};
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _saveSession(data);
        return {'success': true};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Registrasi gagal'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Tidak dapat terhubung ke server'};
    }
  }

  static void logout() {
    html.window.localStorage.remove('helmet_session');
  }
}
