import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:secure_money_management/ad_service/widgets/interstitial_ad.dart';
import 'package:secure_money_management/models/transaction_model.dart';
import 'package:secure_money_management/services/connectivity_service.dart';
import 'package:secure_money_management/services/file_operations_service.dart';
import 'package:secure_money_management/services/secure_transaction_service.dart';
import 'package:secure_money_management/services/currency_service.dart';
import 'package:secure_money_management/utils/user_experience_helper.dart';
import 'package:intl/intl.dart';

/// Service for handling import/export operations with ad gating and connectivity checks
class ImportExportService {
  static final ImportExportService _instance = ImportExportService._internal();
  factory ImportExportService() => _instance;
  ImportExportService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final FileOperationsService _fileOperationsService = FileOperationsService();
  final SecureTransactionService _transactionService = SecureTransactionService();
  final CurrencyService _currencyService = CurrencyService.instance;

  /// Initialize the service
  void initialize() {
    _connectivityService.initialize();
    // Pre-load ad for better user experience
    InterstitialAdWidget.instance.loadAd();
  }

  /// Check internet connection and show appropriate message
  Future<bool> _checkInternetConnection(BuildContext context) async {
    final hasInternet = await _connectivityService.hasInternetConnection();
    
    if (!hasInternet) {
      if (context.mounted) {
        UserExperienceHelper.showErrorSnackbar(
          context,
          'Internet connection required for import/export operations. Please check your connection and try again.',
        );
      }
      return false;
    }
    
    return true;
  }

  /// Show ad before performing import/export action
  Future<void> _showAdBeforeAction({
    required BuildContext context,
    required String actionName,
    required VoidCallback action,
  }) async {
    await InterstitialAdHelper.showAdBeforeAction(
      actionName: actionName,
      action: action,
      onAdFailure: () {
        if (kDebugMode) {
          print('⚠️ Ad failed to show for $actionName, proceeding anyway');
        }
        action();
      },
    );
  }

  /// Export transactions as JSON
  Future<void> exportAsJson(BuildContext context, List<TransactionModel> transactions) async {
    if (!await _checkInternetConnection(context)) return;

    await _showAdBeforeAction(
      context: context,
      actionName: 'JSON Export',
      action: () async {
        try {
          final jsonData = await _transactionService.backupTransactions();
          final filename = 'SecureMoney_Backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
          
          final success = await _fileOperationsService.exportFile(
            context,
            content: jsonData,
            filename: filename,
            mimeType: 'application/json',
            feature: 'JSON Export',
          );

          if (success && context.mounted) {
            UserExperienceHelper.showSuccessSnackbar(
              context,
              'Successfully exported ${transactions.length} transactions as JSON',
            );
          }
        } catch (e) {
          if (context.mounted) {
            UserExperienceHelper.showErrorSnackbar(
              context,
              'Failed to export JSON: ${e.toString()}',
            );
          }
        }
      },
    );
  }

  /// Export transactions as CSV
  Future<void> exportAsCsv(BuildContext context, List<TransactionModel> transactions) async {
    if (!await _checkInternetConnection(context)) return;

    await _showAdBeforeAction(
      context: context,
      actionName: 'CSV Export',
      action: () async {
        try {
          // Create CSV data
          List<List<dynamic>> csvData = [
            ['Date', 'Type', 'Category', 'Payment Mode', 'Amount'],
          ];

          for (final transaction in transactions) {
            csvData.add([
              DateFormat('yyyy-MM-dd').format(transaction.date),
              transaction.type,
              transaction.category,
              transaction.paymentMode ?? 'N/A',
              transaction.amount.toString(),
              //transaction.description,
            ]);
          }

          final csvString = const ListToCsvConverter().convert(csvData);
          final filename = 'SecureMoney_Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

          final success = await _fileOperationsService.exportFile(
            context,
            content: csvString,
            filename: filename,
            mimeType: 'text/csv',
            feature: 'CSV Export',
          );

          if (success && context.mounted) {
            UserExperienceHelper.showSuccessSnackbar(
              context,
              'Successfully exported ${transactions.length} transactions as CSV',
            );
          }
        } catch (e) {
          if (context.mounted) {
            UserExperienceHelper.showErrorSnackbar(
              context,
              'Failed to export CSV: ${e.toString()}',
            );
          }
        }
      },
    );
  }

