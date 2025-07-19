import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:secure_money_management/views/dashboard.dart';
import 'package:secure_money_management/views/recent_transactions.dart';
import 'package:secure_money_management/views/transactions_screen.dart';
import 'package:secure_money_management/screens/splash_screen.dart';
import 'package:secure_money_management/services/lazy_initialization_service.dart';
import 'package:secure_money_management/services/secure_transaction_service.dart';
import 'package:secure_money_management/services/theme_service.dart';
import 'package:secure_money_management/widgets/theme_settings_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/transaction_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();
  
  runApp(MoneyManagementApp(themeService: themeService));
}

class MoneyManagementApp extends StatelessWidget {
  final ThemeService themeService;
  
  const MoneyManagementApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
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
              cardTheme: const CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.green,
              brightness: Brightness.dark,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1B5E20), // Dark green
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              cardTheme: const CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                color: Color(0xFF2E2E2E), // Dark card background
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
              colorScheme: const ColorScheme.dark(
                primary: Colors.green,
                secondary: Colors.greenAccent,
                surface: Color(0xFF1E1E1E),
                background: Color(0xFF121212),
                onPrimary: Colors.white,
                onSecondary: Colors.black,
                onSurface: Colors.white,
                onBackground: Colors.white,
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white70),
                headlineLarge: TextStyle(color: Colors.white),
                headlineMedium: TextStyle(color: Colors.white),
                headlineSmall: TextStyle(color: Colors.white),
              ),
              useMaterial3: true,
            ),
            themeMode: themeService.themeMode, // Use theme service's current mode
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
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
  final SecureTransactionService _secureStorage = SecureTransactionService();

  @override
  void initState() {
    super.initState();
    _initializeAndLoadTransactions(); // Initialize secure storage and load transactions
  }

  /// Initialize secure storage and load transactions
  Future<void> _initializeAndLoadTransactions() async {
    try {
      // Initialize the secure transaction service
      await _secureStorage.initialize();
      
      // Attempt to migrate from plain text storage
      final migrated = await _secureStorage.migrateFromPlainTextStorage();
      if (migrated) {
        debugPrint('Successfully migrated transactions to encrypted storage in main.dart');
      }
      
      // Load transactions after initialization/migration
      await _loadTransactions();
      _calculateBalance();
      
    } catch (e) {
      debugPrint('Error initializing secure storage in main.dart: $e');
      // Fallback to loading without migration
      await _loadTransactions();
      _calculateBalance();
    }
    
    // Initialize non-critical services lazily after UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LazyInitializationService.instance.initializeLazily();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SecureMoney'),
        centerTitle: true,
        actions: [
          const ThemeToggleButton(),
        ],
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
        return RecentTransactions(
          onTransactionsUpdated: _loadTransactions,
        );
      default:
        return DashboardScreen(transactions: _transactions, totalBalance: _totalBalance, onTransactionsUpdated: _loadTransactions);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  // Load transactions from secure storage
  Future<void> _loadTransactions() async {
    try {
      final loadedTransactions = await _secureStorage.loadTransactions();
      setState(() {
        _transactions = loadedTransactions;
      });
      _calculateBalance(); // Recalculate balance after loading transactions
    } catch (e) {
      debugPrint('Error loading transactions in main.dart: $e');
      // Try legacy migration as fallback
      await _tryLegacyMigration();
    }
  }

  /// Try to load from legacy storage and migrate to secure storage
  Future<void> _tryLegacyMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedTransactions = prefs.getString('transactions');
      if (savedTransactions != null) {
        List<dynamic> decodedTransactions = jsonDecode(savedTransactions);
        final legacyTransactions = decodedTransactions
            .map((json) => TransactionModel.fromJson(json))
            .toList();
        
        // Migrate to secure storage
        await _secureStorage.saveTransactions(legacyTransactions);
        await prefs.remove('transactions'); // Remove legacy storage
        
        setState(() {
          _transactions = legacyTransactions;
        });
        
        _calculateBalance(); // Recalculate balance after migration
        debugPrint('Successfully migrated ${legacyTransactions.length} transactions from legacy storage in main.dart');
      }
    } catch (e) {
      debugPrint('Error during legacy migration in main.dart: $e');
      setState(() {
        _transactions = [];
      });
    }
  }

  // Calculate total balance based on transactions
  void _calculateBalance() {
    double balance = 0.0;
    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    
    for (var txn in _transactions) {
      if (txn.type == 'Income') {
        balance += txn.amount;
        totalIncome += txn.amount;
      } else if (txn.type == 'Expense') {
        balance -= txn.amount;
        totalExpenses += txn.amount;
      }
    }
    
    setState(() {
      _totalBalance = balance; // Update the total balance
    });
    
    // Debug output (can be removed in production)
    debugPrint('Main - Loaded ${_transactions.length} transactions, Income: $totalIncome, Expenses: $totalExpenses, Balance: $balance');
  }
}
