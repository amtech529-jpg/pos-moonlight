import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:frontend/src/config/api_config.dart';
import 'package:frontend/src/services/api_client.dart';

class ImportExportService {
  final ApiClient _apiClient = ApiClient();

  /// Downloads a template for a specific model
  Future<void> downloadTemplate(String modelName) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.templateData(modelName),
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await _saveAndOpenFile(response.data, '${modelName}_template_$timestamp.xlsx');
      } else {
        debugPrint('Failed to download template: ${response.statusCode}');
        throw Exception('Failed to download template');
      }
    } catch (e) {
      debugPrint('Error downloading template: $e');
      rethrow;
    }
  }

  /// Exports data for a specific model
  Future<void> exportData(String modelName) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.exportData(modelName),
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await _saveAndOpenFile(response.data, '${modelName}_export_$timestamp.xlsx');
      } else {
         debugPrint('Failed to export data: ${response.statusCode}');
         throw Exception('Failed to export data');
      }
    } catch (e) {
      debugPrint('Error exporting data: $e');
      rethrow;
    }
  }

  /// Imports data for a specific model
  Future<Map<String, dynamic>> importData(String modelName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        
        FormData formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(file.path, filename: fileName),
        });

        final response = await _apiClient.post(
          ApiConfig.importData(modelName),
          data: formData,
        );

        if (response.statusCode == 200) {
          return response.data;
        } else {
          throw Exception('Failed to import data: ${response.statusCode}');
        }
      }
      return {'cancelled': true};
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow; 
    }
  }

  /// Helper to save bytes and open file
  Future<void> _saveAndOpenFile(List<int> bytes, String fileName) async {
    try {
      if (kIsWeb) {
        // Handle web download if needed (not implemented for now)
        return;
      } 
      
      Directory? directory = await getDownloadsDirectory();
      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }
      
      final String outputPath = p.join(directory.path, fileName);
      
      File(outputPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
      
      await OpenFile.open(outputPath);
    } catch (e) {
      debugPrint('Error saving file: $e');
      if (e.toString().contains('OS Error') || e.toString().contains('errno = 32')) {
        throw Exception('File is currently open in another program (like Excel). Please close it first.');
      }
      throw Exception('Failed to save file: $e');
    }
  }
}
