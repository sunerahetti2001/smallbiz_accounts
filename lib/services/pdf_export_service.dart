import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../utils/colors.dart';

class PdfExportService {
  // Generate Monthly Summary PDF
  static Future<File> generateSummaryPdf({
    required String businessName,
    required String ownerName,
    required String monthYear,
    required DateTime startDate,
    required DateTime endDate,
    required double openingBalance,
    required double totalIncome,
    required double totalExpense,
    required double closingBalance,
    required double creditOutstanding,
    required Map<String, double> incomeBreakdown,
    required Map<String, double> expenseBreakdown,
    required List<TransactionModel> pendingCredits,
    required int transactionCount,
  }) async {
    final pdf = pw.Document();

    final double netProfit = totalIncome - totalExpense;
    final double profitMargin = totalIncome > 0 ? (netProfit / totalIncome * 100) : 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              pw.SizedBox(height: 20),
              // Business Info
              _buildBusinessInfo(businessName, ownerName, monthYear, startDate, endDate),
              pw.SizedBox(height: 20),
              // Summary
              _buildSummaryCard(
                openingBalance,
                totalIncome,
                totalExpense,
                closingBalance,
                netProfit,
                profitMargin,
                creditOutstanding,
                transactionCount,
              ),
              pw.SizedBox(height: 20),
              // Income Breakdown
              _buildIncomeBreakdown(incomeBreakdown, totalIncome),
              pw.SizedBox(height: 20),
              // Expense Breakdown
              _buildExpenseBreakdown(expenseBreakdown, totalExpense),
              if (pendingCredits.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildPendingCredits(pendingCredits),
              ],
              pw.SizedBox(height: 30),
              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return await _savePdf(pdf, 'Statement_${businessName.replaceAll(' ', '_')}_$monthYear');
  }

  // Generate Detailed Transactions PDF
  static Future<File> generateDetailedPdf({
    required String businessName,
    required String ownerName,
    required String monthYear,
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
  }) async {
    final pdf = pw.Document();

    // Calculate summary stats
    int incomeCount = 0;
    int expenseCount = 0;
    int creditSaleCount = 0;
    int creditPaymentCount = 0;
    double totalIncome = 0;
    double totalExpense = 0;
    double totalCreditSales = 0;
    double totalCreditPayments = 0;

    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        incomeCount++;
        totalIncome += t.amount;
      } else if (t.type == TransactionType.expense) {
        expenseCount++;
        totalExpense += t.amount;
      } else if (t.type == TransactionType.creditSale) {
        creditSaleCount++;
        totalCreditSales += t.amount;
      } else if (t.type == TransactionType.creditPayment) {
        creditPaymentCount++;
        totalCreditPayments += t.amount;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              pw.SizedBox(height: 20),
              // Business Info
              _buildBusinessInfo(businessName, ownerName, monthYear, startDate, endDate),
              pw.SizedBox(height: 20),
              // Transaction Table
              _buildTransactionTable(transactions),
              pw.SizedBox(height: 20),
              // Summary by type
              _buildTransactionSummary(
                incomeCount, expenseCount, creditSaleCount, creditPaymentCount,
                totalIncome, totalExpense, totalCreditSales, totalCreditPayments,
              ),
              pw.SizedBox(height: 30),
              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return await _savePdf(pdf, 'Detailed_${businessName.replaceAll(' ', '_')}_$monthYear');
  }

