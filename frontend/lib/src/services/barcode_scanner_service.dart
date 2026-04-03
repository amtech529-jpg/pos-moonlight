import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/product/product_model.dart';
import 'api_client.dart';
import '../utils/debug_helper.dart';

class BarcodeScannerService {
  static final BarcodeScannerService _instance = BarcodeScannerService._internal();

  factory BarcodeScannerService() => _instance;

  BarcodeScannerService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Search product by barcode for scanner
  Future<ApiResponse<ProductModel>> searchProductByBarcode(String barcode) async {
    try {
      debugPrint('🔍 Searching product by barcode: $barcode');

      final response = await _apiClient.get('${ApiConfig.products}/search/barcode/$barcode/');

      DebugHelper.printApiResponse('GET Product by Barcode', response.data);

      if (response.statusCode == 200) {
        final product = ProductModel.fromJson(response.data['data']);
        
        debugPrint('✅ Product found: ${product.name}');
        
        return ApiResponse<ProductModel>(
          success: true,
          message: 'Product found successfully',
          data: product,
        );
      } else {
        return ApiResponse<ProductModel>(
          success: false,
          message: response.data['message'] ?? 'Product not found',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('barcode search', e);
      
      if (e.response?.statusCode == 404) {
        return ApiResponse<ProductModel>(
          success: false,
          message: 'Product not found with this barcode',
        );
      }
      
      return ApiResponse<ProductModel>(
        success: false,
        message: 'Network error occurred while searching product',
        errors: {'detail': e.message},
      );
    } catch (e) {
      DebugHelper.printError('barcode search', e);
      return ApiResponse<ProductModel>(
        success: false,
        message: 'An unexpected error occurred',
        errors: {'detail': e.toString()},
      );
    }
  }

  /// Validate barcode format
  bool isValidBarcodeFormat(String barcode) {
    // Remove any whitespace
    final cleanBarcode = barcode.trim();
    
    // Check if empty
    if (cleanBarcode.isEmpty) return false;
    
    // Check for EAN-13 format (13 digits, starts with 2 for our system)
    if (cleanBarcode.length == 13 && cleanBarcode.startsWith('2') && RegExp(r'^[0-9]+$').hasMatch(cleanBarcode)) {
      return true;
    }
    
    // Allow other barcode formats (UPC, Code128, etc.)
    // Basic validation: alphanumeric, 8-20 characters
    if (cleanBarcode.length >= 8 && cleanBarcode.length <= 20 && RegExp(r'^[A-Za-z0-9-_]+$').hasMatch(cleanBarcode)) {
      return true;
    }
    
    return false;
  }

  /// Clean and normalize barcode input
  String cleanBarcode(String barcode) {
    // Remove whitespace, newlines, and special characters
    return barcode.trim().replaceAll(RegExp(r'[\s\n\r\t]'), '');
  }
}
