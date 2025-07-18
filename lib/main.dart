import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:secure_money_management/services/encryption_service.dart';
import 'package:secure_money_management/services/secure_transaction_service.dart';
import 'package:secure_money_management/views/dashboard.dart';
import 'package:secure_money_management/views/recent_transactions.dart';
import 'package:secure_money_management/views/transactions_screen.dart';
import 'package:secure_money_management/widgets/permission_initializer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helper/constants.dart';
import 'models/transaction_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize encryption service first
  try {
    await EncryptionService().initialize();
    await SecureTransactionService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize encryption: $e');
  }
  
  // Initialize Google Mobile Ads
  try {
    Constants.isMobileDevice ? await MobileAds.instance.initialize() : null;
  } catch (e) {
    debugPrint('Failed to initialize ads: $e');
  }

  runApp(const MoneyManagementApp());
}

class MoneyManagementApp extends StatelessWidget {
  const MoneyManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureMoney - Personal Finance Manager',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const PermissionInitializer(
        child: HomeScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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
        title: const Text('SecureMoney'),
        centerTitle: true,
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
        return const RecentTransactions();
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
