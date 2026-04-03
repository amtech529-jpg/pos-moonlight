import 'package:flutter/material.dart';

import '../models/profit_loss/profit_loss_models.dart';

class ProfitLossData {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalSalesIncome;
  final double totalCostOfGoodsSold;
  final double laborPayments;
  final double vendorPayments;
  final double otherExpenses;
  final double zakatAmount;
  final String periodType; // 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM'
  final int totalProductsSold;
  final double averageOrderValue;

  ProfitLossData({
    required this.periodStart,
    required this.periodEnd,
    required this.totalSalesIncome,
    required this.totalCostOfGoodsSold,
    required this.laborPayments,
    required this.vendorPayments,
    required this.otherExpenses,
    required this.zakatAmount,
    required this.periodType,
    this.totalProductsSold = 0,
    this.averageOrderValue = 0.0,
  });

  // Calculated Properties
  double get grossProfit => totalSalesIncome - totalCostOfGoodsSold;
  double get totalExpenses => laborPayments + vendorPayments + otherExpenses + zakatAmount;
  double get netProfit => grossProfit - totalExpenses;
  double get grossProfitMargin => totalSalesIncome > 0 ? (grossProfit / totalSalesIncome) * 100 : 0.0;
  double get profitMargin => totalSalesIncome > 0 ? (netProfit / totalSalesIncome) * 100 : 0.0;
  bool get isProfitable => netProfit > 0;

  // Formatted Strings
  String get formattedPeriod {
    switch (periodType) {
      case 'DAILY':
        return '${periodStart.day}/${periodStart.month}/${periodStart.year}';
      case 'WEEKLY':
        return '${periodStart.day}/${periodStart.month} - ${periodEnd.day}/${periodEnd.month}/${periodEnd.year}';
      case 'MONTHLY':
        return _getMonthName(periodStart.month) + ' ${periodStart.year}';
      case 'YEARLY':
        return '${periodStart.year}';
      case 'CUSTOM':
        return '${periodStart.day}/${periodStart.month}/${periodStart.year} - ${periodEnd.day}/${periodEnd.month}/${periodEnd.year}';
      default:
        return 'Unknown Period';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  String get formattedTotalIncome => 'PKR ${totalSalesIncome.toStringAsFixed(0)}';
  String get formattedGrossProfit => 'PKR ${grossProfit.toStringAsFixed(0)}';
  String get formattedTotalExpenses => 'PKR ${totalExpenses.toStringAsFixed(0)}';
  String get formattedNetProfit => 'PKR ${netProfit.toStringAsFixed(0)}';
  String get formattedGrossProfitMargin => '${grossProfitMargin.toStringAsFixed(1)}%';
  String get formattedProfitMargin => '${profitMargin.toStringAsFixed(1)}%';

  // Expense Breakdown Percentages
  double get laborPercentage => totalExpenses > 0 ? (laborPayments / totalExpenses) * 100 : 0.0;
  double get vendorPercentage => totalExpenses > 0 ? (vendorPayments / totalExpenses) * 100 : 0.0;
  double get otherExpensesPercentage => totalExpenses > 0 ? (otherExpenses / totalExpenses) * 100 : 0.0;
  double get zakatPercentage => totalExpenses > 0 ? (zakatAmount / totalExpenses) * 100 : 0.0;

  // Revenue vs Expense Percentages
  double get expenseToRevenueRatio => totalSalesIncome > 0 ? (totalExpenses / totalSalesIncome) * 100 : 0.0;
  double get profitToRevenueRatio => totalSalesIncome > 0 ? (netProfit / totalSalesIncome) * 100 : 0.0;

  // Create from API ProfitLossRecord
  factory ProfitLossData.fromProfitLossRecord(ProfitLossRecord record) {
    return ProfitLossData(
      periodStart: record.startDate,
      periodEnd: record.endDate,
      totalSalesIncome: record.totalSalesIncome,
      totalCostOfGoodsSold: record.totalCostOfGoodsSold,
      laborPayments: record.totalLaborPayments,
      vendorPayments: record.totalVendorPayments,
      otherExpenses: record.totalExpenses,
      zakatAmount: record.totalZakat,
      periodType: record.periodType,
      totalProductsSold: record.totalProductsSold,
      averageOrderValue: record.averageOrderValue,
    );
  }

  // Create from API ProfitLossSummary
  factory ProfitLossData.fromProfitLossSummary(ProfitLossSummary summary) {
    final periodInfo = summary.periodInfo;
    final startDate = DateTime.parse(periodInfo['start_date']);
    final endDate = DateTime.parse(periodInfo['end_date']);
    final periodType = periodInfo['period_type'] as String;

    return ProfitLossData(
      periodStart: startDate,
      periodEnd: endDate,
      totalSalesIncome: summary.totalSalesIncome,
      totalCostOfGoodsSold: summary.totalCostOfGoodsSold,
      laborPayments: summary.totalLaborPayments,
      vendorPayments: summary.totalVendorPayments,
      otherExpenses: summary.totalExpenses,
      zakatAmount: summary.totalZakat,
      periodType: periodType,
      totalProductsSold: summary.totalProductsSold,
      averageOrderValue: summary.averageOrderValue,
    );
  }
}