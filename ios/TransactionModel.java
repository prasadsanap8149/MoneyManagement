
class TransactionModel {
    String? id;
    String title;
    double amount;
    String type; // 'Income' or 'Expense'
    DateTime date;
    String category; // Added category field

    TransactionModel({
        this.id,
                required this.title,
                required this.amount,
                required this.type,
                required this.date,
                required this.category, // Make category required
    });

    // Convert a TransactionModel object to a JSON-compatible map
    Map<String, dynamic> toJson() => {
        'id': id,
                'title': title,
                'amount': amount,
                'type': type,
                'date': date.toIso8601String(), // Convert DateTime to string
                'category': category, // Include category
    };

    // Create a TransactionModel object from a JSON map
    factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
            id: json['id'],
            title: json['title'],
            amount: json['amount'],
            type: json['type'],
            date: DateTime.parse(json['date']), // Parse string back to DateTime
    category: json['category'], // Parse category
            );
}
