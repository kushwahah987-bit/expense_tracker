import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({Key? key}) : super(key: key);

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  String currentLang = 'en';
  MaterialColor currentThemeColor = Colors.blue;
  bool isLocked = true;

  void toggleLanguage() {
    setState(() {
      currentLang = currentLang == 'en' ? 'hi' : 'en';
    });
  }

  void changeTheme(MaterialColor color) {
    setState(() {
      currentThemeColor = color;
    });
  }

  void unlockApp() {
    setState(() {
      isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: currentThemeColor,
        useMaterial3: true,
      ),
      home: isLocked
          ? PinLockScreen(onUnlock: unlockApp, currentLang: currentLang)
          : HomeScreen(
              currentLang: currentLang,
              onToggleLanguage: toggleLanguage,
              currentThemeColor: currentThemeColor,
              onChangeTheme: changeTheme,
              onLockApp: () => setState(() => isLocked = true),
            ),
    );
  }
}

// --- PIN SECURITY LOCK SCREEN ---
class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final String currentLang;

  const PinLockScreen({Key? key, required this.onUnlock, required this.currentLang}) : super(key: key);

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String enteredPin = "";
  final String correctPin = "1234";

  void _onDigitPress(String digit) {
    if (enteredPin.length < 4) {
      setState(() {
        enteredPin += digit;
      });
      if (enteredPin.length == 4) {
        if (enteredPin == correctPin) {
          widget.onUnlock();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN! Try 1234')),
          );
          setState(() {
            enteredPin = "";
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 60, color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(
              widget.currentLang == 'en' ? 'Enter 4-Digit PIN (Default: 1234)' : '4-अंकों का पिन दर्ज करें (Default: 1234)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < enteredPin.length ? Colors.blueAccent : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            for (var row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['', '0', 'C']])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((digit) {
                  if (digit.isEmpty) return const SizedBox(width: 70, height: 70);
                  return Container(
                    margin: const EdgeInsets.all(10),
                    width: 70,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        if (digit == 'C') {
                          setState(() {
                            enteredPin = "";
                          });
                        } else {
                          _onDigitPress(digit);
                        }
                      },
                      child: Text(digit, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class TransactionItem {
  final String message;
  final double amount;
  final DateTime date;

  TransactionItem({required this.message, required this.amount, required this.date});
}

class HomeScreen extends StatefulWidget {
  final String currentLang;
  final VoidCallback onToggleLanguage;
  final MaterialColor currentThemeColor;
  final Function(MaterialColor) onChangeTheme;
  final VoidCallback onLockApp;

  const HomeScreen({
    Key? key,
    required this.currentLang,
    required this.onToggleLanguage,
    required this.currentThemeColor,
    required this.onChangeTheme,
    required this.onLockApp,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final Telephony telephony = Telephony.instance;
  List<TransactionItem> allTransactions = [];
  late TabController _tabController;

  final Map<String, Map<String, String>> localizedText = {
    'en': {
      'title': 'UPI Expense Tracker',
      'day': 'Day',
      'week': 'Week',
      'month': 'Month',
      'empty': 'No UPI/Debit SMS found.\n(Auto-reading active)',
      'totalSpent': 'Total Spent: Rs. ',
      'theme': 'Change Theme',
    },
    'hi': {
      'title': 'यूपीआई खर्च ट्रैकर',
      'day': 'दिन',
      'week': 'हफ्ता',
      'month': 'महीना',
      'empty': 'कोई यूपीआई एसएमएस नहीं मिला।\n(ऑटो-रीडिंग चालू है)',
      'totalSpent': 'कुल खर्चा: रु. ',
      'theme': 'थीम बदलें',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    initSMSListener();
  }

  void initSMSListener() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted ?? false) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          processMessage(message.body ?? "", message.date != null ? DateTime.fromMillisecondsSinceEpoch(message.date!) : DateTime.now());
        },
        listenInBackground: true,
      );

      List<SmsMessage> messages = await telephony.getInboxMessages(
        columns: [SmsColumn.BODY, SmsColumn.DATE],
      );

      for (var msg in messages) {
        DateTime msgDate = msg.date != null ? DateTime.fromMillisecondsSinceEpoch(msg.date!) : DateTime.now();
        processMessage(msg.body ?? "", msgDate);
      }
    }
  }

  void processMessage(String body, DateTime date) {
    String lowerBody = body.toLowerCase();
    if (lowerBody.contains('debited') || lowerBody.contains('spent') || lowerBody.contains('paid') || lowerBody.contains('sent') || lowerBody.contains('rs.') || lowerBody.contains('inr')) {
      double extractedAmount = extractAmount(body);
      setState(() {
        if (!allTransactions.any((tx) => tx.message == body)) {
          allTransactions.insert(0, TransactionItem(message: body, amount: extractedAmount, date: date));
        }
      });
    }
  }

  double extractAmount(String text) {
    try {
      RegExp regExp = RegExp(r'(?:rs\.?|inr)\s*([\d,]+\.?\d*)', caseSensitive: false);
      Match? match = regExp.firstMatch(text);
      if (match != null && match.group(1) != null) {
        return double.parse(match.group(1)!.replaceAll(',', ''));
      }
    } catch (_) {}
    return 0.0;
  }

  List<TransactionItem> getFilteredTransactions(int tabIndex) {
    DateTime now = DateTime.now();
    return allTransactions.where((tx) {
      if (tabIndex == 0) {
        return tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day;
      } else if (tabIndex == 1) {
        return now.difference(tx.date).inDays <= 7;
      } else {
        return tx.date.year == now.year && tx.date.month == now.month;
      }
    }).toList();
  }

  double calculateTotal(List<TransactionItem> list) {
    double total = 0;
    for (var item in list) {
      total += item.amount;
    }
    return total;
  }

  void showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizedText[widget.currentLang]!['theme']!),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue),
                title: const Text('Blue Theme'),
                onTap: () { widget.onChangeTheme(Colors.blue); Navigator.pop(context); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green),
                title: const Text('Green Theme'),
                onTap: () { widget.onChangeTheme(Colors.green); Navigator.pop(context); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.purple),
                title: const Text('Purple Theme'),
                onTap: () { widget.onChangeTheme(Colors.purple); Navigator.pop(context); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.red),
                title: const Text('Red Theme'),
                onTap: () { widget.onChangeTheme(Colors.red); Navigator.pop(context); },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var t = localizedText[widget.currentLang]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t['title']!),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: showThemeDialog,
            tooltip: t['theme'],
          ),
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: widget.onLockApp,
            tooltip: 'Lock App',
          ),
          TextButton.icon(
            onPressed: widget.onToggleLanguage,
            icon: const Icon(Icons.language, color: Colors.white),
            label: Text(
              widget.currentLang == 'en' ? 'हिन्दी' : 'English',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: t['day']),
            Tab(text: t['week']),
            Tab(text: t['month']),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTransactionView(getFilteredTransactions(0), t),
          buildTransactionView(getFilteredTransactions(1), t),
          buildTransactionView(getFilteredTransactions(2), t),
        ],
      ),
    );
  }

  Widget buildTransactionView(List<TransactionItem> transactions, Map<String, String> t) {
    double totalSpent = calculateTotal(transactions);

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.currentThemeColor.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.currentThemeColor.shade200),
          ),
          child: Text(
            t['totalSpent']! + totalSpent.toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.currentThemeColor.shade700,
            ),
          ),
        ),
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Text(
                    t['empty']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(Icons.account_balance_wallet, color: widget.currentThemeColor),
                        title: Text(tx.message, maxLines: 3, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          "Amount: Rs. ${tx.amount} | Date: ${tx.date.day}/${tx.date.month}/${tx.date.year}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}