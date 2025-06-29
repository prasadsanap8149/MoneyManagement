import 'package:intl/intl.dart';

import '../models/transaction_model.dart';

class UtilService{
    double calculateBalance(List<TransactionModel> transactions, String transactionType){
     return transactions
         .where((txn) => txn.type == transactionType)
       .fold(0.0, (sum, txn) => sum + (txn.amount > 0 ? txn.amount : 0));
   }
    final indianRupeeFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

}
final UtilService utilService=UtilService();