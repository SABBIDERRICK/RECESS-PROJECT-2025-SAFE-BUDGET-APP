// lib/screens/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:safe_budget/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  // Sample mock transactions
  final List<Map<String, dynamic>> _transactions = const [
    {
      'type': 'Deposit',
      'amount': 500.00,
      'date': '2025-07-10',
      'purpose': 'Tuition',
    },
    {
      'type': 'Withdrawal',
      'amount': 75.00,
      'date': '2025-07-09',
      'purpose': 'Books',
    },
    {
      'type': 'Withdrawal',
      'amount': 120.00,
      'date': '2025-07-08',
      'purpose': 'Rent',
    },
    {
      'type': 'Deposit',
      'amount': 300.00,
      'date': '2025-07-07',
      'purpose': 'Scholarship',
    },
    {
      'type': 'Withdrawal',
      'amount': 50.00,
      'date': '2025-07-06',
      'purpose': 'Meals',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Transactions',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: getBaseGradient(), // your reusable gradient function
        ),
        child:
            user == null
                ? const Center(child: Text('Not logged in'))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('transactions')
                          .orderBy('date', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final transaction = docs[index].data();
                        final isDeposit = transaction['type'] == 'Deposit';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[100],
                              child: Icon(
                                isDeposit
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: Colors.green[800],
                              ),
                            ),
                            title: Text(
                              transaction['purpose'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              transaction['date'] != null &&
                                      transaction['date'] is Timestamp
                                  ? (transaction['date'] as Timestamp)
                                      .toDate()
                                      .toString()
                                      .substring(0, 16)
                                  : '',
                            ),
                            trailing: Text(
                              (isDeposit ? '+' : '-') +
                                  'USh${(transaction['amount'] as num).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }
}
