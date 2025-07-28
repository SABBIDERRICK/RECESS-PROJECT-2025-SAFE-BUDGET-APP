// lib/screens/deposit_screen.dart

import 'package:flutter/material.dart';
import 'package:safe_budget/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_budget/services/notification_service.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();

  void _submitDeposit() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final amount = double.parse(_amountController.text.trim());
      final purpose = _purposeController.text.trim();
      final reference = _referenceController.text.trim();
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final balanceSnap = await userDoc.get();
      double balance = 0.0;
      if (balanceSnap.exists &&
          balanceSnap.data() != null &&
          balanceSnap.data()!['balance'] != null) {
        balance = (balanceSnap.data()!['balance'] as num).toDouble();
      }

      try {
        // Add transaction
        await userDoc.collection('transactions').add({
          'type': 'Deposit',
          'amount': amount,
          'purpose': purpose,
          'reference': reference,
          'date': FieldValue.serverTimestamp(),
        });
        // Update balance
        await userDoc.set({
          'balance': balance + amount,
        }, SetOptions(merge: true));

        // Show success notification
        await NotificationService().showDepositNotification(
          amount: amount,
          purpose: purpose,
          reference: reference.isNotEmpty ? reference : null,
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Deposit successful!')));
        // Clear form
        _amountController.clear();
        _purposeController.clear();
        _referenceController.clear();
      } catch (e) {
        // Show error notification
        await NotificationService().showErrorNotification(
          title: 'Deposit Failed',
          body: 'Failed to process deposit. Please try again.',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Deposit Funds'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: getBaseGradient(), // your reusable gradient function
        ),
        padding: const EdgeInsets.all(20),
        child:
            user == null
                ? const Center(child: Text('Not logged in'))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('allocations')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    final List<String> purposes = [
                      ...docs.map((doc) => doc.data()['title'] as String),
                    ];
                    if (purposes.isEmpty) {
                      return const Center(
                        child: Text(
                          'Allocate funds to continue',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }
                    return Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Amount
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter deposit amount';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Enter a valid amount';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Purpose Dropdown
                          DefaultTextStyle(
                            style: const TextStyle(color: Colors.white),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Purpose',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                              value:
                                  _purposeController.text.isNotEmpty
                                      ? _purposeController.text
                                      : null,
                              style: const TextStyle(
                                color: Colors.white,
                              ), // selected value color
                              dropdownColor:
                                  Theme.of(
                                    context,
                                  ).primaryColor, // dropdown menu background
                              items:
                                  purposes
                                      .map(
                                        (purpose) => DropdownMenuItem(
                                          value: purpose,
                                          child: Text(
                                            purpose,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ), // menu items now white
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _purposeController.text = value ?? '';
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Select a purpose'
                                          : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Optional Reference Number
                          TextFormField(
                            controller: _referenceController,
                            decoration: const InputDecoration(
                              labelText: 'Reference Number (optional)',
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.account_balance_wallet),
                              label: const Text('Deposit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _submitDeposit,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
