import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/session_provider.dart';
import 'session_details_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
    returnImage: false,
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.itf,
    ],
  );
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final FocusNode _quantityFocusNode = FocusNode();

  String? _currentBarcode;
  bool _isProcessing = false;
  bool _cameraPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    // Enable wakelock to keep screen on
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    // Disable wakelock when leaving scanner screen
    WakelockPlus.disable();
    _scannerController.dispose();
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() => _cameraPermissionGranted = true);
    } else {
      final result = await Permission.camera.request();
      setState(() => _cameraPermissionGranted = result.isGranted);

      if (!result.isGranted) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Нужно е разрешение за камера'),
        content: const Text(
          'Приложението има нужда от достъп до камерата за сканиране на баркодове.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Настройки'),
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing || _currentBarcode != null) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    // Validate that barcode contains only digits
    if (code != null && code.isNotEmpty && RegExp(r'^\d+$').hasMatch(code)) {
      setState(() {
        _currentBarcode = code;
        _isProcessing = true;
      });

      // Focus quantity field
      _quantityFocusNode.requestFocus();
      _quantityController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _quantityController.text.length,
      );
    }
  }

  Future<void> _addItem() async {
    if (_currentBarcode == null) return;

    final quantityText = _quantityController.text.trim();
    final quantity = int.tryParse(quantityText);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Моля въведете валидно количество')),
      );
      return;
    }

    try {
      final sessionProvider = context.read<SessionProvider>();
      await sessionProvider.addItem(_currentBarcode!, quantity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Добавен: $_currentBarcode x $quantity'),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Reset for next scan
      setState(() {
        _currentBarcode = null;
        _isProcessing = false;
        _quantityController.text = '1';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Грешка: $e')));
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _incrementQuantity() {
    final current = int.tryParse(_quantityController.text) ?? 1;
    _quantityController.text = (current + 1).toString();
  }

  void _decrementQuantity() {
    final current = int.tryParse(_quantityController.text) ?? 1;
    if (current > 1) {
      _quantityController.text = (current - 1).toString();
    }
  }

  void _cancelCurrentBarcode() {
    setState(() {
      _currentBarcode = null;
      _isProcessing = false;
      _quantityController.text = '1';
    });
  }

  Future<void> _completeSession() async {
    final sessionProvider = context.read<SessionProvider>();

    if (sessionProvider.currentItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Няма добавени артикули')));
      return;
    }

    // Navigate to session details screen
    if (mounted) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SessionDetailsScreen(session: sessionProvider.currentSession!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканиране на баркодове'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: _completeSession,
            tooltip: 'Завърши',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: !_cameraPermissionGranted
            ? const Center(child: Text('Няма разрешение за камера'))
            : Column(
                children: [
                  // Camera preview
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: _onBarcodeDetected,
                        ),
                        // Overlay with scan guide
                        Center(
                          child: Container(
                            width: 250,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Barcode display and quantity input
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Current barcode display
                        if (_currentBarcode != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Баркод: $_currentBarcode',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _cancelCurrentBarcode,
                                icon: const Icon(Icons.cancel),
                                color: Colors.red,
                                tooltip: 'Отказ',
                                iconSize: 28,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Quantity input
                        Row(
                          children: [
                            const Text(
                              'Количество:',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: _decrementQuantity,
                              icon: const Icon(Icons.remove_circle_outline),
                              iconSize: 32,
                            ),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _quantityController,
                                focusNode: _quantityFocusNode,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _incrementQuantity,
                              icon: const Icon(Icons.add_circle_outline),
                              iconSize: 32,
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _currentBarcode != null
                                  ? _addItem
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Добави',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Items list
                  Expanded(
                    flex: 2,
                    child: Consumer<SessionProvider>(
                      builder: (context, sessionProvider, child) {
                        final items = sessionProvider.currentItems;

                        if (items.isEmpty) {
                          return const Center(
                            child: Text('Няма сканирани артикули'),
                          );
                        }

                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Dismissible(
                              key: Key('item_${item.id}_$index'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Изтриване'),
                                    content: Text(
                                      'Изтриване на баркод ${item.barcode}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Не'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Да'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) async {
                                try {
                                  await sessionProvider.deleteItem(item.id!);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Артикулът е изтрит'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Грешка: $e')),
                                    );
                                  }
                                }
                              },
                              child: ListTile(
                                leading: const Icon(Icons.qr_code),
                                title: Text(
                                  item.barcode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Text(
                                  'x ${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
