/// API Service
/// Handles HTTP communication with FastAPI backend
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiService {
  static const String _defaultBaseUrl = 'http://127.0.0.1:8000';
  final String baseUrl;
  final http.Client _client;

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _defaultBaseUrl,
        _client = client ?? http.Client();

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<dynamic> _get(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams,
      );
      final response = await _client.get(uri, headers: _headers);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Unable to connect to server. Please ensure the backend is running.');
    }
  }

  Future<dynamic> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Unable to connect to server. Please ensure the backend is running.');
    }
  }

  Future<dynamic> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.put(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Unable to connect to server. Please ensure the backend is running.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String message = 'Unknown error';
      try {
        final error = jsonDecode(response.body);
        message = error['detail'] ?? error['message'] ?? message;
      } catch (_) {
        message = response.body;
      }
      throw ApiException(message, response.statusCode);
    }
  }

  // ============================================================================
  // HEALTH CHECK
  // ============================================================================

  Future<bool> healthCheck() async {
    try {
      await _get('/health');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================================
  // COMPANY PROFILE
  // ============================================================================

  Future<CompanyProfile?> getCompanyProfile() async {
    try {
      final data = await _get('/api/company');
      return CompanyProfile.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> saveCompanyProfile(CompanyProfile company) async {
    await _post('/api/company', company.toJson());
  }

  // ============================================================================
  // STATES
  // ============================================================================

  Future<List<IndianState>> getStates() async {
    final data = await _get('/api/states');
    return (data as List).map((e) => IndianState.fromJson(e)).toList();
  }

  // ============================================================================
  // LEDGERS (PARTIES)
  // ============================================================================

  Future<List<Ledger>> getLedgers({
    int? groupId,
    String? nature,
    bool? isParty,
    String? search,
    bool isActive = true,
  }) async {
    final params = <String, String>{'is_active': isActive.toString()};
    if (groupId != null) params['group_id'] = groupId.toString();
    if (nature != null && nature.isNotEmpty && nature != 'ALL')
      params['nature'] = nature;
    if (isParty != null) params['is_party'] = isParty.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;

    final data = await _get('/api/ledgers', queryParams: params);
    return (data as List).map((e) => Ledger.fromJson(e)).toList();
  }

  Future<Ledger> getLedger(int id) async {
    final data = await _get('/api/ledgers/$id');
    return Ledger.fromJson(data);
  }

  Future<List<LedgerGroup>> getLedgerGroups() async {
    final data = await _get('/api/ledger-groups');
    return (data as List).map((e) => LedgerGroup.fromJson(e)).toList();
  }

  Future<int> createLedger(Ledger ledger) async {
    final response = await _post('/api/ledgers', ledger.toJson());
    return response['data']['id'];
  }

  Future<void> updateLedger(int id, Map<String, dynamic> updates) async {
    await _put('/api/ledgers/$id', updates);
  }

  // ============================================================================
  // HSN CODES
  // ============================================================================

  Future<List<HSNCode>> getHSNCodes({String? search, String? type}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (type != null) params['type'] = type;

    final data = await _get('/api/hsn-codes', queryParams: params);
    return (data as List).map((e) => HSNCode.fromJson(e)).toList();
  }

  Future<int> createHSNCode(HSNCode hsn) async {
    final response = await _post('/api/hsn-codes', hsn.toJson());
    return response['data']['id'];
  }

  // ============================================================================
  // ITEMS
  // ============================================================================

  Future<List<Item>> getItems({
    String? search,
    int? categoryId,
    bool lowStock = false,
    bool isActive = true,
    int page = 1,
    int pageSize = 50,
  }) async {
    final params = <String, String>{
      'is_active': isActive.toString(),
      'low_stock': lowStock.toString(),
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoryId != null) params['category_id'] = categoryId.toString();

    final data = await _get('/api/items', queryParams: params);
    return (data as List).map((e) => Item.fromJson(e)).toList();
  }

  Future<List<ItemSearchResult>> searchItems(String query,
      {int limit = 20}) async {
    final params = {'q': query, 'limit': limit.toString()};
    final data = await _get('/api/items/search', queryParams: params);
    return (data as List).map((e) => ItemSearchResult.fromJson(e)).toList();
  }

  Future<List<HSNCode>> searchHSNCodes(String query, {int limit = 50}) async {
    final params = {'q': query, 'limit': limit.toString()};
    final data = await _get('/api/hsn/search', queryParams: params);
    return (data as List).map((e) => HSNCode.fromJson(e)).toList();
  }

  Future<ItemSearchResult?> getItemByBarcode(String barcode) async {
    try {
      final data = await _get('/api/items/barcode/$barcode');
      return ItemSearchResult.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Item> getItem(int id) async {
    final data = await _get('/api/items/$id');
    return Item.fromJson(data);
  }

  Future<int> createItem(Item item) async {
    final response = await _post('/api/items', item.toJson());
    return response['data']['id'];
  }

  Future<void> updateItem(int id, Map<String, dynamic> updates) async {
    await _put('/api/items/$id', updates);
  }

  // ============================================================================
  // INVOICES
  // ============================================================================

  Future<List<GSTInvoice>> getInvoices({
    int? voucherTypeId,
    int? partyId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (voucherTypeId != null) {
      params['voucher_type_id'] = voucherTypeId.toString();
    }
    if (partyId != null) params['party_id'] = partyId.toString();
    if (status != null) params['status'] = status;
    if (fromDate != null) {
      params['from_date'] = fromDate.toIso8601String().split('T')[0];
    }
    if (toDate != null) {
      params['to_date'] = toDate.toIso8601String().split('T')[0];
    }

    final data = await _get('/api/invoices', queryParams: params);
    return (data as List).map((e) => GSTInvoice.fromJson(e)).toList();
  }

  Future<GSTInvoice> getInvoice(int id) async {
    final data = await _get('/api/invoices/$id');
    return GSTInvoice.fromJson(data);
  }

  Future<Map<String, dynamic>> createInvoice(GSTInvoice invoice) async {
    final response = await _post('/api/invoices', invoice.toJson());
    return response['data'];
  }

  Future<void> cancelInvoice(int id, {String reason = ''}) async {
    await _put('/api/invoices/$id/cancel', {'reason': reason});
  }

  // ============================================================================
  // INVENTORY
  // ============================================================================

  Future<List<Map<String, dynamic>>> getStockSummary(
      {bool lowStockOnly = false}) async {
    final params = {'low_stock_only': lowStockOnly.toString()};
    final data =
        await _get('/api/inventory/stock-summary', queryParams: params);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<double> adjustInventory({
    required int itemId,
    required double quantity,
    required String adjustmentType,
    required String reason,
    String? reference,
  }) async {
    final response = await _post('/api/inventory/adjust', {
      'item_id': itemId,
      'quantity': quantity,
      'adjustment_type': adjustmentType,
      'reason': reason,
      'reference': reference,
    });
    return response['data']['new_stock'];
  }

  Future<List<Map<String, dynamic>>> getInventoryMovements({
    int? itemId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (itemId != null) params['item_id'] = itemId.toString();
    if (fromDate != null) {
      params['from_date'] = fromDate.toIso8601String().split('T')[0];
    }
    if (toDate != null) {
      params['to_date'] = toDate.toIso8601String().split('T')[0];
    }
    final data = await _get('/api/inventory/movements', queryParams: params);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createInventoryMovement(
      Map<String, dynamic> payload) async {
    final response = await _post('/api/inventory/movements', payload);
    return response['data'] ?? {};
  }

  Future<List<Map<String, dynamic>>> getItemBatches(int itemId) async {
    final params = {'item_id': itemId.toString()};
    final data = await _get('/api/inventory/batches', queryParams: params);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getItemSerials(int itemId,
      {String? status}) async {
    final params = {'item_id': itemId.toString()};
    if (status != null) params['status'] = status;
    final data = await _get('/api/inventory/serials', queryParams: params);
    return (data as List).cast<Map<String, dynamic>>();
  }

  // ============================================================================
  // REPORTS
  // ============================================================================

  Future<Map<String, dynamic>> getSalesSummary(
      DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    final data = await _get('/api/reports/sales-summary', queryParams: params);
    return data;
  }

  Future<Map<String, dynamic>> getGSTSummary(
      DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    final data = await _get('/api/reports/gst-summary', queryParams: params);
    return data;
  }

  Future<List<TaxSummary>> getHSNSummary(
      DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    final data = await _get('/api/reports/hsn-summary', queryParams: params);
    return (data as List).map((e) => TaxSummary.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getOutstandingInvoices() async {
    final data = await _get('/api/reports/outstanding');
    return (data as List).cast<Map<String, dynamic>>();
  }

  // ============================================================================
  // ITR REPORTS
  // ============================================================================

  Future<Map<String, dynamic>> getProfitLoss(
      DateTime fromDate, DateTime toDate, {int? financialYearId}) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
      if (financialYearId != null) 'financial_year_id': financialYearId.toString(),
    };
    return await _get('/api/reports/itr/pl', queryParams: params);
  }

  Future<Map<String, dynamic>> getBalanceSheet(
      DateTime asOnDate, {int? financialYearId}) async {
    final params = {
      'as_on_date': asOnDate.toIso8601String().split('T')[0],
      if (financialYearId != null) 'financial_year_id': financialYearId.toString(),
    };
    return await _get('/api/reports/itr/balance-sheet', queryParams: params);
  }

  Future<Map<String, dynamic>> getDepreciationReport(
      DateTime fromDate, DateTime toDate, {int? financialYearId}) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
      if (financialYearId != null) 'financial_year_id': financialYearId.toString(),
    };
    return await _get('/api/reports/itr/depreciation', queryParams: params);
  }

  Future<Map<String, dynamic>> getCapitalAccountReport(
      DateTime fromDate, DateTime toDate, {int? financialYearId}) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
      if (financialYearId != null) 'financial_year_id': financialYearId.toString(),
    };
    return await _get('/api/reports/itr/capital-account', queryParams: params);
  }

  Future<Map<String, dynamic>> getLoanSchedules({int? loanId}) async {
    final params = loanId != null ? {'loan_id': loanId.toString()} : null;
    return await _get('/api/reports/itr/loan-schedules', queryParams: params);
  }

  // ============================================================================
  // GST REPORTS
  // ============================================================================

  Future<Map<String, dynamic>> getInvoiceClassification(
      DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    return await _get('/api/reports/gst/invoice-classification', queryParams: params);
  }

  Future<List<Map<String, dynamic>>> getGSTHSNSummary(
      DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    final data = await _get('/api/reports/gst/hsn-summary', queryParams: params);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getITCReport(
      DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    return await _get('/api/reports/gst/itc', queryParams: params);
  }

  Future<Map<String, dynamic>> getTaxPayableReport(
      DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    return await _get('/api/reports/gst/tax-payable', queryParams: params);
  }

  Future<Map<String, dynamic>> getGSTAmendments({
    DateTime? fromDate,
    DateTime? toDate,
    int? invoiceId,
  }) async {
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate.toIso8601String().split('T')[0];
    if (toDate != null) params['to_date'] = toDate.toIso8601String().split('T')[0];
    if (invoiceId != null) params['invoice_id'] = invoiceId.toString();
    return await _get('/api/reports/gst/amendments', queryParams: params.isNotEmpty ? params : null);
  }

  // ============================================================================
  // STATUTORY COMPLIANCE
  // ============================================================================

  Future<Map<String, dynamic>> getTrialBalance(
      DateTime fromDate, DateTime toDate, {int? financialYearId}) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
      if (financialYearId != null) 'financial_year_id': financialYearId.toString(),
    };
    return await _get('/api/compliance/trial-balance', queryParams: params);
  }

  Future<List<dynamic>> getDayBook(DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    final data = await _get('/api/compliance/books/day-book', queryParams: params);
    return data is List ? data : [];
  }

  Future<List<dynamic>> getCashBook(DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    final data = await _get('/api/compliance/books/cash-book', queryParams: params);
    return data is List ? data : [];
  }

  Future<List<dynamic>> getBankBook(DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    final data = await _get('/api/compliance/books/bank-book', queryParams: params);
    return data is List ? data : [];
  }

  Future<List<dynamic>> getSalesRegister(DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    final data = await _get('/api/compliance/books/sales-register', queryParams: params);
    return data is List ? data : [];
  }

  Future<List<dynamic>> getPurchaseRegister(DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    final data = await _get('/api/compliance/books/purchase-register', queryParams: params);
    return data is List ? data : [];
  }

  Future<List<dynamic>> getJournalRegister(DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    final data = await _get('/api/compliance/books/journal-register', queryParams: params);
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> getGSTR1Data(DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    return await _get('/api/compliance/gstr1', queryParams: params);
  }

  Future<Map<String, dynamic>> getGSTR3BSummary(DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    return await _get('/api/compliance/gstr3b', queryParams: params);
  }

  Future<List<dynamic>> getITCTracking(DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    final data = await _get('/api/compliance/itc-tracking', queryParams: params);
    return data is List ? data : [];
  }

  Future<List<dynamic>> getMismatchAlerts({String status = 'OPEN'}) async {
    final data = await _get('/api/compliance/mismatch-alerts', queryParams: {'status': status});
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> getCapitalMovement(
      DateTime fromDate, DateTime toDate, {int? financialYearId}) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
      if (financialYearId != null) 'financial_year_id': financialYearId.toString(),
    };
    return await _get('/api/compliance/capital-movement', queryParams: params);
  }

  Future<Map<String, dynamic>> getTurnoverSummary(DateTime fromDate, DateTime toDate) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
    };
    return await _get('/api/compliance/turnover-summary', queryParams: params);
  }

  Future<Map<String, dynamic>> exportForCA(
      DateTime fromDate, DateTime toDate, List<String> reportTypes) async {
    final params = {
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
      'reports': reportTypes.join(','),
    };
    return await _get('/api/compliance/export-ca', queryParams: params);
  }

  Future<void> lockFinancialYear(int fyId, {String lockedBy = 'system'}) async {
    final uri = Uri.parse('$baseUrl/api/compliance/lock-year').replace(
      queryParameters: {'fy_id': fyId.toString(), 'locked_by': lockedBy},
    );
    final response = await _client.post(uri, headers: _headers);
    _handleResponse(response);
  }

  Future<void> markInvoiceFiled(int invoiceId, {String? arn}) async {
    final params = <String, String>{'invoice_id': invoiceId.toString()};
    if (arn != null) params['arn'] = arn;
    final uri = Uri.parse('$baseUrl/api/compliance/mark-invoice-filed').replace(
      queryParameters: params,
    );
    final response = await _client.post(uri, headers: _headers);
    _handleResponse(response);
  }

  /// Create amendment entry for filed invoices
  Future<Map<String, dynamic>> createAmendmentEntry({
    required String originalEntityType,
    required int originalEntityId,
    required String amendmentType,
    required String reason,
    required DateTime amendmentDate,
  }) async {
    final data = {
      'original_entity_type': originalEntityType,
      'original_entity_id': originalEntityId,
      'amendment_type': amendmentType,
      'reason': reason,
      'amendment_date': amendmentDate.toIso8601String().split('T')[0],
    };
    return await _post('/api/compliance/amendment-entry', data);
  }

  /// Get tax payment tracking for GST liabilities
  Future<List<Map<String, dynamic>>> getTaxPaymentTracking({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate.toIso8601String().split('T')[0];
    if (toDate != null) params['to_date'] = toDate.toIso8601String().split('T')[0];
    final data = await _get('/api/compliance/tax-payment-tracking', queryParams: params.isNotEmpty ? params : null);
    return data is List ? List<Map<String, dynamic>>.from(data) : [];
  }

  /// Get related party transactions for compliance
  Future<List<Map<String, dynamic>>> getRelatedPartyTransactions({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate.toIso8601String().split('T')[0];
    if (toDate != null) params['to_date'] = toDate.toIso8601String().split('T')[0];
    final data = await _get('/api/compliance/related-party-transactions', queryParams: params.isNotEmpty ? params : null);
    return data is List ? List<Map<String, dynamic>>.from(data) : [];
  }

  // ============================================================================
  // INVENTORY REPORTS
  // ============================================================================

  Future<Map<String, dynamic>> getInventoryValuation(
      {String method = 'fifo'}) async {
    final params = {'method': method};
    final data = await _get('/api/reports/inventory/valuation', queryParams: params);
    return data;
  }

  Future<List<Map<String, dynamic>>> getInventoryAging(
      {DateTime? asOf, List<int>? buckets}) async {
    final params = <String, String>{};
    if (asOf != null) {
      params['as_of'] = asOf.toIso8601String().split('T')[0];
    }
    if (buckets != null && buckets.isNotEmpty) {
      params['buckets'] = buckets.join(',');
    }
    final data = await _get('/api/reports/inventory/aging', queryParams: params);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getDeadStock({int days = 90}) async {
    final params = {'days': days.toString()};
    final data = await _get('/api/reports/inventory/dead-stock', queryParams: params);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getFastMoving(
      {int days = 30, int limit = 10}) async {
    final params = {'days': days.toString(), 'limit': limit.toString()};
    final data = await _get('/api/reports/inventory/fast-moving', queryParams: params);
    return (data as List).cast<Map<String, dynamic>>();
  }

  // ============================================================================
  // CRM
  // ============================================================================

  Future<List<Map<String, dynamic>>> getCrmPipeline() async {
    final data = await _get('/api/crm/pipeline');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCrmStaff() async {
    final data = await _get('/api/crm/staff');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createCrmStaff(Map<String, dynamic> payload) async {
    final response = await _post('/api/crm/staff', payload);
    return response['data'] ?? {};
  }

  Future<void> updateCrmStaff(int staffId, Map<String, dynamic> payload) async {
    await _put('/api/crm/staff/$staffId', payload);
  }

  Future<List<Map<String, dynamic>>> getCrmLeads({
    String? status,
    int? stageId,
    int? assignedStaffId,
    String? search,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (stageId != null) params['stage_id'] = stageId.toString();
    if (assignedStaffId != null) params['assigned_staff_id'] = assignedStaffId.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await _get('/api/crm/leads', queryParams: params);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createCrmLead(Map<String, dynamic> payload) async {
    final response = await _post('/api/crm/leads', payload);
    return response['data'] ?? {};
  }

  Future<void> updateCrmLead(int leadId, Map<String, dynamic> payload) async {
    await _put('/api/crm/leads/$leadId', payload);
  }

  Future<void> createCrmNote(Map<String, dynamic> payload) async {
    await _post('/api/crm/leads/notes', payload);
  }

  Future<void> createCrmCall(Map<String, dynamic> payload) async {
    await _post('/api/crm/leads/calls', payload);
  }

  Future<void> createCrmFollowUp(Map<String, dynamic> payload) async {
    await _post('/api/crm/leads/followups', payload);
  }

  Future<List<Map<String, dynamic>>> getCrmLeadTimeline(int leadId) async {
    final data = await _get('/api/crm/leads/$leadId/timeline');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCrmFollowUps({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final data = await _get('/api/crm/followups', queryParams: params);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCrmCustomers({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await _get('/api/crm/customers', queryParams: params);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getCrmReports() async {
    final data = await _get('/api/crm/reports');
    return data;
  }

  // ============================================================================
  // EXPENSES & OTHER INCOME
  // ============================================================================

  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    final data = await _get('/api/expenses/categories');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createExpenseCategory(Map<String, dynamic> payload) async {
    final response = await _post('/api/expenses/categories', payload);
    return response['data'] ?? {};
  }

  Future<List<Map<String, dynamic>>> getExpenses({
    int? categoryId,
    int? vendorLedgerId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final params = <String, String>{};
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (vendorLedgerId != null) params['vendor_ledger_id'] = vendorLedgerId.toString();
    if (fromDate != null) params['from_date'] = fromDate.toIso8601String().split('T')[0];
    if (toDate != null) params['to_date'] = toDate.toIso8601String().split('T')[0];
    final data = await _get('/api/expenses', queryParams: params);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> payload) async {
    final response = await _post('/api/expenses', payload);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> addExpenseAttachment(
    int expenseId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _post('/api/expenses/$expenseId/attachments', payload);
    return response['data'] ?? {};
  }

  Future<List<Map<String, dynamic>>> getRecurringExpenses() async {
    final data = await _get('/api/expenses/recurring');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createRecurringExpense(Map<String, dynamic> payload) async {
    final response = await _post('/api/expenses/recurring', payload);
    return response['data'] ?? {};
  }

  Future<void> runRecurringExpense(int recurringId) async {
    await _post('/api/expenses/recurring/$recurringId/run', {});
  }

  Future<List<Map<String, dynamic>>> getOtherIncome() async {
    final data = await _get('/api/other-income');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createOtherIncome(Map<String, dynamic> payload) async {
    final response = await _post('/api/other-income', payload);
    return response['data'] ?? {};
  }

  // ============================================================================
  // PARTIES / FIRMS
  // ============================================================================

  Future<List<Map<String, dynamic>>> getParties({
    String? partyType,
    bool isActive = true,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'is_active': isActive ? '1' : '0',
    };
    if (partyType != null && partyType.isNotEmpty) {
      queryParams['party_type'] = partyType;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    final data = await _get('/api/parties', queryParams: queryParams);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getParty(int partyId) async {
    return await _get('/api/parties/$partyId');
  }

  Future<List<Map<String, dynamic>>> getPartyHistory(int partyId) async {
    final data = await _get('/api/parties/$partyId/history');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createParty(Map<String, dynamic> payload) async {
    final response = await _post('/api/parties', payload);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateParty(int partyId, Map<String, dynamic> payload) async {
    final response = await _put('/api/parties/$partyId', payload);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> deactivateParty(int partyId, {String reason = ''}) async {
    final response = await _post('/api/parties/$partyId/deactivate', {'reason': reason});
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> reactivateParty(int partyId) async {
    final response = await _post('/api/parties/$partyId/reactivate', {});
    return response['data'] ?? {};
  }

  Future<bool> checkGstinExists(String gstin) async {
    try {
      final parties = await getParties(search: gstin);
      return parties.any((p) => p['gstin'] == gstin);
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // UNITS & VOUCHER TYPES
  // ============================================================================

  Future<List<Unit>> getUnits() async {
    final data = await _get('/api/units');
    return (data as List).map((e) => Unit.fromJson(e)).toList();
  }

  Future<List<VoucherType>> getVoucherTypes() async {
    final data = await _get('/api/voucher-types');
    return (data as List).map((e) => VoucherType.fromJson(e)).toList();
  }

  // ============================================================================
  // STATEMENTS (Party Ledger Statements)
  // ============================================================================

  /// Get party statement with all transactions (invoices, notes, payments)
  Future<PartyStatement> getPartyStatement({
    required int partyId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final queryParams = {
      'from_date': fromDate.toIso8601String().split('T').first,
      'to_date': toDate.toIso8601String().split('T').first,
    };
    final data = await _get('/api/statements/$partyId', queryParams: queryParams);
    return PartyStatement.fromJson(data);
  }

  /// Get summary of all party statements for overview
  Future<List<Map<String, dynamic>>> getStatementsOverview() async {
    final data = await _get('/api/statements/overview');
    return (data as List).cast<Map<String, dynamic>>();
  }

  void dispose() {
    _client.close();
  }
}
