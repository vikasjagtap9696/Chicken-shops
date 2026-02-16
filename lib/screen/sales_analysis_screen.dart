import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as excel_lib;
import '../services/database_service.dart';
import '../models/sale_model.dart';

class SalesAnalysisScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final sales = db.sales;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Analysis', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePdf(sales),
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: Icon(Icons.table_view),
            onPressed: () => _generateExcel(sales),
            tooltip: 'Export Excel',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryHeader(db),
              SizedBox(height: 24),
              Text('Sales Performance (Last 7 Sales)', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              _buildChart(sales),
              SizedBox(height: 32),
              Text('Detailed Transactions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              _buildSalesTable(sales),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(DatabaseService db) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Today Sales', '₹${db.todaySales.toStringAsFixed(0)}'),
          Container(width: 1, height: 40, color: Colors.white24),
          _summaryItem('Orders', '${db.sales.length}'),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildChart(List<SaleModel> sales) {
    if (sales.isEmpty) return Center(child: Text('No data for chart'));
    
    final lastSales = sales.take(7).toList().reversed.toList();
    
    return Container(
      height: 200,
      padding: EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: lastSales.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.grandTotal)).toList(),
              isCurved: true,
              color: Colors.white,
              barWidth: 4,
              belowBarData: BarAreaData(show: true, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTable(List<SaleModel> sales) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        return ListTile(
          leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: Icon(Icons.receipt, color: Colors.green)),
          title: Text(sale.billNumber, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(DateFormat('hh:mm a').format(sale.createdAt)),
          trailing: Text('₹${sale.grandTotal}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        );
      },
    );
  }

  Future<void> _generatePdf(List<SaleModel> sales) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Header(level: 0, child: pw.Text("Chicken Mart - Sales Report")),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Bill No', 'Customer', 'Amount', 'Date'],
                ...sales.map((s) => [s.billNumber, s.customerName ?? 'N/A', s.grandTotal.toString(), DateFormat('dd/MM/yyyy').format(s.createdAt)])
              ],
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _generateExcel(List<SaleModel> sales) {
    try {
      var excel = excel_lib.Excel.createExcel();
      var sheet = excel['Sales_Report'];
      
      sheet.appendRow([
        excel_lib.TextCellValue('Bill Number'),
        excel_lib.TextCellValue('Customer Name'),
        excel_lib.TextCellValue('Amount'),
        excel_lib.TextCellValue('Payment Mode'),
        excel_lib.TextCellValue('Date')
      ]);
      
      for (var sale in sales) {
        sheet.appendRow([
          excel_lib.TextCellValue(sale.billNumber),
          excel_lib.TextCellValue(sale.customerName ?? 'Walk-in'),
          excel_lib.DoubleCellValue(sale.grandTotal),
          excel_lib.TextCellValue(sale.paymentMode),
          excel_lib.TextCellValue(DateFormat('dd/MM/yyyy').format(sale.createdAt))
        ]);
      }
      
      excel.save(fileName: "Sales_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx");
    } catch (e) {
      debugPrint("Excel Error: $e");
    }
  }
}
