import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:money_management/views/dashboard.dart';
import 'package:money_management/views/recent_transactions.dart';
import 'package:money_management/views/report_screen.dart';
import 'package:money_management/views/transactions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helper/constants.dart';
import 'models/transaction_model.dart';

Future<void> main() async {
  // Initialize Google Mobile Ads
  try {
    Constants.isMobileDevice ? await MobileAds.instance.initialize() : null;
  } catch (e) {
    debugPrint(e.toString());
  }

  runApp(const MoneyManagementApp());
}

class MoneyManagementApp extends StatelessWidget {
  const MoneyManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Management App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionModel> _transactions = []; // List to hold transactions
  double _totalBalance = 0.0;
  int _selectedIndex = 0; // Index to track the selected tab

  @override
  void initState() {
    super.initState();
    _loadTransactions(); // Load saved transactions
    _calculateBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Manager'),
      ),
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Reports',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          transactions: _transactions,
          totalBalance: _totalBalance,
          onTransactionsUpdated: _loadTransactions,
        );
      case 1:
        return TransactionScreen(
          onTransactionsUpdated: () {
            _loadTransactions(); // Reload transactions when returning
          },
        );
      case 2:
        // return ReportsScreen(transactions: _transactions);
        return RecentTransactions();
      default:
        return DashboardScreen(transactions: _transactions, totalBalance: _totalBalance, onTransactionsUpdated: _loadTransactions);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  // Load transactions from local storage
  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTransactions = prefs.getString('transactions');
    if (savedTransactions != null) {
      List<dynamic> decodedTransactions = jsonDecode(savedTransactions);
      setState(() {
        _transactions = decodedTransactions
            .map((json) => TransactionModel.fromJson(json))
            .toList();
        _calculateBalance(); // Recalculate balance after loading
      });
    }
  }

  // Calculate total balance based on transactions
  void _calculateBalance() {
    double balance = 0.0;
    for (var txn in _transactions) {
      if (txn.type == 'Income') {
        balance += txn.amount;
      } else if (txn.type == 'Expense') {
        balance -= txn.amount;
      }
    }
    setState(() {
      _totalBalance = balance; // Update the total balance
    });
  }
}
