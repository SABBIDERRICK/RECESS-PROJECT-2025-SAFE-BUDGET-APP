// lib/screens/withdraw_screen.dart

import 'package:flutter/material.dart';
import 'package:safe_budget/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_budget/services/notification_service.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedPurpose;

  final List<String> _purposes = [
    'Tuition',
    'Rent',
    'Meals',
    'Books',
    'Transport',
    'Other',
  ];

  void _submitWithdrawal() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final amount = double.parse(_amountController.text.trim());
      final purpose = _selectedPurpose ?? '';
      final note = _noteController.text.trim();
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
      // Fetch allocation for the selected purpose
      final allocationSnap =
          await userDoc
              .collection('allocations')
              .where('title', isEqualTo: purpose)
              .limit(1)
              .get();
      double allocated = 0.0;
      if (allocationSnap.docs.isNotEmpty &&
          allocationSnap.docs.first.data()['amount'] != null) {
        allocated =
            (allocationSnap.docs.first.data()['amount'] as num).toDouble();
      }
      if (amount > allocated) {
        await NotificationService().showErrorNotification(
          title: 'Withdrawal Failed',
          body:
              'Cannot withdraw more than allocated for $purpose. Max: ${allocated.toStringAsFixed(2)}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot withdraw more than allocated for $purpose. Max: ${allocated.toStringAsFixed(2)}',
            ),
          ),
        );
        return;
      }
      if (amount > balance) {
        await NotificationService().showErrorNotification(
          title: 'Insufficient Funds',
          body: 'Insufficient funds for this withdrawal.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient funds for this withdrawal.'),
          ),
        );
        return;
      }

      try {
        // Add transaction
        await userDoc.collection('transactions').add({
          'type': 'Withdrawal',
          'amount': amount,
          'purpose': purpose,
          'note': note,
          'date': FieldValue.serverTimestamp(),
        });
        // Update balance
        await userDoc.set({
          'balance': balance - amount,
        }, SetOptions(merge: true));

        // Show success notification
        await NotificationService().showWithdrawalNotification(
          amount: amount,
          purpose: purpose,
          note: note.isNotEmpty ? note : null,
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Withdrawal successful!')));
        // Clear form
        _amountController.clear();
        _noteController.clear();
        setState(() {
          _selectedPurpose = null;
        });
      } catch (e) {
        // Show error notification
        await NotificationService().showErrorNotification(
          title: 'Withdrawal Failed',
          body: 'Failed to process withdrawal. Please try again.',
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
        title: const Text(
          'Withdraw Funds',
          style: TextStyle(color: Colors.white),
        ),
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
                    // Remove 'Other' from the purposes list
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
                    String? selectedPurpose = _selectedPurpose;
                    return StatefulBuilder(
                      builder: (context, setLocalState) {
                        return Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Purpose Dropdown
                              Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor:
                                      Colors.white, // dropdown menu background
                                  textTheme: Theme.of(
                                    context,
                                  ).textTheme.copyWith(
                                    titleMedium: const TextStyle(
                                      color: Colors.white,
                                    ), // selected value color (Flutter 3+)
                                  ),
                                  inputDecorationTheme:
                                      const InputDecorationTheme(
                                        labelStyle: TextStyle(
                                          color: Colors.white,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                ),
                                child: DefaultTextStyle(
                                  style: const TextStyle(color: Colors.white),
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Purpose',
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                      ),
                                      border: OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    value: selectedPurpose,
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
                                      setLocalState(() {
                                        selectedPurpose = value;
                                      });
                                      _selectedPurpose = value;
                                    },
                                    validator:
                                        (value) =>
                                            value == null || value.isEmpty
                                                ? 'Select a purpose'
                                                : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Amount Field
                              TextFormField(
                                controller: _amountController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                  prefixIcon: Icon(Icons.attach_money),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter amount';
                                  }
                                  final amount = double.tryParse(value);
                                  if (amount == null || amount <= 0) {
                                    return 'Enter a valid amount';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              // Optional Note Field
                              TextFormField(
                                controller: _noteController,
                                decoration: const InputDecoration(
                                  labelText: 'Note (optional)',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 30),
                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.outbound),
                                  label: const Text('Withdraw'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _submitWithdrawal,
                                ),
                              ),
                            ],
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
