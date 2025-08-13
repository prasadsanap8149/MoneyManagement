import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:secure_money_management/helper/constants.dart';
import 'package:secure_money_management/services/currency_service.dart';
import 'package:secure_money_management/services/first_use_prompts_service.dart';

import '../ad_service/widgets/banner_ad.dart';
import '../models/transaction_model.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final Function onSave;
  final TransactionModel? transaction;

  const AddEditTransactionScreen(
      {super.key, required this.onSave, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Income';
  String _category = 'Select Category';
  String? _customCategory;
  String? _paymentMode; // Added payment mode
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCategories = [];
  double? _amount;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    debugPrint('Transaction received: ${widget.transaction}');
    if (widget.transaction != null) {
      _amount = widget.transaction!.amount;
      _type = widget.transaction!.type;
      _selectedDate = widget.transaction!.date;
      _category = Constants.getCategoryDisplayName(widget.transaction!.category);
      _customCategory = widget.transaction!.customCategory;
      _paymentMode = widget.transaction!.paymentMode;
    } else {
      _category = Constants.transactionCategory[0]; // Default placeholder
    }

    _filteredCategories =
        Constants.transactionCategory; // Initially, all categories are shown
    _searchController.addListener(() {
      filterCategories();
    });
    
    // Show first-time prompts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFirstTimePrompts();
    });
  }

  /// Show helpful prompts for first-time users
  Future<void> _showFirstTimePrompts() async {
    if (widget.transaction == null) { // Only for new transactions
      await FirstUsePromptsService.showFirstUsePrompt(
        context,
        featureId: 'add_transaction_form',
        title: 'Create Your Transaction! 💰',
        message: 'Fill in the details below to track your income or expenses. '
                'Choose categories and payment modes for better organization.',
        icon: Icons.receipt_long,
        color: Colors.green,
      );
    }
  }

  void filterCategories() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = Constants.transactionCategory
          .where((category) => category.toLowerCase().contains(query))
          .toList();
    });
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final transaction = TransactionModel(
        id: widget.transaction?.id,
        amount: _amount!,
        type: _type,
        date: _selectedDate,
        category: _category,
        customCategory: _customCategory,
        paymentMode: _paymentMode, // Include payment mode
      );

      widget.onSave(transaction);
      Navigator.pop(context); // Navigate back after saving
    }
  }

  void _cancelForm() {
    Navigator.pop(context);
  }

  /// Get appropriate icon for category
  IconData _getCategoryIcon(String category) {
    // Remove emoji if present to get clean category name
    String cleanCategory = Constants.getCategoryStorageName(category).toLowerCase();
    
    switch (cleanCategory) {
      case 'food':
      case 'groceries':
      case 'dining out':
      case 'food delivery':
        return Icons.restaurant;
      case 'transport':
      case 'fuel':
      case 'car maintenance':
      case 'public transit':
      case 'taxi and rideshare':
        return Icons.directions_car;
      case 'entertainment':
      case 'movies and events':
      case 'gaming':
        return Icons.movie;
      case 'shopping':
      case 'apparel':
      case 'clothing and personal care':
      case 'shoes':
        return Icons.shopping_bag;
      case 'bills':
      case 'utilities':
      case 'insurance premiums':
        return Icons.receipt;
      case 'rent':
      case 'house rent':
      case 'rent/mortgage':
      case 'home insurance':
        return Icons.home;
      case 'salary':
      case 'income':
      case 'freelance income':
      case 'bonuses':
        return Icons.account_balance_wallet;
      case 'healthcare':
      case 'medical':
      case 'medical bills':
      case 'medications':
        return Icons.local_hospital;
      case 'education':
      case 'tuition fees':
      case 'online courses':
      case 'training and courses':
        return Icons.school;
      case 'investment':
      case 'stock investments':
      case 'savings and investments':
        return Icons.trending_up;
      case 'savings':
      case 'savings contributions':
      case 'emergency fund':
        return Icons.savings;
      case 'travel':
      case 'travel expenses':
        return Icons.flight;
      case 'fitness':
      case 'fitness and health':
      case 'gym memberships':
        return Icons.fitness_center;
      case 'other':
        return Icons.more_horiz;
      case 'coffee shops':
        return Icons.local_cafe;
      case 'gifts':
        return Icons.card_giftcard;
      case 'subscriptions':
      case 'streaming services':
        return Icons.subscriptions;
      case 'electronics':
        return Icons.devices;
      case 'pet care':
      case 'veterinary bills':
        return Icons.pets;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Add Transaction'
            : 'Edit Transaction'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: _amount != null ? _amount.toString() : '',
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null || double.tryParse(value)! <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                  onSaved: (value) => _amount = double.tryParse(value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: InputDecoration(
                    labelText: 'Transaction Type',
                    prefixIcon: Icon(
                      _type == 'Income' ? Icons.trending_up : Icons.trending_down,
                      color: _type == 'Income' ? Colors.green : Colors.red,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                  ),
                  items: Constants.transactionType.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            type == 'Income' ? Icons.add_circle : Icons.remove_circle,
                            color: type == 'Income' ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(type),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() {
                    _type = value!;
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select "Other" to create a custom category',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category, color: Colors.teal),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                  ),
                  items: Constants.transactionCategory.map((category) {
                    IconData categoryIcon = _getCategoryIcon(category);
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(categoryIcon, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null || value == Constants.transactionCategory[0]) {
                      return 'Please select a valid category';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _category = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_category == 'Other' || _category == 'Other 📋')
                  TextFormField(
                    initialValue: _customCategory == null
                        ? ''
                        : _customCategory.toString(),
                    decoration: InputDecoration(
                      labelText: 'Custom Category',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a custom category';
                      }
                      return null;
                    },
                    onSaved: (value) => _customCategory = value!,
                  ),
                if (_category == 'Other' || _category == 'Other 📋')
                  const SizedBox(height: 16),
                
                // Payment Mode Dropdown
                DropdownButtonFormField<String>(
                  value: _paymentMode,
                  decoration: InputDecoration(
                    labelText: 'Payment Mode (Optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                  ),
                  hint: const Text('Select payment mode'),
                  items: Constants.paymentModes.map((mode) {
                    return DropdownMenuItem(
                        value: mode, child: Text(mode));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _paymentMode = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _presentDatePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.teal),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.teal),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _cancelForm,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10), // Spacing between buttons
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child:
                            Text(widget.transaction == null ? 'Add' : 'Update'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (Constants.isMobileDevice) const GetBannerAd(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
