import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/src/providers/customer_provider.dart';
import 'package:frontend/src/providers/import_export_provider.dart';
import 'package:frontend/src/providers/product_provider.dart';
import 'package:provider/provider.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  late ImportExportProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ImportExportProvider>();
    _provider.addListener(_onProviderChange);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    if (!mounted) return;
    final msg = _provider.message;
    
    if (msg != null && msg.isNotEmpty) {
      final isError = msg.toLowerCase().contains('failed') || msg.toLowerCase().contains('error');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      
      // Clear the message immediately so it doesn't trigger again or stay in state
      // Use addPostFrameCallback to avoid modifying state during build cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _provider.clearMessage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ImportExportProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Import Data
                  Expanded(
                    child: _buildImportSection(context, provider),
                  ),
                  const SizedBox(width: 32),
                  // Right Column: Export & Templates
                  Expanded(
                    child: _buildExportSection(context, provider),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImportSection(BuildContext context, ImportExportProvider provider) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              "Import Data",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          _buildUploadBox(
            title: "Upload Inventory (Excel/CSV)",
            isLoading: provider.isImportingInventory,
            onBrowse: () => provider.importInventory(productProvider),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Divider(height: 64, thickness: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildUploadBox(
            title: "Upload Customer (Excel/CSV)",
            isLoading: provider.isImportingCustomers,
            onBrowse: () => provider.importCustomers(customerProvider),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildUploadBox({required String title, required bool isLoading, required VoidCallback onBrowse}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          // Dashed border container
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: DashedRectPainter(color: Colors.grey.shade400),
              child: InkWell(
                onTap: isLoading ? null : onBrowse,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      const CircularProgressIndicator()
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                          children: [
                            const TextSpan(text: "Drag & drop your file here\nor "),
                            TextSpan(
                              text: "Browse",
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.8),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Max file size: 105 MB",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "Supported formats: csv or .xlsx",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection(BuildContext context, ImportExportProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Export & Templates",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 48),
          
          Text(
            "Download Sample Templates",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            text: "Download Inventory Templates",
            icon: Icons.file_download_outlined,
            onPressed: () => provider.downloadInventoryTemplate(),
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            text: "Customer Templates",
            icon: Icons.file_download_outlined,
            onPressed: () => provider.downloadCustomerTemplate(),
            width: 220,
          ),
          
          const SizedBox(height: 64),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 48),
          
          Text(
            "Bulk Data Onboarding History",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          if (provider.importHistory.isEmpty)
            Text(
              "No recent imports.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...provider.importHistory.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildHistoryItem("Uploaded ${item['fileName']}", item['count']!),
            )),
          
          const SizedBox(height: 64),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 48),
          
          Text(
            "Export Full Data (Excel)",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            text: "Export All Inventory",
            isLoading: provider.isExportingInventory,
            onPressed: () => provider.exportAllInventory(),
            width: 240,
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            text: "Export All Customers",
            isLoading: provider.isExportingCustomers,
            onPressed: () => provider.exportAllCustomers(),
            width: 240,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    IconData? icon,
    bool isLoading = false,
    required VoidCallback onPressed,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7E87FF),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            else ...[
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String fileName, String count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            fileName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB8B48D), // Mustard/Olive color from image
            ),
          ),
        ),
        Text(
          "• $count",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;

  DashedRectPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.dash = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(12)));

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final Path metrics = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = dash;
        metrics.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length + gap;
      }
    }
    canvas.drawPath(metrics, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
