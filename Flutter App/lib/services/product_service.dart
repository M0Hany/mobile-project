import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/store.dart';
import '../core/config.dart';
import '../services/auth_service.dart';
import 'package:logger/logger.dart';

class ProductService {
  final String baseUrl;
  final AuthService authService;
  final http.Client client;
  final _logger = Logger();

  ProductService({
    String? baseUrl,
    required this.authService,
    http.Client? client,
  })  : baseUrl = baseUrl ?? Config.getBaseUrl(),
        client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await authService.getStoredToken();
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      _logger.e('Error getting auth headers', error: e);
      rethrow;
    }
  }

  String _handleConnectionError(dynamic error) {
    if (error is SocketException) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    } else if (error is http.ClientException) {
      return 'Network error occurred. Please try again.';
    } else if (error is FormatException) {
      return 'Invalid response from server. Please try again.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  Future<List<Product>> getStoreProducts(int storeId) async {
    try {
      _logger.i('Fetching products for store $storeId');
      final response = await client
          .get(
        Uri.parse('$baseUrl/stores/$storeId/products'),
        headers: await _getHeaders(),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      final errorMessage = _handleConnectionError(e);
      _logger.e('Error fetching store products: $errorMessage', error: e);
      throw Exception(errorMessage);
    }
  }

  Future<Product> getProductDetails(int productId) async {
    try {
      _logger.i('Fetching details for product $productId');
      final response = await client.get(
        Uri.parse('$baseUrl/products/$productId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return Product.fromMap(json.decode(response.body));
      } else {
        throw Exception('Failed to load product details');
      }
    } catch (e) {
      _logger.e('Error fetching product details', error: e);
      rethrow;
    }
  }

  Future<List<String>> getProductCategories() async {
    try {
      _logger.i('Fetching product categories');
      final response = await client
          .get(
        Uri.parse('$baseUrl/products/categories'),
        headers: await _getHeaders(),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((category) => category.toString()).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      final errorMessage = _handleConnectionError(e);
      _logger.e('Error fetching product categories: $errorMessage', error: e);
      throw Exception(errorMessage);
    }
  }

  Future<List<Store>> searchProducts(String query) async {
    try {
      _logger.i('Searching stores with products matching: $query');

      // Encode the query parameter properly
      final encodedQuery = Uri.encodeQueryComponent(query);
      final uri = Uri.parse('$baseUrl/products/search').replace(
        queryParameters: {'query': encodedQuery},
      );

      _logger.d('Making request to: ${uri.toString()}');

      final response = await client
          .get(
        uri,
        headers: await _getHeaders(),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      _logger.d('Response status code: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          final store = Store.fromMap(json);
          if (json['matching_products'] != null) {
            store.products = (json['matching_products'] as List)
                .map((p) => Product.fromMap(p))
                .toList();
          }
          return store;
        }).toList();
      } else {
        String errorMessage;
        try {
          final errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ??
              errorBody['error'] ??
              'Failed to search stores';
        } catch (e) {
          errorMessage = 'Failed to search stores: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        _logger.e('Error parsing response', error: e);
        throw Exception('Invalid response format from server');
      } else if (e is TimeoutException) {
        _logger.e('Request timed out', error: e);
        throw Exception('Request timed out. Please try again.');
      } else if (e is SocketException) {
        _logger.e('Network error', error: e);
        throw Exception('Network error. Please check your connection.');
      } else {
        _logger.e('Error searching stores', error: e);
        final message = e.toString().replaceAll('Exception: ', '');
        throw Exception(message);
      }
    }
  }

  Future<List<String>> getProductSuggestions() async {
    try {
      _logger.i('Fetching product suggestions');
      final uri = Uri.parse('$baseUrl/products/suggestions');

      _logger.d('Making request to: ${uri.toString()}');

      final response = await client
          .get(
        uri,
        headers: await _getHeaders(),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      _logger.d('Product suggestions response status: ${response.statusCode}');
      _logger.d('Product suggestions response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((suggestion) => suggestion.toString()).toList();
      } else {
        String errorMessage;
        try {
          final errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ?? 'Failed to load suggestions';
        } catch (e) {
          errorMessage = 'Failed to load suggestions: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      final errorMessage = _handleConnectionError(e);
      _logger.e('Error fetching product suggestions: $errorMessage', error: e);
      throw Exception(errorMessage);
    }
  }
}
