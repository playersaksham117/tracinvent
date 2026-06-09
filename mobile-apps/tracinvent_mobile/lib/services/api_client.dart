import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  String _baseUrl;
  final http.Client _client;
  String? _authToken;

  ApiClient({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl ?? 'http://localhost:8000/api/v1',
        _client = client ?? http.Client();

  String get baseUrl => _baseUrl;

  void setAuthToken(String? token) => _authToken = token;

  void updateBaseUrl(String url) {
    _baseUrl = url;
    saveBaseUrl(url);
  }

  static Future<String> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sync_api_base_url') ?? 'http://localhost:8000/api/v1';
  }

  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sync_api_base_url', url);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .post(Uri.parse('$_baseUrl$endpoint'), headers: _headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': 'Server error: ${response.statusCode}: ${response.body}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> checkHealth() async {
    final result = await _get('/health');
    return result['success'] == true;
  }

  Future<Map<String, dynamic>> login({required String username, required String password}) async {
    return _post('/auth/login', {'username': username, 'password': password});
  }

  Future<Map<String, dynamic>> registerDevice({
    required String name,
    required String deviceType,
    String role = 'operator',
  }) async {
    return _post('/devices/register', {
      'name': name,
      'device_type': deviceType,
      'role': role,
    });
  }

  Future<Map<String, dynamic>> syncPush({required List<Map<String, dynamic>> changes}) async {
    return _post('/sync/push', {'changes': changes});
  }

  Future<Map<String, dynamic>> syncPull({String? since, List<String>? tables}) async {
    return _post('/sync/pull', {
      if (since != null) 'since': since,
      if (tables != null) 'tables': tables,
    });
  }

  void dispose() => _client.close();
}