  /// Export transactions as PDF
  Future<void> exportAsPdf(BuildContext context, List<TransactionModel> transactions) async {
    if (!await _checkInternetConnection(context)) return;

    await _showAdBeforeAction(
      context: context,
      actionName: 'PDF Export',
      action: () async {
        try {
          final pdf = pw.Document();

          // Calculate totals
          double totalIncome = 0;
          double totalExpenses = 0;
          for (final transaction in transactions) {
            if (transaction.type == 'Income') {
              totalIncome += transaction.amount;
            } else {
              totalExpenses += transaction.amount;
            }
          }
          final balance = totalIncome - totalExpenses;

          pdf.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(32),
              build: (pw.Context context) {
                return [
                  // Header
                  pw.Header(
                    level: 0,
                    child: pw.Text(
                      'SecureMoney Transaction Report',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  
                  pw.SizedBox(height: 20),
                  
                  // Summary
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text('Total Transactions: ${transactions.length}'),
                        pw.Text('Total Income: ${_currencyService.formatAmount(totalIncome)}'),
                        pw.Text('Total Expenses: ${_currencyService.formatAmount(totalExpenses)}'),
                        pw.Text('Balance: ${_currencyService.formatAmount(balance)}'),
                        pw.Text('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}'),
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(height: 20),
                  
                  // Transactions table
                  pw.Text('Transactions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(80),
                      1: const pw.FixedColumnWidth(60),
                      2: const pw.FixedColumnWidth(80),
                      3: const pw.FixedColumnWidth(70),
                      4: const pw.FixedColumnWidth(70),
                      5: const pw.FlexColumnWidth(),
                    },
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Payment', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          //pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                      // Data rows
                      ...transactions.map((transaction) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(DateFormat('MM/dd/yy').format(transaction.date), style: const pw.TextStyle(fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(transaction.type, style: const pw.TextStyle(fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(transaction.category, style: const pw.TextStyle(fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(transaction.paymentMode ?? '', style: const pw.TextStyle(fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_currencyService.formatAmount(transaction.amount), style: const pw.TextStyle(fontSize: 10))),
                          //pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(transaction.description, style: const pw.TextStyle(fontSize: 10))),
                        ],
                      )),
                    ],
                  ),
                ];
              },
            ),
          );

          final pdfBytes = await pdf.save();
          final filename = 'SecureMoney_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

          final success = await _fileOperationsService.exportBinaryFile(
            context,
            bytes: pdfBytes,
            filename: filename,
            mimeType: 'application/pdf',
            feature: 'PDF Export',
          );

          if (success && context.mounted) {
            UserExperienceHelper.showSuccessSnackbar(
              context,
              'Successfully exported ${transactions.length} transactions as PDF',
            );
          }
        } catch (e) {
          if (context.mounted) {
            UserExperienceHelper.showErrorSnackbar(
              context,
              'Failed to export PDF: ${e.toString()}',
            );
          }
        }
      },
    );
  }

  /// Import transactions from JSON file
  Future<void> importFromJson(BuildContext context, VoidCallback onImportComplete) async {
    if (!await _checkInternetConnection(context)) return;

    await _showAdBeforeAction(
      context: context,
      actionName: 'JSON Import',
      action: () async {
        try {
          final jsonData = await _fileOperationsService.importTransactionJsonFile(context);
          
          if (jsonData == null) {
            // User cancelled or error already shown
            return;
          }

          final newTransactionsCount = await _transactionService.importAndAppendTransactions(jsonData);

          if (context.mounted) {
            if (newTransactionsCount > 0) {
              UserExperienceHelper.showSuccessSnackbar(
                context,
                'Successfully imported $newTransactionsCount new transactions. Duplicates were automatically skipped.',
              );
              onImportComplete();
            } else {
              UserExperienceHelper.showInfoSnackbar(
                context,
                'No new transactions found. All transactions in the file already exist.',
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            UserExperienceHelper.showErrorSnackbar(
              context,
              'Failed to import transactions: ${e.toString()}',
            );
          }
        }
      },
    );
  }

  /// Show export options dialog
  Future<void> showExportDialog(BuildContext context, List<TransactionModel> transactions) async {
    if (transactions.isEmpty) {
      UserExperienceHelper.showInfoSnackbar(
        context,
        'No transactions to export. Add some transactions first.',
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.file_upload, color: Colors.blue),
              SizedBox(width: 8),
              Text('Export Transactions'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose export format for ${transactions.length} transactions:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.code, color: Colors.orange),
                title: const Text('JSON Format'),
                subtitle: const Text('For backup and import to SecureMoney'),
                onTap: () {
                  Navigator.pop(context);
                  exportAsJson(context, transactions);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('CSV Format'),
                subtitle: const Text('For spreadsheet applications'),
                onTap: () {
                  Navigator.pop(context);
                  exportAsCsv(context, transactions);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF Report'),
                subtitle: const Text('For printing and sharing'),
                onTap: () {
                  Navigator.pop(context);
                  exportAsPdf(context, transactions);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Dispose of the service
  void dispose() {
    _connectivityService.dispose();
  }
}
