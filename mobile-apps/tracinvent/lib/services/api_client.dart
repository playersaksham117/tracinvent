import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  
  ApiClient({
    this.baseUrl = 'http://localhost:5000/api',
    http.Client? client,
  }) : _client = client ?? http.Client();
  
  // ========== Helper Methods ==========
  
  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Map<String, dynamic>> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Map<String, dynamic>> _delete(String endpoint) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // ========== Health Check ==========
  
  Future<bool> checkHealth() async {
    try {
      final result = await _get('/health');
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }
  
  // ========== Inventory Items ==========
  
  Future<Map<String, dynamic>> getInventoryItems({String? since}) async {
    String endpoint = '/inventory';
    if (since != null) {
      endpoint += '?since=$since';
    }
    return await _get(endpoint);
  }
  
  Future<Map<String, dynamic>> createInventoryItem(Map<String, dynamic> item) async {
    return await _post('/inventory', item);
  }
  
  Future<Map<String, dynamic>> updateInventoryItem(String id, Map<String, dynamic> item) async {
    return await _put('/inventory/$id', item);
  }
  
  Future<Map<String, dynamic>> deleteInventoryItem(String id) async {
    return await _delete('/inventory/$id');
  }
  
  // ========== Warehouses ==========
  
  Future<Map<String, dynamic>> getWarehouses({String? since}) async {
    String endpoint = '/warehouses';
    if (since != null) {
      endpoint += '?since=$since';
    }
    return await _get(endpoint);
  }
  
  Future<Map<String, dynamic>> createWarehouse(Map<String, dynamic> warehouse) async {
    return await _post('/warehouses', warehouse);
  }
  
  Future<Map<String, dynamic>> updateWarehouse(String id, Map<String, dynamic> warehouse) async {
    return await _put('/warehouses/$id', warehouse);
  }
  
  Future<Map<String, dynamic>> deleteWarehouse(String id) async {
    return await _delete('/warehouses/$id');
  }
  
  // ========== Stock ==========
  
  Future<Map<String, dynamic>> getStock({String? since}) async {
    String endpoint = '/stock';
    if (since != null) {
      endpoint += '?since=$since';
    }
    return await _get(endpoint);
  }
  
  Future<Map<String, dynamic>> createStock(Map<String, dynamic> stock) async {
    return await _post('/stock', stock);
  }
  
  Future<Map<String, dynamic>> updateStock(String id, Map<String, dynamic> stock) async {
    return await _put('/stock/$id', stock);
  }
  
  // ========== Transactions ==========
  
  Future<Map<String, dynamic>> getTransactions({String? since}) async {
    String endpoint = '/transactions';
    if (since != null) {
      endpoint += '?since=$since';
    }
    return await _get(endpoint);
  }
  
  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> transaction) async {
    return await _post('/transactions', transaction);
  }
  
  // ========== Sync ==========
  
  Future<Map<String, dynamic>> sync({
    required String? lastSync,
    required Map<String, dynamic> changes,
  }) async {
    return await _post('/sync', {
      'lastSync': lastSync,
      'changes': changes,
    });
  }
  
  void dispose() {
    _client.close();
  }
}
