// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:safe_budget/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? get user => FirebaseAuth.instance.currentUser;

  Future<void> _addOrEditAllocation({
    Map<String, dynamic>? allocation,
    String? docId,
  }) async {
    // Get current balance and existing allocations
    double currentBalance = 0.0;
    double existingAllocationsTotal = 0.0;

    if (user != null) {
      // Get current balance
      final balanceDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
      if (balanceDoc.exists &&
          balanceDoc.data() != null &&
          balanceDoc.data()!['balance'] != null) {
        currentBalance = (balanceDoc.data()!['balance'] as num).toDouble();
      }

      // Get existing allocations total (excluding the one being edited)
      final allocationsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('allocations')
              .get();

      for (final doc in allocationsSnapshot.docs) {
        if (docId == null || doc.id != docId) {
          // Don't count the allocation being edited
          final data = doc.data();
          if (data['amount'] != null) {
            existingAllocationsTotal += (data['amount'] as num).toDouble();
          }
        }
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final titleController = TextEditingController(
          text: allocation?['title'] ?? '',
        );
        final amountController = TextEditingController(
          text: allocation != null ? allocation['amount'].toString() : '',
        );

        // Calculate available amount for allocation
        final double currentAllocationAmount =
            allocation != null ? (allocation['amount'] as num).toDouble() : 0.0;
        final double availableAmount =
            currentBalance - existingAllocationsTotal + currentAllocationAmount;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                allocation == null ? 'Add Allocation' : 'Edit Allocation',
                style: const TextStyle(color: Colors.black),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Colors.black),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(color: Colors.black),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(color: Colors.black),
                      onChanged: (value) {
                        setState(() {
                          // This will trigger a rebuild to show validation
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Show validation message
                    Builder(
                      builder: (context) {
                        final enteredAmount =
                            double.tryParse(amountController.text.trim()) ??
                            0.0;
                        if (enteredAmount > availableAmount) {
                          return Text(
                            'Amount exceeds available balance by USh${(enteredAmount - availableAmount).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0.0;

                    if (title.isNotEmpty && amount > 0) {
                      if (amount <= availableAmount) {
                        Navigator.pop(context, {
                          'title': title,
                          'amount': amount,
                        });
                      } else {
                        // Show error message and notification
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cannot allocate USh${amount.toStringAsFixed(2)}. Available: USh${availableAmount.toStringAsFixed(2)}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && user != null) {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('allocations');
      if (docId != null) {
        await ref.doc(docId).set(result);
      } else {
        await ref.add(result);
      }
    }
  }

  Future<void> _deleteAllocation(String docId) async {
    if (user != null) {
      // Get allocation details before deleting for notification
      final allocationDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('allocations')
              .doc(docId)
              .get();

      if (allocationDoc.exists) {
        final allocationData = allocationDoc.data()!;

        // Delete the allocation
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('allocations')
            .doc(docId)
            .delete();
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _allocationsStream {
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('allocations')
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _balanceStream {
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .snapshots();
  }

  Color getContrastingTextColor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 19, 39, 56),
        title: const Text('Safe Budget', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(gradient: getBaseGradient()),
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              // Current Balance Card
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _balanceStream,
                builder: (context, snapshot) {
                  double balance = 0.0;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data();
                    if (data != null && data['balance'] != null) {
                      balance = (data['balance'] as num).toDouble();
                    }
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 19, 39, 56),
                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Balance',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'USh ${formatter.format(balance)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 25),

              // Spending Breakdown Pie Chart
              if (user != null)
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user!.uid)
                          .collection('transactions')
                          .where('type', isEqualTo: 'Withdrawal')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Text(
                        'No spending data yet',
                        style: TextStyle(color: Colors.white70),
                      );
                    }
                    // Aggregate withdrawals by category
                    final Map<String, double> categoryTotals = {};
                    double total = 0.0;
                    for (final doc in docs) {
                      final data = doc.data();
                      final category = data['purpose'] ?? 'Other';
                      final amount =
                          (data['amount'] as num?)?.toDouble() ?? 0.0;
                      categoryTotals[category] =
                          (categoryTotals[category] ?? 0) + amount;
                      total += amount;
                    }
                    final List<PieChartSectionData> sections = [];
                    final List<Map<String, dynamic>> legendItems = [];
                    final List<Color> colorPalette = [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                      Colors.red,
                      Colors.teal,
                      Colors.brown,
                      Colors.pink,
                      Colors.amber,
                      Colors.cyan,
                      Colors.deepOrange,
                      Colors.indigo,
                      Colors.lime,
                      Colors.deepPurple,
                      Colors.lightBlue,
                      Colors.lightGreen,
                      Colors.yellow,
                      Colors.grey,
                    ];
                    final categoryList = categoryTotals.keys.toList();
                    final Map<String, Color> categoryColorMap = {};
                    for (int i = 0; i < categoryList.length; i++) {
                      categoryColorMap[categoryList[i]] =
                          colorPalette[i % colorPalette.length];
                    }
                    categoryTotals.forEach((category, amount) {
                      final percent = total > 0 ? (amount / total * 100) : 0;
                      final color = categoryColorMap[category]!;
                      sections.add(
                        PieChartSectionData(
                          color: color,
                          value: amount,
                          title:
                              percent >= 1
                                  ? '${percent.toStringAsFixed(0)}%'
                                  : '<1%',
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12,
                            color: getContrastingTextColor(color),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                      if (amount > 0) {
                        legendItems.add({
                          'color': color,
                          'category': category,
                          'amount': amount,
                        });
                      }
                    });
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spending Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              sections: sections,
                              centerSpaceRadius: 30,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children:
                              legendItems
                                  .map(
                                    (item) => Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          color: item['color'],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${item['category']}: USh ${formatter.format(item['amount'])}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 25),

              // Allocated Funds Overview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Allocated Funds',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    icon: const Icon(
                      Icons.add,
                      color:
                          Colors
                              .green, // or Theme.of(context).primaryColor for dynamic color
                    ),
                    label: const Text(
                      'Add',
                      style: TextStyle(color: Colors.green),
                    ),
                    onPressed: () => _addOrEditAllocation(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Allocation Summary Card
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _balanceStream,
                builder: (context, balanceSnapshot) {
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _allocationsStream,
                    builder: (context, allocationSnapshot) {
                      double balance = 0.0;
                      double totalAllocated = 0.0;

                      if (balanceSnapshot.hasData &&
                          balanceSnapshot.data!.exists) {
                        final data = balanceSnapshot.data!.data();
                        if (data != null && data['balance'] != null) {
                          balance = (data['balance'] as num).toDouble();
                        }
                      }

                      if (allocationSnapshot.hasData) {
                        for (final doc in allocationSnapshot.data!.docs) {
                          final data = doc.data();
                          if (data['amount'] != null) {
                            totalAllocated +=
                                (data['amount'] as num).toDouble();
                          }
                        }
                      }

                      final double availableForAllocation =
                          balance - totalAllocated;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Allocated',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'USh ${formatter.format(totalAllocated)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Available for Allocation',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'USh ${formatter.format(availableForAllocation)}',
                                  style: TextStyle(
                                    color:
                                        availableForAllocation >= 0
                                            ? Colors.green
                                            : Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _allocationsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No allocations yet',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final allocation = doc.data();
                      return Dismissible(
                        key: ValueKey(doc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteAllocation(doc.id),
                        child: GestureDetector(
                          onTap:
                              () => _addOrEditAllocation(
                                allocation: allocation,
                                docId: doc.id,
                              ),
                          child: _buildAllocationTile(
                            allocation['title'],
                            (allocation['amount'] as num).toDouble(),
                            formatter,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationTile(
    String title,
    double amount,
    NumberFormat formatter,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title),
        trailing: Text('USh ${formatter.format(amount)}'),
        leading: const Icon(Icons.pie_chart_outline),
      ),
    );
  }
}
