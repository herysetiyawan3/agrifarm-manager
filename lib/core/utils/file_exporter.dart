import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'formatters.dart';

class FileExporter {
  // Helper to get local directory to store temp files
  static Future<String> get _tempPath async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  // Export List of maps to Excel sheet
  static Future<void> exportToExcel({
    required String fileName,
    required String sheetName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final excel = Excel.createExcel();
    final Sheet sheetObject = excel[sheetName];
    
    // Set headers
    sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Set rows
    for (var row in rows) {
      sheetObject.appendRow(row.map((r) => TextCellValue(r.toString())).toList());
    }

    // Save file
    final path = await _tempPath;
    final fileBytes = excel.save();
    final file = File('$path/$fileName.xlsx');
    await file.create(recursive: true);
    await file.writeAsBytes(fileBytes!);

    // Share file
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Laporan $sheetName dari AgriFarm Manager',
    );
  }

  // Export Laba Rugi Financial Report to PDF
  static Future<void> exportLabaRugiPdf({
    required String seasonName,
    required double totalPendapatan,
    required double totalPengeluaran,
    required double labaBersih,
    required double marginKeuntungan,
    required Map<String, double> biayaKategori,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AgriFarm Manager',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
                        pw.Text('Laporan Keuangan Laba Rugi Budidaya'),
                      ],
                    ),
                    pw.Text(
                      Formatters.formatDate(DateTime.now()),
                      style: const pw.TextStyle(color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Divider(thickness: 2, color: PdfColors.green800),
                pw.SizedBox(height: 20),

                // Season Meta
                pw.Text(
                  'Musim Tanam: $seasonName',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),

                // Ringkasan Keuangan Table
                pw.Text(
                  'Ikhtisar Keuangan',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    _buildTableRow('Total Pendapatan (Penjualan)', Formatters.formatRupiah(totalPendapatan), isHeader: false),
                    _buildTableRow('Total Pengeluaran (Operasional)', Formatters.formatRupiah(totalPengeluaran), isHeader: false),
                    _buildTableRow(
                      'Laba Bersih',
                      Formatters.formatRupiah(labaBersih),
                      isHeader: true,
                      color: labaBersih >= 0 ? PdfColors.green100 : PdfColors.red100,
                    ),
                    _buildTableRow('Margin Keuntungan', '${marginKeuntungan.toStringAsFixed(1)}%', isHeader: false),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Breakdown Biaya
                pw.Text(
                  'Rincian Pengeluaran berdasarkan Kategori',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Kategori Biaya', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Nominal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Rows
                    ...biayaKategori.entries.map((e) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(e.key),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(Formatters.formatRupiah(e.value)),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                pw.Center(
                  child: pw.Text(
                    'Laporan ini digenerate secara otomatis oleh AgriFarm Manager.',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save and share PDF
    final path = await _tempPath;
    final file = File('$path/Laporan_Laba_Rugi_$seasonName.pdf');
    await file.create(recursive: true);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Laporan Keuangan $seasonName - AgriFarm Manager',
    );
  }

  static pw.TableRow _buildTableRow(String label, String value, {required bool isHeader, PdfColor? color}) {
    return pw.TableRow(
      decoration: color != null ? pw.BoxDecoration(color: color) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ),
      ],
    );
  }

  // Export List of data to CSV file
  static Future<void> exportToCSV({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final StringBuffer csvBuffer = StringBuffer();
    
    // Add headers
    csvBuffer.writeln(headers.map((h) => '"${h.replaceAll('"', '""')}"').join(','));

    // Add rows
    for (var row in rows) {
      csvBuffer.writeln(row.map((r) {
        final val = r == null ? '' : r.toString().replaceAll('"', '""');
        return '"$val"';
      }).join(','));
    }

    // Save file
    final path = await _tempPath;
    final file = File('$path/$fileName.csv');
    await file.create(recursive: true);
    await file.writeAsString(csvBuffer.toString());

    // Share file
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Ekspor data CSV dari AgriFarm Manager',
    );
  }
}
