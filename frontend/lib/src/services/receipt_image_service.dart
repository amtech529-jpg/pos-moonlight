import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DesktopReceiptImageService {
  // Pick image file from Windows file explorer
  static Future<File?> pickImageFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'bmp', 'gif'],
        dialogTitle: 'Select Receipt Image',
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image file: $e');
    }
  }

  // Save image to application data directory
  static Future<String> saveImageToAppDirectory(File imageFile) async {
    try {
      // Get Windows application data directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String receiptDir = path.join(appDir.path, 'AdvancePaymentApp', 'receipts');

      // Create receipts directory if it doesn't exist
      final Directory receiptDirectory = Directory(receiptDir);
      if (!await receiptDirectory.exists()) {
        await receiptDirectory.create(recursive: true);
      }

      // Generate unique filename with timestamp
      final String originalName = path.basename(imageFile.path);
      final String extension = path.extension(originalName);
      final String nameWithoutExt = path.basenameWithoutExtension(originalName);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${nameWithoutExt}_$timestamp$extension';
      final String newPath = path.join(receiptDir, fileName);

      // Copy file to app directory
      final File newFile = await imageFile.copy(newPath);
      return newFile.path;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  // Delete image file
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if image file exists
  static Future<bool> imageExists(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      return await imageFile.exists();
    } catch (e) {
      return false;
    }
  }

  // Get image file size in bytes
  static Future<int> getImageSize(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        return await imageFile.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Get image as bytes for display
  static Future<Uint8List?> getImageBytes(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        return await imageFile.readAsBytes();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Get file info including creation date
  static Future<Map<String, dynamic>> getFileInfo(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        final FileStat stats = await imageFile.stat();
        return {
          'size': stats.size,
          'created': stats.changed,
          'modified': stats.modified,
          'name': path.basename(imagePath),
          'extension': path.extension(imagePath),
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Open file in default Windows image viewer
  static Future<void> openInExternalViewer(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await Process.run('start', ['', imagePath], runInShell: true);
      }
    } catch (e) {
      throw Exception('Failed to open image in external viewer: $e');
    }
  }

  // Show in Windows Explorer
  static Future<void> showInExplorer(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await Process.run('explorer', ['/select,', imagePath], runInShell: true);
      }
    } catch (e) {
      throw Exception('Failed to show in explorer: $e');
    }
  }

  // Get supported image formats for Windows
  static List<String> getSupportedFormats() {
    return ['jpg', 'jpeg', 'png', 'bmp', 'gif', 'tiff', 'webp'];
  }

  // Validate image file
  static Future<bool> validateImageFile(File imageFile) async {
    try {
      final String extension = path.extension(imageFile.path).toLowerCase();
      final List<String> supportedFormats = getSupportedFormats();

      // Check extension
      if (!supportedFormats.contains(extension.replaceFirst('.', ''))) {
        return false;
      }

      // Check file size (max 10MB for desktop)
      final int fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        return false;
      }

      // Check if file can be read
      try {
        await imageFile.readAsBytes();
        return true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Copy image to clipboard (Windows specific)
  static Future<void> copyImageToClipboard(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        // PowerShell command to copy image to clipboard
        final String psCommand =
            '''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
\$img = [System.Drawing.Image]::FromFile("$imagePath")
[System.Windows.Forms.Clipboard]::SetImage(\$img)
\$img.Dispose()
''';

        await Process.run('powershell', ['-Command', psCommand], runInShell: true);
      }
    } catch (e) {
      throw Exception('Failed to copy image to clipboard: $e');
    }
  }

  // Create backup of receipt images
  static Future<String> createBackup() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String receiptDir = path.join(appDir.path, 'AdvancePaymentApp', 'receipts');
      final String backupDir = path.join(appDir.path, 'AdvancePaymentApp', 'backups');

      final Directory backupDirectory = Directory(backupDir);
      if (!await backupDirectory.exists()) {
        await backupDirectory.create(recursive: true);
      }

      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final String backupPath = path.join(backupDir, 'receipts_backup_$timestamp');

      final Directory sourceDir = Directory(receiptDir);
      if (await sourceDir.exists()) {
        await _copyDirectory(sourceDir, Directory(backupPath));
      }

      return backupPath;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  // Helper method to copy directory
  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);

    await for (final FileSystemEntity entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final Directory newDirectory = Directory(path.join(destination.path, path.basename(entity.path)));
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        final File newFile = File(path.join(destination.path, path.basename(entity.path)));
        await entity.copy(newFile.path);
      }
    }
  }

  // Get total storage used by receipts
  static Future<int> getTotalStorageUsed() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String receiptDir = path.join(appDir.path, 'AdvancePaymentApp', 'receipts');
      final Directory receiptDirectory = Directory(receiptDir);

      if (!await receiptDirectory.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final FileSystemEntity entity in receiptDirectory.list(recursive: true)) {
        if (entity is File) {
          final FileStat stats = await entity.stat();
          totalSize += stats.size;
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // Clean up old backup files (keep only last 5)
  static Future<void> cleanupOldBackups() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String backupDir = path.join(appDir.path, 'AdvancePaymentApp', 'backups');
      final Directory backupDirectory = Directory(backupDir);

      if (!await backupDirectory.exists()) {
        return;
      }

      final List<FileSystemEntity> backups = await backupDirectory.list().toList();
      backups.sort((a, b) => b.path.compareTo(a.path)); // Sort by name (timestamp)

      // Keep only the 5 most recent backups
      if (backups.length > 5) {
        for (int i = 5; i < backups.length; i++) {
          if (backups[i] is Directory) {
            await (backups[i] as Directory).delete(recursive: true);
          }
        }
      }
    } catch (e) {
      // Silently handle cleanup errors
    }
  }
}
