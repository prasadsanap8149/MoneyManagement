import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_management/helper/constants.dart';

import '../ad_service/widgets/banner_ad.dart';
import '../models/transaction_model.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final Function onSave;
  final TransactionModel? transaction;

  const AddEditTransactionScreen(
      {super.key, required this.onSave, this.transaction});

  @override
  _AddEditTransactionScreenState createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Income';
  String _category = 'Select Category';
  String? _customCategory;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCategories = [];
  double? _amount;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    print('Transaction received: ${widget.transaction}');
    if (widget.transaction != null) {
      _amount = widget.transaction!.amount;
      _type = widget.transaction!.type;
      _selectedDate = widget.transaction!.date;
      _category = widget.transaction!.category;
      _customCategory = widget.transaction!.customCategory;
    }
    _filteredCategories =
        Constants.transactionCategory; // Initially, all categories are shown
    _searchController.addListener(() {
      filterCategories();
    });
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
      );

      widget.onSave(transaction);
      Navigator.pop(context); // Navigate back after saving
    }
  }

  void _cancelForm() {
    Navigator.pop(context);
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                  ),
                  items: Constants.transactionType.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) => setState(() {
                    _type = value!;
                  }),
                ),
                const SizedBox(height: 14),
                const Text('Please select other option for custom category',style: TextStyle(fontWeight: FontWeight.bold,),textAlign: TextAlign.center,),
                const SizedBox(height: 2),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                  ),
                  items: Constants.transactionCategory.map((category) {
                    return DropdownMenuItem(
                        value: category, child: Text(category));
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
                if (_category == 'Other')
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
                // const SizedBox(height: 16),
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
