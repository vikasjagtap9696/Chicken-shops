import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/stock_model.dart';
import '../models/sale_model.dart';
import '../models/customer_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class DatabaseService extends ChangeNotifier {
  static const String baseUrl = 'http://192.168.1.8:5000/api';
  
  List<StockModel> _stocks = [];
  List<SaleModel> _sales = [];
  List<CustomerModel> _customers = [];
  List<UserModel> _staff = [];
  String? _lastError;

  double _dailyRevenue = 0.0;
  double _monthlyRevenue = 0.0;
  bool _isLoading = false;

  List<StockModel> get stocks => _stocks;
  List<SaleModel> get sales => _sales;
  List<CustomerModel> get customers => _customers;
  List<UserModel> get staff => _staff;
  String? get lastError => _lastError;
  double get todaySales => _dailyRevenue;
  double get todayProfit => _dailyRevenue * 0.25; 
  double get totalStockValue => _stocks.fold(0, (sum, item) => sum + (item.currentStock * item.pricePerUnit));
  bool get isLoading => _isLoading;

  // Added missing fetchSales method
  Future<void> fetchSales(AuthService auth) async {
    await fetchDailySales(auth);
  }

  Future<void> fetchAllOrders(AuthService auth) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'), headers: auth.getAuthHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        _sales = data.map((json) => SaleModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Fetch All Orders Error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDailySales(AuthService auth, {String? date}) async {
    _isLoading = true;
    notifyListeners();
    try {
      String url = '$baseUrl/reports/daily-sales';
      if (date != null) url += '?date=$date';
      final response = await http.get(Uri.parse(url), headers: auth.getAuthHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = json.decode(response.body)['data']['orders'];
        _sales = ordersJson.map((json) => SaleModel.fromJson(json)).toList();
      }
    } catch (e) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createSale(Map<String, dynamic> saleData, AuthService auth) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/orders'), headers: auth.getAuthHeaders(), body: json.encode(saleData));
      if (response.statusCode == 201) {
        await fetchStocks(auth);
        await fetchRevenueSummary(auth);
        return true;
      }
      return false;
    } catch (e) { return false; }
  }

  Future<void> fetchStocks(AuthService auth) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('$baseUrl/stock/summary'), headers: auth.getAuthHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        _stocks = data.map((json) => StockModel.fromJson(json)).toList();
      }
    } catch (e) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> recordStockMovement(String productId, double quantity, String type, AuthService auth) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stock'),
        headers: auth.getAuthHeaders(),
        body: json.encode({
          'productId': productId,
          'quantity': quantity,
          'type': type,
          'date': DateTime.now().toIso8601String().split('T')[0]
        }),
      );
      if (response.statusCode == 201) {
        await fetchStocks(auth);
        return true;
      }
      return false;
    } catch (e) { return false; }
  }

  Future<void> fetchRevenueSummary(AuthService auth) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reports/revenue-summary'), headers: auth.getAuthHeaders());
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        _dailyRevenue = double.tryParse(data['dailyRevenue'].toString()) ?? 0.0;
        _monthlyRevenue = double.tryParse(data['monthlyRevenue'].toString()) ?? 0.0;
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<void> fetchCustomers(AuthService auth) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/customers'), headers: auth.getAuthHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        _customers = data.map((json) => CustomerModel.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<bool> addCustomer(CustomerModel customer, AuthService auth) async {
    _lastError = null;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers'), 
        headers: auth.getAuthHeaders(), 
        body: json.encode({
          'name': customer.name, 
          'phone': customer.phone.trim().isEmpty ? null : customer.phone.trim(), 
          'email': customer.email?.trim().isEmpty ?? true ? null : customer.email?.trim(), 
          'address': customer.address?.trim().isEmpty ?? true ? null : customer.address?.trim()
        })
      );
      
      final responseData = json.decode(response.body);
      if (response.statusCode == 201) { 
        await fetchCustomers(auth);
        return true; 
      } else {
        _lastError = responseData['message'] ?? 'Failed to add customer';
        return false;
      }
    } catch (e) { 
      _lastError = "Connection Error";
      return false; 
    }
  }

  Future<bool> updateCustomer(CustomerModel customer, AuthService auth) async {
    _lastError = null;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/customers/${customer.id}'), 
        headers: auth.getAuthHeaders(), 
        body: json.encode({
          'name': customer.name, 
          'phone': customer.phone.trim().isEmpty ? null : customer.phone.trim(), 
          'email': customer.email?.trim().isEmpty ?? true ? null : customer.email?.trim(), 
          'address': customer.address?.trim().isEmpty ?? true ? null : customer.address?.trim(),
          'creditBalance': customer.advanceBalance,
          'nextPaymentDate': customer.nextPaymentDate?.toIso8601String().split('T')[0]
        })
      );
      
      final responseData = json.decode(response.body);
      if (response.statusCode == 200) { 
        await fetchCustomers(auth); 
        return true; 
      } else {
        _lastError = responseData['message'] ?? 'Failed to update customer';
        return false;
      }
    } catch (e) { 
      _lastError = "Connection Error";
      return false; 
    }
  }

  Future<bool> deleteCustomer(String id, AuthService auth) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/customers/$id'), headers: auth.getAuthHeaders());
      if (response.statusCode == 200) { 
        _customers.removeWhere((c) => c.id == id); 
        notifyListeners(); 
        return true; 
      }
      return false;
    } catch (e) { return false; }
  }

  Future<void> fetchStaff(AuthService auth) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('$baseUrl/auth/staff'), headers: auth.getAuthHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        _staff = data.map((json) => UserModel.fromJson(json)).toList();
      }
    } catch (e) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addStaff(Map<String, dynamic> staffData, AuthService auth) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/auth/register'), headers: auth.getAuthHeaders(), body: json.encode(staffData));
      if (response.statusCode == 201) { await fetchStaff(auth); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> deleteStaff(String staffId, AuthService auth) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/auth/staff/$staffId'), headers: auth.getAuthHeaders());
      if (response.statusCode == 200) { _staff.removeWhere((s) => s.id == staffId); notifyListeners(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> addStock(Map<String, dynamic> data, AuthService auth) async {
    final res = await http.post(Uri.parse('$baseUrl/products'), headers: auth.getAuthHeaders(), body: json.encode(data));
    if (res.statusCode == 201) { await fetchStocks(auth); return true; }
    return false;
  }

  Future<bool> updateStock(String id, Map<String, dynamic> data, AuthService auth) async {
    final res = await http.put(Uri.parse('$baseUrl/products/$id'), headers: auth.getAuthHeaders(), body: json.encode(data));
    if (res.statusCode == 200) { await fetchStocks(auth); return true; }
    return false;
  }

  Future<bool> deleteStock(String id, AuthService auth) async {
    final res = await http.delete(Uri.parse('$baseUrl/products/$id'), headers: auth.getAuthHeaders());
    if (res.statusCode == 200) { _stocks.removeWhere((s) => s.productId == id); notifyListeners(); return true; }
    return false;
  }
}
