import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:secure_money_management/views/dashboard.dart';
import 'package:secure_money_management/views/recent_transactions.dart';
import 'package:secure_money_management/views/transactions_screen.dart';
import 'package:secure_money_management/views/report_screen.dart';
import 'package:secure_money_management/screens/splash_screen.dart';
import 'package:secure_money_management/screens/onboarding_tutorial.dart';
import 'package:secure_money_management/services/lazy_initialization_service.dart';
import 'package:secure_money_management/services/secure_transaction_service.dart';
import 'package:secure_money_management/services/theme_service.dart';
import 'package:secure_money_management/services/currency_service.dart';
import 'package:secure_money_management/services/system_ui_service.dart';
import 'package:secure_money_management/services/onboarding_service.dart';
import 'package:secure_money_management/services/gamification_service.dart';
import 'package:secure_money_management/widgets/theme_settings_widget.dart';
import 'package:secure_money_management/widgets/sample_data_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/transaction_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait only to prevent overflow issues
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configure system UI for edge-to-edge display using modern APIs
  SystemUIService.instance.resetToEdgeToEdge();
  
  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();
  
  // Initialize currency service
  await CurrencyService.instance.initialize();
  
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
          // Configure system UI based on current theme
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SystemUIService.instance.configureForTheme(
              themeService.themeMode, 
              context
            );
          });
          
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<TransactionModel> _transactions = []; // List to hold transactions
  double _totalBalance = 0.0;
  int _selectedIndex = 0; // Index to track the selected tab
  final SecureTransactionService _secureStorage = SecureTransactionService();
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _showOnboarding = false;
  bool _showSampleDataPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    _checkOnboardingAndInitialize(); // Check onboarding and initialize
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    super.dispose();
  }

  /// Check onboarding state and initialize app
  Future<void> _checkOnboardingAndInitialize() async {
    try {
      // Check if this is first launch
      final isFirstLaunch = await OnboardingService.isFirstLaunch();
      final hasSeenTutorial = await OnboardingService.hasSeenTutorial();
      
      if (isFirstLaunch && !hasSeenTutorial) {
        setState(() {
          _showOnboarding = true;
        });
        return;
      }
      
      // Initialize app normally
      await _initializeAndLoadTransactions();
      
      // Check if we should show sample data prompt
      if (_transactions.isEmpty && isFirstLaunch) {
        setState(() {
          _showSampleDataPrompt = true;
        });
      }
    } catch (e) {
      debugPrint('Error during onboarding check: $e');
      // Fallback to normal initialization
      await _initializeAndLoadTransactions();
    }
  }

  /// Complete onboarding and proceed to app
  void _completeOnboarding() {
    setState(() {
      _showOnboarding = false;
    });
    _initializeAndLoadTransactions();
  }

  /// Load sample data for new users
  Future<void> _loadSampleData() async {
    try {
      final sampleTransactions = SampleDataHelper.getSampleTransactions();
      final transactionModels = sampleTransactions.map((sample) {
        return TransactionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: sample.amount,
          type: sample.type,
          date: sample.date,
          category: sample.category,
          customCategory: sample.description,
          paymentMode: 'Sample',
        );
      }).toList();

      // Save sample transactions
      await _secureStorage.saveTransactions(transactionModels);
      
      // Reload transactions
      await _loadTransactions();
      
      setState(() {
        _showSampleDataPrompt = false;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample data loaded! You can clear it anytime from settings.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading sample data: $e');
      setState(() {
        _showSampleDataPrompt = false;
      });
    }
  }

  /// Skip sample data and start fresh
  void _skipSampleData() {
    setState(() {
      _showSampleDataPrompt = false;
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed from background - refresh data if needed
        debugPrint('App resumed from background - refreshing data');
        if (_isInitialized) {
          _refreshDataOnResume();
        }
        break;
      case AppLifecycleState.paused:
        // App went to background
        debugPrint('App went to background');
        break;
      case AppLifecycleState.inactive:
        // App became inactive (e.g., phone call)
        debugPrint('App became inactive');
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        debugPrint('App is being terminated');
        break;
      case AppLifecycleState.hidden:
        // App is hidden (iOS/Android specific)
        debugPrint('App is hidden');
        break;
    }
  }

  /// Refresh data when app resumes from background
  Future<void> _refreshDataOnResume() async {
    if (_isLoading) return; // Prevent multiple simultaneous refreshes
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Reload transactions to ensure data is fresh
      await _loadTransactions();
      
      setState(() {
        _isLoading = false;
      });
      
      debugPrint('Data refreshed successfully on app resume');
    } catch (e) {
      debugPrint('Error refreshing data on app resume: $e');
      setState(() {
        _isLoading = false;
      });
      
      // If refresh fails, try reinitializing
      _reinitializeApp();
    }
  }

  /// Reinitialize the app if something goes wrong
  Future<void> _reinitializeApp() async {
    debugPrint('Reinitializing app due to error...');
    try {
      setState(() {
        _isInitialized = false;
        _isLoading = true;
      });
      
      await _initializeAndLoadTransactions();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error during app reinitialization: $e');
      setState(() {
        _isLoading = false;
        _transactions = [];
        _totalBalance = 0.0;
      });
    }
  }

  /// Initialize secure storage and load transactions
  Future<void> _initializeAndLoadTransactions() async {
    if (_isLoading) return; // Prevent multiple simultaneous initializations
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('Main: Initializing secure transaction service...');
      
      // Initialize the secure transaction service
      await _secureStorage.initialize();
      
      // Test storage integrity and repair if needed
      final storageOk = await _secureStorage.testAndRepairStorage();
      if (!storageOk) {
        print('Main: Storage repair failed, continuing with empty state');
      }
      
      // Attempt to migrate from plain text storage
      final migrated = await _secureStorage.migrateFromPlainTextStorage();
      if (migrated) {
        print('Main: Successfully migrated transactions to encrypted storage');
      }
      
      // Load transactions after initialization/migration
      await _loadTransactions();
      _calculateBalance();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
      print('Main: Initialization complete - ${_transactions.length} transactions loaded');
      
    } catch (e) {
      print('Main: Error initializing secure storage: $e');
      
      // Fallback to loading without migration
      try {
        await _loadTransactions();
        _calculateBalance();
        
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        
        print('Main: Fallback initialization successful');
      } catch (fallbackError) {
        print('Main: Fallback loading also failed: $fallbackError');
        setState(() {
          _isInitialized = false;
          _isLoading = false;
          _transactions = [];
          _totalBalance = 0.0;
        });
      }
    }
    
    // Initialize non-critical services lazily after UI is built
    if (_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LazyInitializationService.instance.initializeLazily();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show onboarding tutorial if needed
    if (_showOnboarding) {
      return OnboardingTutorial(
        onComplete: _completeOnboarding,
        onSkip: _completeOnboarding,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SecureMoney'),
        centerTitle: true,
        actions: [
          const ThemeToggleButton(),
        ],
      ),
      body: _isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your financial data...'),
              ],
            ),
          )
        : !_isInitialized
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your internet connection and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reinitializeApp,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _showSampleDataPrompt
            ? SampleDataHelper.buildSampleDataPrompt(
                onLoadSample: _loadSampleData,
                onAddFirst: _skipSampleData,
              )
            : _getSelectedScreen(),
      bottomNavigationBar: (!_isLoading && _isInitialized && !_showSampleDataPrompt) 
        ? BottomNavigationBar(
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
          )
        : null,
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          transactions: _transactions,
          totalBalance: _totalBalance,
          onTransactionsUpdated: _loadTransactions,
          onSaveTransaction: _saveTransaction,
        );
      case 1:
        return TransactionScreen(
          onTransactionsUpdated: () {
            _loadTransactions(); // Reload transactions when returning
          },
        );
      case 2:
        return ReportsScreen(transactions: _transactions);
      default:
        return DashboardScreen(
          transactions: _transactions, 
          totalBalance: _totalBalance, 
          onTransactionsUpdated: _loadTransactions,
          onSaveTransaction: _saveTransaction,
        );
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
      print('Main: Starting transaction load...');
      final loadedTransactions = await _secureStorage.loadTransactions();
      print('Main: Loaded ${loadedTransactions.length} transactions');
      
      if (mounted) {
        setState(() {
          _transactions = loadedTransactions;
        });
        _calculateBalance(); // Recalculate balance after loading transactions
        print('Main: State updated with ${_transactions.length} transactions');
      }
    } catch (e) {
      print('Main: Error loading transactions: $e');
      
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
        
        if (mounted) {
          setState(() {
            _transactions = legacyTransactions;
          });
          
          _calculateBalance(); // Recalculate balance after migration
        }
        debugPrint('Successfully migrated ${legacyTransactions.length} transactions from legacy storage in main.dart');
      }
    } catch (e) {
      debugPrint('Error during legacy migration in main.dart: $e');
      if (mounted) {
        setState(() {
          _transactions = [];
        });
      }
    }
  }

  // Save a new or updated transaction
  Future<void> _saveTransaction(TransactionModel newTransaction) async {
    try {
      setState(() {
        if (newTransaction.id == null) {
          // New transaction - generate unique ID with milliseconds precision
          newTransaction.id = '${DateTime.now().millisecondsSinceEpoch}_${_transactions.length}';
          _transactions.add(newTransaction);
          debugPrint('✅ Added new transaction with ID: ${newTransaction.id}');
        } else {
          // Update existing transaction
          int index = _transactions.indexWhere((txn) => txn.id == newTransaction.id);
          if (index != -1) {
            _transactions[index] = newTransaction;
            debugPrint('✅ Updated transaction with ID: ${newTransaction.id}');
          } else {
            debugPrint('⚠️ Transaction with ID ${newTransaction.id} not found for update');
          }
        }
      });

      // Save to secure storage
      await _secureStorage.saveTransactions(_transactions);
      debugPrint('✅ Saved ${_transactions.length} transactions to secure storage');
      
      // Recalculate balance
      _calculateBalance();
      
      // Check for achievements (gamification)
      await _checkForAchievements();
      
      // Force UI refresh by calling setState
      if (mounted) {
        setState(() {
          // This will trigger a rebuild of all child widgets
        });
      }
      
    } catch (e) {
      debugPrint('❌ Error saving transaction: $e');
      rethrow;
    }
  }

  // Check for new achievements after transaction changes
  Future<void> _checkForAchievements() async {
    try {
      // Calculate total categories used
      final categories = _transactions
          .map((t) => t.category == 'Other' ? t.customCategory ?? 'Other' : t.category)
          .toSet()
          .length;
      
      // Calculate total amount
      final totalAmount = _transactions.fold(0.0, (sum, t) => sum + t.amount);
      
      // Check feature usage
      final hasUsedExport = await GamificationService.hasUsedFeature('export');
      final hasUsedImport = await GamificationService.hasUsedFeature('import');
      final hasUsedReports = await GamificationService.hasUsedFeature('reports');
      
      // Check for new achievements
      final newAchievements = await GamificationService.checkForNewAchievements(
        totalTransactions: _transactions.length,
        totalCategories: categories,
        totalAmount: totalAmount,
        hasUsedExport: hasUsedExport,
        hasUsedImport: hasUsedImport,
        hasUsedReports: hasUsedReports,
      );
      
      // Show achievement notifications
      for (final achievement in newAchievements) {
        if (mounted) {
          GamificationService.showAchievementNotification(context, achievement);
        }
      }
      
      // Update stats
      await GamificationService.updateStats(
        transactionCount: _transactions.length,
        totalAmount: totalAmount,
      );
      
    } catch (e) {
      debugPrint('Error checking achievements: $e');
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
    
    if (mounted) {
      setState(() {
        _totalBalance = balance; // Update the total balance
      });
    }
    
    // Debug output (can be removed in production)
    debugPrint('Main - Loaded ${_transactions.length} transactions, Income: $totalIncome, Expenses: $totalExpenses, Balance: $balance');
  }

  /// Handle memory pressure and cleanup
  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    debugPrint('Memory pressure detected - performing cleanup');
    
    // Clear any cached data that can be reloaded
    // Note: We keep essential transaction data but could clear UI caches
    LazyInitializationService.instance.clearCaches();
  }

  /// Handle platform messages (for additional error recovery)
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // Ensure UI updates properly when system theme changes
    if (mounted) {
      setState(() {
        // Force rebuild to handle theme changes properly
      });
    }
  }
}
