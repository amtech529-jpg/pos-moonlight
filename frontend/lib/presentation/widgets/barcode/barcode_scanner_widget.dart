import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import '../../../src/services/barcode_scanner_service.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String)? onBarcodeScanned;
  final bool autoAddToCart;
  final bool showFeedback;

  const BarcodeScannerWidget({
    super.key,
    this.onBarcodeScanned,
    this.autoAddToCart = true,
    this.showFeedback = true,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  final TextEditingController _barcodeController = TextEditingController();
  final BarcodeScannerService _scannerService = BarcodeScannerService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isScanning = false;
  String _lastScannedBarcode = '';
  String _statusMessage = '';
  bool _isSuccess = false;
  bool _isError = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the status message once localizations are available
    if (!_isInitialized) {
      _statusMessage = AppLocalizations.of(context)!.scannerReady;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeScanner() {
    // Auto-focus on the text field for scanner input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  Future<void> _playSuccessSound() async {
    if (!widget.showFeedback) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/success_beep.mp3'));
    } catch (e) {
      debugPrint('Audio not supported: $e');
    }
  }

  Future<void> _playErrorSound() async {
    if (!widget.showFeedback) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/error_beep.mp3'));
    } catch (e) {
      debugPrint('Audio not supported: $e');
    }
  }

  Future<void> _vibrate() async {
    if (!widget.showFeedback) return;
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      // Ignore vibration errors
    }
  }

  Future<void> _handleBarcodeInput(String barcode) async {
    if (_isScanning) return;

    final l10n = AppLocalizations.of(context)!;
    final cleanBarcode = _scannerService.cleanBarcode(barcode);

    if (!_scannerService.isValidBarcodeFormat(cleanBarcode)) {
      _showError(l10n.scannerInvalidFormat);
      return;
    }

    if (cleanBarcode == _lastScannedBarcode) {
      _showError(l10n.scannerDuplicateScan);
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = l10n.scannerScanning;
      _isSuccess = false;
      _isError = false;
    });

    try {
      final response = await _scannerService.searchProductByBarcode(cleanBarcode);

      if (response.success && response.data != null) {
        final product = response.data!;

        setState(() {
          _lastScannedBarcode = cleanBarcode;
          _statusMessage = l10n.scannerFound(product.name);
          _isSuccess = true;
          _isError = false;
        });

        await _playSuccessSound();
        await _vibrate();

        if (widget.autoAddToCart) {
          await _addProductToCart(product);
        }

        widget.onBarcodeScanned?.call(cleanBarcode);

        _barcodeController.clear();

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _statusMessage = l10n.scannerReady;
              _isSuccess = false;
              _isError = false;
            });
          }
        });

      } else {
        _showError(response.message ?? l10n.scannerProductNotFound);
      }

    } catch (e) {
      _showError(l10n.scannerFailed(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _addProductToCart(ProductModel product) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final salesProvider = context.read<SalesProvider>();

      salesProvider.addToCartWithCustomization(
        productId: product.id,
        productName: product.name,
        unitPrice: product.price ?? 0.0,
        quantity: 1,
        itemDiscount: 0.0,
        customizationNotes: null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text(l10n.scannerAddedToCart(product.name))),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text(l10n.scannerAddToCartFailed)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _statusMessage = message;
      _isError = true;
      _isSuccess = false;
    });

    _playErrorSound();
    _vibrate();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _statusMessage = l10n.scannerReady;
          _isError = false;
          _isSuccess = false;
        });
      }
    });

    _barcodeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.qr_code_scanner, color: AppTheme.primaryMaroon, size: context.iconSize('small')),
              SizedBox(width: context.smallPadding / 2),
              Text(
                l10n.scannerTitle,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              Spacer(),
              if (_isScanning)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
                      ),
                      SizedBox(width: 4),
                      Text(l10n.scannerScanning, style: TextStyle(fontSize: context.captionFontSize - 2, color: Colors.blue)),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: context.smallPadding),

          // Barcode input
          PremiumTextField(
            label: l10n.scannerLabel,
            hint: l10n.scannerHint,
            controller: _barcodeController,
            prefixIcon: Icons.qr_code_2_outlined,
            onChanged: (value) {
              if (_isSuccess || _isError) {
                setState(() {
                  _statusMessage = l10n.scannerReady;
                  _isSuccess = false;
                  _isError = false;
                });
              }
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _handleBarcodeInput(value.trim());
              }
            },
          ),

          SizedBox(height: context.smallPadding / 2),

          // Status message
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: 2),
            decoration: BoxDecoration(
              color: _isSuccess
                  ? Colors.green.withOpacity(0.1)
                  : _isError
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Text(
              _statusMessage.isEmpty ? l10n.scannerReady : _statusMessage,
              style: TextStyle(
                fontSize: context.captionFontSize - 1,
                fontWeight: FontWeight.w500,
                color: _isSuccess
                    ? Colors.green[700]
                    : _isError
                    ? Colors.red[700]
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}