import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_formatter.dart';
import '../models/student_model.dart';

class ExcelExportService {
  /// Generate an Excel file from a list of students and share it.
  /// Returns error message or null on success.
  Future<String?> exportAndShare(
    List<StudentModel> students, {
    String? customFileName,
  }) async {
    try {
      if (students.isEmpty) {
        return 'No records to export.';
      }

      final excel = Excel.createExcel();
      final sheet = excel['Student Records'];
      excel.setDefaultSheet('Student Records');
      // Remove default sheet
      excel.delete('Sheet1');

      // ── Header row ──────────────────────────────
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      );

      for (int i = 0; i < AppConstants.excelHeaders.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(AppConstants.excelHeaders[i]);
        cell.cellStyle = headerStyle;
      }

      // Set column widths
      _setColumnWidths(sheet);

      // ── Data rows ───────────────────────────────
      for (int rowIdx = 0; rowIdx < students.length; rowIdx++) {
        final s = students[rowIdx];
        final row = rowIdx + 1;

        _setCell(sheet, 0, row, s.serialNumber.toString());
        _setCell(sheet, 1, row, s.firstName);
        _setCell(sheet, 2, row, s.middleName);
        _setCell(sheet, 3, row, s.surname);
        _setCell(sheet, 4, row, s.schoolName);
        _setCell(sheet, 5, row, s.siblingClass);
        _setCell(sheet, 6, row, s.parents);
        _setCell(sheet, 7, row, s.motherContact);
        _setCell(sheet, 8, row, s.fatherContact);
        _setCell(sheet, 9, row, s.fullAddress);
        _setCell(sheet, 10, row, s.area);
        _setCell(sheet, 11, row, s.otherArea);
        _setCell(sheet, 12, row, s.landmark);
        _setCell(sheet, 13, row, s.otherLandmark);
        // Student Photo — URL reference
        _setCell(sheet, 14, row, s.photoUrl.isNotEmpty ? s.photoUrl : '');
        _setCell(sheet, 15, row, s.makerName);
        _setCell(
          sheet,
          16,
          row,
          DateFormatter.toExcel(s.submittedAtIST),
        );
      }

      // ── Save to temp file ────────────────────────
      final bytes = excel.encode();
      if (bytes == null) return 'Failed to generate Excel file.';

      final dir = await getTemporaryDirectory();
      final now = DateFormatter.nowIST();
      final fileName = customFileName ??
          'Student_Records_${DateFormatter.toFileName(now)}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      // ── Share / download ─────────────────────────
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Krishna Century — Student Records',
        subject: fileName,
      );

      return null;
    } catch (e) {
      return 'Excel export failed. Please try again.\n$e';
    }
  }

  void _setCell(Sheet sheet, int col, int row, String value) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = TextCellValue(value);
    cell.cellStyle = CellStyle(
      textWrapping: TextWrapping.WrapText,
      horizontalAlign: col == 9 ? HorizontalAlign.Left : HorizontalAlign.Left,
    );
  }

  void _setColumnWidths(Sheet sheet) {
    // Approximate widths in characters
    final widths = [
      6.0,   // Sr. No.
      18.0,  // First Name
      15.0,  // Middle Name
      18.0,  // Surname
      22.0,  // School Name
      20.0,  // Bro/Sis
      16.0,  // Parents
      18.0,  // Mother Contact
      18.0,  // Father Contact
      35.0,  // Address
      14.0,  // Area
      14.0,  // Other Area
      20.0,  // Landmark
      20.0,  // Other Landmark
      40.0,  // Photo URL
      18.0,  // Maker
      22.0,  // Date & Time
    ];
    for (int i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }
}
