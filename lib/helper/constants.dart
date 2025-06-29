import '../models/transaction_model.dart';

class Constants{
  static bool isMobileDevice = false;
  static final transactionType=['Income', 'Expense'];
  // static final transactionCategory=['Select Category','Salary', 'Food', 'Rent','Glossary', 'Lunch Box', 'Travel','Petrol', 'Cloth', 'Party','Other'];
  static final transactionCategory = <String>[
    "Select Category",
    "Other",
    "Apparel",
    "Bonuses",
    "Coffee Shops",
    "Clothing and Personal Care",
    "Dining Out",
    "Donations",
    "Education",
    "Entertainment",
    "Freelance Income",
    "Fuel",
    "Gifts",
    "Groceries",
    "Gym Memberships",
    "Home Insurance",
    "Hobbies",
    "Insurance",
    "Insurance Premiums",
    "Maintenance and Repairs",
    "Medical Bills",
    "Medications",
    "Miscellaneous",
    "Movies and Events",
    "Online Courses",
    "Property Taxes",
    "Public Transit",
    "Rent/Mortgage",
    "Rental Income",
    "Retirement Accounts",
    "Salary",
    "Savings and Investments",
    "Savings Contributions",
    "Shoes",
    "Snacks",
    "Stock Investments",
    "Subscriptions",
    "Travel Expenses",
    "Tuition Fees",
    "Utilities"

  ];


  static final List<TransactionModel> transaction = [
    TransactionModel(
      id: '1',
     category: 'Grocery Shopping',
      amount: 50.75,
      type: 'Expense',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: '1',
     category: 'Grocery Shopping',
      amount: 50.75,
      type: 'Expense',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: '1',
     category: 'Grocery Shopping',
      amount: 50.75,
      type: 'Expense',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: '1',
     category: 'Grocery Shopping',
      amount: 50.75,
      type: 'Expense',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: '1',
     category: 'Grocery Shopping',
      amount: 50.75,
      type: 'Expense',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: '2',
     category: 'Salary',
      amount: 1500.00,
      type: 'Income',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TransactionModel(
      id: '3',
     category: 'Electricity Bill',
      amount: 60.20,
      type: 'Expense',
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
    TransactionModel(
      id: '4',
     category: 'Freelance Payment',
      amount: 300.00,
      type: 'Income',
      date: DateTime.now().subtract(const Duration(days: 4)),
    ),
    TransactionModel(
      id: '5',
     category: 'Restaurant',
      amount: 40.00,
      type: 'Expense',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
}