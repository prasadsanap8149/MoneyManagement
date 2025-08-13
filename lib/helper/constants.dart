import '../models/transaction_model.dart';

class Constants{
  static bool isMobileDevice = true;
  static final transactionType=['Income', 'Expense'];
  
  // Payment modes for transactions
  static final paymentModes = <String>[
    "Cash",
    "UPI",
    "Debit Card",
    "Credit Card",
    "Cheque",
    "Net Banking",
    "Other"
  ];
  
  // static final transactionCategory=['Select Category','Salary', 'Food', 'Rent','Glossary', 'Lunch Box', 'Travel','Petrol', 'Cloth', 'Party','Other'];
  static final transactionCategory = <String>[
    "Select Category",
    "Other 📋",
    "Apparel 👕",
    "Bonuses 💰",
    "Coffee Shops ☕",
    "Clothing and Personal Care 👔",
    "Dining Out 🍽️",
    "Donations 🤝",
    "Education 📚",
    "Entertainment 🎬",
    "Freelance Income 💻",
    "Fuel ⛽",
    "Gifts 🎁",
    "Groceries 🛒",
    "Gym Memberships 💪",
    "Home Insurance 🏠",
    "Hobbies 🎨",
    "Insurance 🛡️",
    "Insurance Premiums 📄",
    "Maintenance and Repairs 🔧",
    "Medical Bills 🏥",
    "Medications 💊",
    "Miscellaneous 📦",
    "Movies and Events 🎭",
    "Online Courses 🖥️",
    "Property Taxes 🏘️",
    "Public Transit 🚌",
    "Rent/Mortgage 🏡",
    "Rental Income 🏢",
    "Retirement Accounts 👴",
    "Salary 💼",
    "Savings and Investments 📈",
    "Savings Contributions 🏦",
    "Shoes 👟",
    "Snacks 🍿",
    "Stock Investments 📊",
    "Subscriptions 📱",
    "Travel Expenses ✈️",
    "Tuition Fees 🎓",
    "Utilities ⚡",
    "Books and Magazines 📖",
    "Business Expenses 💼",
    "Car Maintenance 🚗",
    "Child Care 👶",
    "Commission 💵",
    "Credit Card Payments 💳",
    "Debt Payments 💰",
    "Electronics 📺",
    "Emergency Fund 🚨",
    "Family Support 👪",
    "Fitness and Health ⚕️",
    "Food Delivery 🚚",
    "Furniture 🛋️",
    "Gaming 🎮",
    "Government Benefits 🏛️",
    "Home Decor 🖼️",
    "Investment Returns 💹",
    "Laundry and Dry Cleaning 👕",
    "Legal Fees ⚖️",
    "Loans 💳",
    "Mobile and Internet 📶",
    "Office Supplies 📎",
    "Parking 🅿️",
    "Pet Care 🐕",
    "Photography 📸",
    "Professional Services 🤝",
    "Repairs and Maintenance 🛠️",
    "Side Hustle 💪",
    "Software and Apps 💻",
    "Spa and Beauty 💅",
    "Streaming Services 📺",
    "Taxi and Rideshare 🚕",
    "Tax Refunds 💰",
    "Tools and Equipment 🔨",
    "Training and Courses 📘",
    "Vehicle Insurance 🚙",
    "Veterinary Bills 🐾"
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

  /// Helper function to get category display name with emoji
  static String getCategoryDisplayName(String category) {
    // Handle backward compatibility for existing categories without emojis
    for (String categoryWithEmoji in transactionCategory) {
      if (categoryWithEmoji.startsWith(category) || 
          categoryWithEmoji.contains(category)) {
        return categoryWithEmoji;
      }
    }
    
    // If not found, return the original category
    return category;
  }
  
  /// Helper function to get category name without emoji for storage
  static String getCategoryStorageName(String categoryWithEmoji) {
    // Remove emoji and trim whitespace
    return categoryWithEmoji.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true), '').trim();
  }
  
  /// Helper function to check if category exists (with or without emoji)
  static bool isCategoryValid(String category) {
    // Check exact match first
    if (transactionCategory.contains(category)) {
      return true;
    }
    
    // Check if category without emoji exists
    for (String categoryWithEmoji in transactionCategory) {
      if (getCategoryStorageName(categoryWithEmoji) == category) {
        return true;
      }
    }
    
    return false;
  }
}
