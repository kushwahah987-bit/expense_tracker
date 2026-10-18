Aapke kehne par humne app mein **Year (साल)** ka tab bhi add kar diya hai!

Ab aap app mein **Day (दिन), Week (हफ्ता), Month (महीना), aur Year (साल)** — in charo intervals ke hisab se apna kul kharcha aur saari transactions aasani se dekh sakte hain.

Yahan aapke liye **complete updated `lib/main.dart` code** hai:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  bool isLoggedIn = false;
  bool isLocked = true;
  ThemeMode themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    loadThemeSetting();
  }

  void checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? phone = prefs.getString('user_mobile');
    setState(() {
      isLoggedIn = phone != null && phone.isNotEmpty;
    });
  }

  void loadThemeSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTheme = prefs.getString('themeMode');
    setState(() {
      if (savedTheme == 'dark') themeMode = ThemeMode.dark;
      else if (savedTheme == 'light') themeMode = ThemeMode.light;
      else themeMode = ThemeMode.system;
    });
  }

  void toggleTheme(ThemeMode mode) async {
    setState(() {
      themeMode = mode;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', mode == ThemeMode.dark ? 'dark' : (mode == ThemeMode.light ? 'light' : 'system'));
  }

  void toggleLanguage() {
    setState(() {
      currentLang = currentLang == 'en' ? 'hi' : 'en';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UPI Expense Tracker',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: !isLoggedIn
          ? LoginScreen(
              onLoginSuccess: () => setState(() => isLoggedIn = true),
              currentLang: currentLang,
              onToggleLang: toggleLanguage,
            )
          : isLocked
              ? PinLockScreen(
                  onUnlock: () => setState(() => isLocked = false),
                  currentLang: currentLang,
                )
              : HomeScreen(
                  currentLang: currentLang,
                  onToggleLanguage: toggleLanguage,
                  onLockApp: () => setState(() => isLocked = true),
                  currentThemeMode: themeMode,
                  onChangeTheme: toggleTheme,
                  onLogout: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    prefs.remove('user_mobile');
                    setState(() {
                      isLoggedIn = false;
                    });
                  },
                ),
    );
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final String currentLang;
  final VoidCallback onToggleLang;

  const LoginScreen({Key? key, required this.onLoginSuccess, required this.currentLang, required this.onToggleLang}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  void handleLogin() async {
    String phone = phoneController.text.trim();
    if (phone.length == 10) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('user_mobile', phone);
      widget.onLoginSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.currentLang == 'en' ? 'Enter a valid 10-digit mobile number' : 'कृपया 10 अंकों का वैध मोबाइल नंबर दर्ज करें')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEn = widget.currentLang == 'en';
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton.icon(
            onPressed: widget.onToggleLang,
            icon: const Icon(Icons.language),
            label: Text(isEn ? 'हिन्दी' : 'English'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(
              isEn ? 'UPI Expense Tracker Login' : 'यूपीआई खर्च ट्रैकर लॉगिन',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              isEn ? 'Enter mobile number to view SMS expenses' : 'एसएमएस खर्च देखने के लिए मोबाइल नंबर दर्ज करें',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone),
                labelText: isEn ? 'Mobile Number' : 'मोबाइल नंबर',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: handleLogin,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                child: Text(isEn ? 'Continue' : 'आगे बढ़ें', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PIN LOCK SCREEN ---
class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final String currentLang;

  const PinLockScreen({Key? key, required this.onUnlock, required this.currentLang}) : super(key: key);

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String enteredPin = "";
  String savedPin = "1234";

  @override
  void initState() {
    super.initState();
    loadSavedPin();
  }

  void loadSavedPin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedPin = prefs.getString('user_pin') ?? "1234";
    });
  }

  void _onDigitPress(String digit) {
    if (enteredPin.length < 4) {
      setState(() {
        enteredPin += digit;
      });
      if (enteredPin.length == 4) {
        if (enteredPin == savedPin) {
          widget.onUnlock();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.currentLang == 'en' ? 'Incorrect PIN!' : 'गलत पिन!')),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 60, color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(
              widget.currentLang == 'en' ? 'Enter 4-Digit PIN (Default: 1234)' : '4-अंकों का पिन दर्ज करें (Default: 1234)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    color: index < enteredPin.length ? Colors.blueAccent : Colors.grey.shade400,
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

// --- DATA MODEL ---
class TransactionItem {
  final String message;
  final double amount;
  final String dateStr;

  TransactionItem({required this.message, required this.amount, required this.dateStr});

  Map<String, dynamic> toJson() => {'message': message, 'amount': amount, 'dateStr': dateStr};

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      message: json['message'],
      amount: json['amount'],
      dateStr: json['dateStr'],
    );
  }
}

// --- MAIN HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  final String currentLang;
  final VoidCallback onToggleLanguage;
  final VoidCallback onLockApp;
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onChangeTheme;
  final VoidCallback onLogout;

  const HomeScreen({
    Key? key,
    required this.currentLang,
    required this.onToggleLanguage,
    required this.onLockApp,
    required this.currentThemeMode,
    required this.onChangeTheme,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final SmsQuery _smsQuery = SmsQuery();
  List<TransactionItem> allTransactions = [];
  late TabController _tabController;
  bool isLoading = false;

  final Map<String, Map<String, String>> localizedText = {
    'en': {
      'title': 'UPI Expense Tracker',
      'day': 'Day',
      'week': 'Week',
      'month': 'Month',
      'year': 'Year',
      'empty': 'No UPI transactions found. Pull down or tap Refresh.',
      'totalSpent': 'Total Spent: Rs. ',
      'settings': 'Settings',
      'changePin': 'Change PIN',
      'themeTitle': 'Theme Mode',
      'logout': 'Logout',
      'refresh': 'Sync SMS',
    },
    'hi': {
      'title': 'यूपीआई खर्च ट्रैकर',
      'day': 'दिन',
      'week': 'हफ्ता',
      'month': 'महीना',
      'year': 'साल',
      'empty': 'कोई यूपीआई लेन-देन नहीं मिला। Sync SMS पर टैप करें।',
      'totalSpent': 'कुल खर्चा: रु. ',
      'settings': 'सेटिंग्स',
      'changePin': 'पिन बदलें',
      'themeTitle': 'थीम मोड',
      'logout': 'लॉग आउट',
      'refresh': 'एसएमएस सिंक करें',
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    loadSavedTransactions();
    fetchAndParseSms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchAndParseSms();
    }
  }

  void loadSavedTransactions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? dataString = prefs.getString('transactions_list');
    if (dataString != null) {
      List decoded = jsonDecode(dataString);
      setState(() {
        allTransactions = decoded.map((item) => TransactionItem.fromJson(item)).toList();
      });
    }
  }

  void saveTransactionsToDisk() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(allTransactions.map((tx) => tx.toJson()).toList());
    prefs.setString('transactions_list', encoded);
  }

  Future<void> fetchAndParseSms() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    var status = await Permission.sms.request();
    if (status.isGranted) {
      List<SmsMessage> messages = await _smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
      );

      bool hasNew = false;
      for (var msg in messages) {
        String body = msg.body ?? "";
        String lower = body.toLowerCase();
        
        if (lower.contains('debited') || 
            lower.contains('spent') || 
            lower.contains('paid') || 
            lower.contains('sent') ||
            lower.contains('transferred') ||
            lower.contains('dr') ||
            lower.contains('deducted') ||
            lower.contains('purchase') ||
            lower.contains('txn')) {
          double amt = extractAmount(body);
          if (amt > 0) {
            String msgDate = msg.date != null ? msg.date!.toIso8601String() : DateTime.now().toIso8601String();
            bool exists = allTransactions.any((tx) => tx.message == body);
            if (!exists) {
              allTransactions.add(TransactionItem(message: body, amount: amt, dateStr: msgDate));
              hasNew = true;
            }
          }
        }
      }

      if (hasNew && mounted) {
        allTransactions.sort((a, b) => DateTime.parse(b.dateStr).compareTo(DateTime.parse(a.dateStr)));
        saveTransactionsToDisk();
      }
    }
    if (mounted) {
      setState(() => isLoading = false);
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

  void showChangePinDialog() {
    TextEditingController oldPinController = TextEditingController();
    TextEditingController newPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.currentLang == 'en' ? 'Change PIN' : 'पिन बदलें'),
          content: Column(
            mainAxisSize: MinAxisSize.min,
            children: [
              TextField(controller: oldPinController, decoration: const InputDecoration(hintText: 'Old PIN'), obscureText: true),
              TextField(controller: newPinController, decoration: const InputDecoration(hintText: 'New 4-Digit PIN'), obscureText: true, maxLength: 4),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String currentSavedPin = prefs.getString('user_pin') ?? '1234';
                if (oldPinController.text == currentSavedPin && newPinController.text.length == 4) {
                  prefs.setString('user_pin', newPinController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Changed Successfully!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid PIN details!')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void showSettingsDialog() {
    var t = localizedText[widget.currentLang]!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t['settings']!),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: Text(t['changePin']!),
                onTap: () {
                  Navigator.pop(context);
                  showChangePinDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(t['logout']!, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onLogout();
                },
              ),
              const Divider(),
              Text(t['themeTitle']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: widget.currentThemeMode,
                onChanged: (val) { widget.onChangeTheme(val!); Navigator.pop(context); },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light Mode'),
                value: ThemeMode.light,
                groupValue: widget.currentThemeMode,
                onChanged: (val) { widget.onChangeTheme(val!); Navigator.pop(context); },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark Mode'),
                value: ThemeMode.dark,
                groupValue: widget.currentThemeMode,
                onChanged: (val) { widget.onChangeTheme(val!); Navigator.pop(context); },
              ),
            ],
          ),
        );
      },
    );
  }

  List<TransactionItem> getFilteredTransactions(int tabIndex) {
    DateTime now = DateTime.now();
    return allTransactions.where((tx) {
      DateTime txDate = DateTime.parse(tx.dateStr);
      if (tabIndex == 0) {
        // Day Filter
        return txDate.year == now.year && txDate.month == now.month && txDate.day == now.day;
      } else if (tabIndex == 1) {
        // Week Filter
        return now.difference(txDate).inDays <= 7;
      } else if (tabIndex == 2) {
        // Month Filter
        return txDate.year == now.year && txDate.month == now.month;
      } else {
        // Year Filter
        return txDate.year == now.year;
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

  @override
  Widget build(BuildContext context) {
    var t = localizedText[widget.currentLang]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t['title']!),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAndParseSms,
            tooltip: t['refresh'],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: widget.onLockApp,
          ),
          TextButton.icon(
            onPressed: widget.onToggleLanguage,
            icon: const Icon(Icons.language),
            label: Text(widget.currentLang == 'en' ? 'हिन्दी' : 'English'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t['day']),
            Tab(text: t['week']),
            Tab(text: t['month']),
            Tab(text: t['year']),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                buildView(getFilteredTransactions(0), t),
                buildView(getFilteredTransactions(1), t),
                buildView(getFilteredTransactions(2), t),
                buildView(getFilteredTransactions(3), t),
              ],
            ),
    );
  }

  Widget buildView(List<TransactionItem> txList, Map<String, String> t) {
    double total = calculateTotal(txList);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            t['totalSpent']! + total.toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: txList.isEmpty
              ? Center(child: Text(t['empty']!, style: const TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: txList.length,
                  itemBuilder: (context, index) {
                    final tx = txList[index];
                    DateTime dt = DateTime.parse(tx.dateStr);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                        title: Text(tx.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text("Rs. ${tx.amount} | Date: ${dt.day}/${dt.month}/${dt.year}"),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

```