  // Show PDF preview with simple dialog (no complex widgets)
  static Future<void> showPdfPreview({
    required BuildContext context,
    required File pdfFile,
    required String title,
  }) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Use the printing package's preview widget
      await Printing.sharePdf(
        bytes: await pdfFile.readAsBytes(),
        filename: '$title.pdf',
      );
    } catch (e) {
      // Fallback: just show a snackbar with file location
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: ${pdfFile.path}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }
    }
  }

  // Helper methods
  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SmallBiz Accounts',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Track Smarter. Claim More.',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Text(
            'Financial Statement',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBusinessInfo(String businessName, String ownerName, String monthYear, DateTime startDate, DateTime endDate) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Business: $businessName', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Owner: $ownerName', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Period: $monthYear', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('${_formatDate(startDate)} - ${_formatDate(endDate)}', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCard(
      double openingBalance,
      double totalIncome,
      double totalExpense,
      double closingBalance,
      double netProfit,
      double profitMargin,
      double creditOutstanding,
      int transactionCount,
      ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text('FINANCIAL SUMMARY', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Opening Balance', 'Rs ${_formatNumber(openingBalance)}'),
              _buildSummaryItem('Total Income', 'Rs ${_formatNumber(totalIncome)}'),
              _buildSummaryItem('Total Expense', 'Rs ${_formatNumber(totalExpense)}'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Closing Balance', 'Rs ${_formatNumber(closingBalance)}'),
              _buildSummaryItem('Net Profit', 'Rs ${_formatNumber(netProfit)}'),
              _buildSummaryItem('Profit Margin', '${profitMargin.toStringAsFixed(1)}%'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Credit Outstanding', 'Rs ${_formatNumber(creditOutstanding)}'),
              _buildSummaryItem('Transactions', transactionCount.toString()),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _buildIncomeBreakdown(Map<String, double> breakdown, double total) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text('INCOME BREAKDOWN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
          pw.SizedBox(height: 12),
          ...breakdown.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100) : 0;
            return pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(entry.key, style: pw.TextStyle(fontSize: 11)),
                    pw.Text(
                      'Rs ${_formatNumber(entry.value)} (${percentage.toStringAsFixed(1)}%)',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  height: 6,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Container(
                    width: (percentage / 100) * 400,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
              ],
            );
          }).toList(),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Rs ${_formatNumber(total)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildExpenseBreakdown(Map<String, double> breakdown, double total) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text('EXPENSE BREAKDOWN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
          pw.SizedBox(height: 12),
          ...breakdown.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100) : 0;
            return pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(entry.key, style: pw.TextStyle(fontSize: 11)),
                    pw.Text(
                      'Rs ${_formatNumber(entry.value)} (${percentage.toStringAsFixed(1)}%)',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  height: 6,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Container(
                    width: (percentage / 100) * 400,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
              ],
            );
          }).toList(),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Rs ${_formatNumber(total)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPendingCredits(List<TransactionModel> credits) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.orange),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text('PENDING CREDITS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Customer', isHeader: true),
                  _buildTableCell('Amount', isHeader: true),
                  _buildTableCell('Due Date', isHeader: true),
                  _buildTableCell('Status', isHeader: true),
                ],
              ),
              ...credits.map((credit) {
                final isOverdue = credit.dueDate != null && credit.dueDate!.isBefore(DateTime.now());
                return pw.TableRow(
                  children: [
                    _buildTableCell(credit.customerName ?? 'Unknown'),
                    _buildTableCell('Rs ${_formatNumber(credit.amount)}'),
                    _buildTableCell(credit.dueDate != null ? _formatDate(credit.dueDate!) : 'Not set'),
                    _buildTableCell(isOverdue ? 'OVERDUE' : 'Pending', textColor: isOverdue ? PdfColors.red : PdfColors.orange),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('TOTAL OUTSTANDING: ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                'Rs ${_formatNumber(credits.fold(0.0, (sum, c) => sum + c.amount))}',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTransactionTable(List<TransactionModel> transactions) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text('TRANSACTION DETAILS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey),
            columnWidths: {
              0: pw.FixedColumnWidth(40),
              1: pw.FixedColumnWidth(80),
              2: pw.FixedColumnWidth(80),
              3: pw.FlexColumnWidth(),
              4: pw.FixedColumnWidth(80),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('#', isHeader: true),
                  _buildTableCell('Date', isHeader: true),
                  _buildTableCell('Type', isHeader: true),
                  _buildTableCell('Category/Description', isHeader: true),
                  _buildTableCell('Amount', isHeader: true),
                ],
              ),
              ...transactions.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final t = entry.value;
                final isIncome = t.type == TransactionType.income || t.type == TransactionType.creditPayment;
                final String amountText;
                final PdfColor amountColor;

                if (isIncome) {
                  amountText = '+Rs ${_formatNumber(t.amount)}';
                  amountColor = PdfColors.green;
                } else if (t.type == TransactionType.expense) {
                  amountText = '-Rs ${_formatNumber(t.amount)}';
                  amountColor = PdfColors.red;
                } else {
                  amountText = 'Rs ${_formatNumber(t.amount)}';
                  amountColor = PdfColors.orange;
                }

                String typeText = '';
                if (t.type == TransactionType.income) typeText = 'Income';
                else if (t.type == TransactionType.expense) typeText = 'Expense';
                else if (t.type == TransactionType.creditSale) typeText = 'Credit Sale';
                else if (t.type == TransactionType.creditPayment) typeText = 'Credit Payment';

                String categoryText = t.category;
                if (t.customerName != null && t.customerName!.isNotEmpty) {
                  categoryText = '${t.customerName} - $categoryText';
                }

                return pw.TableRow(
                  children: [
                    _buildTableCell(index.toString()),
                    _buildTableCell(_formatDate(t.date)),
                    _buildTableCell(typeText),
                    _buildTableCell('${t.description}\n${categoryText}'),
                    _buildTableCell(amountText, textColor: amountColor),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTransactionSummary(
      int incomeCount, int expenseCount, int creditSaleCount, int creditPaymentCount,
      double totalIncome, double totalExpense, double totalCreditSales, double totalCreditPayments,
      ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        children: [
          pw.Text('SUMMARY BY TYPE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildTypeSummary('Income', incomeCount, totalIncome, PdfColors.green),
              _buildTypeSummary('Expense', expenseCount, totalExpense, PdfColors.red),
              _buildTypeSummary('Credit Sale', creditSaleCount, totalCreditSales, PdfColors.orange),
              _buildTypeSummary('Credit Payment', creditPaymentCount, totalCreditPayments, PdfColors.green),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTypeSummary(String type, int count, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(type, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.Text('$count transactions', style: pw.TextStyle(fontSize: 9)),
        pw.Text('Rs ${_formatNumber(amount)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? textColor}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'SmallBiz Accounts - Track Smarter. Claim More.',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.Text(
          'This is a computer-generated document. No signature required.',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.Text(
          'Generated on: ${_formatDateTime(DateTime.now())}',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static Future<File> _savePdf(pw.Document pdf, String fileName) async {
    final bytes = await pdf.save();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  static String _formatNumber(double number) {
    return number.toStringAsFixed(2);
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}