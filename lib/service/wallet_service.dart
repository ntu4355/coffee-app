import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../model/transaction_model.dart';

class WalletService {
  WalletService._privateConstructor();
  static final WalletService instance = WalletService._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ValueNotifier<double> balanceNotifier = ValueNotifier(0.0);
  final ValueNotifier<List<TransactionModel>> transactionsNotifier =
      ValueNotifier([]);

  double get balance => balanceNotifier.value;
  List<TransactionModel> get transactions => transactionsNotifier.value;

  Future<void> loadWalletData({bool rethrowErrors = false}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Load balance
      final balanceDoc = await _firestore.collection('wallets').doc(uid).get();
      if (balanceDoc.exists) {
        balanceNotifier.value =
            (balanceDoc.data()?['amount'] as num?)?.toDouble() ?? 0.0;
      } else {
        balanceNotifier.value = 0.0;
      }

      // Load transactions
      final transQuery = await _firestore
          .collection('wallets')
          .doc(uid)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .get();

      final loaded = transQuery.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), id: doc.id))
          .toList();

      transactionsNotifier.value = loaded;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load wallet data: $e');
      }
      if (rethrowErrors) rethrow;
    }
  }

  Future<void> deductBalance(double amount, {String? description}) async {
    if (amount <= 0 || balance < amount) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final newBalance = balance - amount;
    balanceNotifier.value = newBalance;

    final transaction = TransactionModel(
      type: TransactionType.purchase,
      amount: amount,
      description: description ?? 'Thanh toán',
    );

    // Update balance in Firestore
    await _firestore.collection('wallets').doc(uid).set({
      'amount': newBalance,
    }, SetOptions(merge: true));

    // Add transaction record
    try {
      final Map<String, dynamic> data = transaction.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore
          .collection('wallets')
          .doc(uid)
          .collection('transactions')
          .add(data);
      transaction.id = docRef.id;

      final list = List<TransactionModel>.from(transactionsNotifier.value);
      list.insert(0, transaction);
      transactionsNotifier.value = list;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save transaction: $e');
      }
    }
  }

  void clear() {
    balanceNotifier.value = 0.0;
    transactionsNotifier.value = [];
  }

  String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)}K';
  }
}
