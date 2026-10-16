import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/scanning_session.dart';
import '../models/barcode_item.dart';
import '../providers/session_provider.dart';
import '../services/excel_export_service.dart';

class SessionDetailsScreen extends StatelessWidget {
  final ScanningSession session;

  const SessionDetailsScreen({super.key, required this.session});

  Future<void> _editQuantity(BuildContext context, BarcodeItem item) async {
    final controller = TextEditingController(text: item.quantity.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактиране на количество'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Баркод: ${item.barcode}'),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final current = int.tryParse(controller.text) ?? 1;
                    if (current > 1) {
                      controller.text = (current - 1).toString();
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 32,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Количество',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final current = int.tryParse(controller.text) ?? 1;
                    controller.text = (current + 1).toString();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 32,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text);
              if (quantity != null && quantity > 0) {
                Navigator.pop(context, quantity);
              }
            },
            child: const Text('Запази'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      try {
        await context.read<SessionProvider>().updateItemQuantity(
          item.id!,
          result,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Количеството е актуализирано')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Грешка: $e')));
        }
      }
    }
  }

  Future<void> _deleteItem(BuildContext context, BarcodeItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изтриване на Артикул'),
        content: Text('Изтриване на баркод ${item.barcode}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Изтрий'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await context.read<SessionProvider>().deleteItem(item.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Артикулът е изтрит')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Грешка: $e')));
        }
      }
    }
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final excelService = ExcelExportService();
      final filePath = await excelService.exportSessionToExcel(session);

      debugPrint('Excel file created at: $filePath');

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Share the file
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            subject: session.name,
            text: 'Експорт на инвентар: ${session.name}',
          ),
        );

        debugPrint('Share result: ${result.status}');

        // Show success message if shared successfully
        if (result.status == ShareResultStatus.success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Файлът е споделен успешно')),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _exportToExcel: $e');
      debugPrint('Stack trace: $stackTrace');

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Грешка при експорт: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    try {
      final excelService = ExcelExportService();
      final text = excelService.exportSessionToText(session);

      await Clipboard.setData(ClipboardData(text: text));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Копирано в клипборда'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Грешка при копиране: $e')));
      }
    }
  }

  Future<void> _editNotes(BuildContext context) async {
    final controller = TextEditingController(text: session.notes);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Бележки'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Въведете бележки...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, controller.text);
            },
            child: const Text('Запази'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      try {
        await context.read<SessionProvider>().updateSessionNotes(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Бележките са актуализирани')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Грешка: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детайли на заявката'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _exportToExcel(context),
            tooltip: 'Експорт Excel',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(context),
            tooltip: 'Копирай',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Consumer<SessionProvider>(
          builder: (context, sessionProvider, child) {
            // Get fresh data if this is the current session
            final displaySession =
                sessionProvider.currentSession?.id == session.id
                ? sessionProvider.currentSession!
                : session;

            return Column(
              children: [
                // Session info card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                displaySession.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note),
                              onPressed: () => _editNotes(context),
                              tooltip: 'Редактирай бележки',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Дата: ${dateFormatter.format(displaySession.createdDate)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Артикули: ${displaySession.itemCount}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Общо количество: ${displaySession.totalQuantity}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (displaySession.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 4),
                          const Text(
                            'Бележки:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displaySession.notes,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportToExcel(context),
                          icon: const Icon(Icons.file_download),
                          label: const Text('Експорт Excel'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyToClipboard(context),
                          icon: const Icon(Icons.copy),
                          label: const Text('Копирай'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Items list
                Expanded(
                  child: displaySession.items.isEmpty
                      ? const Center(child: Text('Няма артикули'))
                      : ListView.builder(
                          itemCount: displaySession.items.length,
                          itemBuilder: (context, index) {
                            final item = displaySession.items[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.qr_code, size: 32),
                                title: Text(
                                  item.barcode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('HH:mm:ss').format(item.timestamp),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'x ${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _editQuantity(context, item),
                                      tooltip: 'Редактиране',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: () =>
                                          _deleteItem(context, item),
                                      tooltip: 'Изтриване',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
