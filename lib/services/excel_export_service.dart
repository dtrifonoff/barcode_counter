import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../models/scanning_session.dart';

class ExcelExportService {
  /// Generate Excel file from scanning session
  /// Returns the file path of the generated Excel file
  Future<String> exportSessionToExcel(ScanningSession session) async {
    try {
      debugPrint('Starting Excel export for session: ${session.name}');
      
      // Create Excel workbook
      var excel = Excel.createExcel();
      
      // Get default sheet
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      debugPrint('Default sheet: $defaultSheet');
      
      // Rename default sheet
      excel.rename(defaultSheet, 'Инвентар');
      
      // Get the sheet object
      Sheet sheetObject = excel['Инвентар'];
      
      // Add header row
      sheetObject.appendRow([
        TextCellValue('Баркод'),
        TextCellValue('Количество'),
      ]);
      
      debugPrint('Added header row');
      
      // Add data rows
      for (var item in session.items) {
        sheetObject.appendRow([
          TextCellValue(item.barcode),
          IntCellValue(item.quantity),
        ]);
      }
      
      debugPrint('Added ${session.items.length} data rows');
      
      // Generate filename with session name and date
      final dateFormatter = DateFormat('dd.MM.yyyy_HH-mm');
      final dateStr = dateFormatter.format(session.createdDate);
      // Clean filename - remove special characters
      final cleanName = session.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final filename = 'inventar_${cleanName}_$dateStr.xlsx';
      
      debugPrint('Filename: $filename');
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';
      
      debugPrint('File path: $filePath');
      
      // Encode Excel file
      final excelBytes = excel.encode();
      if (excelBytes == null) {
        throw Exception('Не може да се кодира Excel файл');
      }
      
      debugPrint('Excel encoded, size: ${excelBytes.length} bytes');
      
      // Save Excel file
      final file = File(filePath);
      await file.writeAsBytes(excelBytes);
      
      debugPrint('File written successfully');
      
      // Verify file exists
      if (!await file.exists()) {
        throw Exception('Файлът не е създаден');
      }
      
      final fileSize = await file.length();
      debugPrint('File size: $fileSize bytes');
      
      return filePath;
    } catch (e, stackTrace) {
      debugPrint('Error exporting to Excel: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generate text format for clipboard copy
  /// Format: barcode1;quantity1\nbarcode2;quantity2\n...
  String exportSessionToText(ScanningSession session) {
    final buffer = StringBuffer();
    
    for (var item in session.items) {
      buffer.writeln('${item.barcode};${item.quantity}');
    }
    
    return buffer.toString();
  }

  /// Delete temporary Excel file after sharing
  Future<void> deleteExcelFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }
}
