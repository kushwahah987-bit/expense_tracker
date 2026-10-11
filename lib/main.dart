import 'package:flutter/material.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double todayExpense = 250.00;
  double monthlyExpense = 4850.00;

  List<Map<String, dynamic>> transactions = [
    {"title": "Auto Fare (Convenience)", "amount": 50.0, "type": "Cash", "time": "10:30 AM"},
    {"title": "UPI to Swiggy", "amount": 200.0, "type": "UPI (Auto)", "time": "01:15 PM"},
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  void _addExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Kharcha Add Karein',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Detail (e.g. Milk, Cab, Lunch)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;
                setState(() {
                  double amt = double.parse(_amountController.text);
                  transactions.insert(0, {
                    "title": _titleController.text,
                    "amount": amt,
                    "type": "Manual",
                    "time": "Abhi"
                  });
                  todayExpense += amt;
                  monthlyExpense += amt;
                });
                _titleController.clear();
                _amountController.clear();
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Karein'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense & Convenience Tracker'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Aaj Ka Kharcha', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 5),
                      Text('₹ $todayExpense', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ],
                  ),
                  Container(height: 40, width: 1, color: Colors.indigo.shade200),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Is Mahine Ka Total', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 5),
                      Text('₹ $monthlyExpense', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final item = transactions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item['type'].contains('UPI') ? Colors.green.shade100 : Colors.orange.shade100,
                      child: Icon(
                        item['type'].contains('UPI') ? Icons.qr_code_scanner : Icons.directions_bus,
                        color: item['type'].contains('UPI') ? Colors.green : Colors.orange,
                      ),
                    ),
                    title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("${item['type']} • ${item['time']}"),
                    trailing: Text('₹ ${item['amount']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}