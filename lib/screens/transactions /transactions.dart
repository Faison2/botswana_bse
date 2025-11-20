import 'package:flutter/material.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _selectedTab = 0;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _methodController = TextEditingController(text: 'Orange');

  double totalBalance = 300.50;

  final List<Map<String, dynamic>> _allTransactions = [
    {'date': '2023-01-15', 'description': 'Initial funding', 'type': 'Credit', 'amount': 1500.00},
    {'date': '2023-01-15', 'description': 'Withdrawal', 'type': 'Debit', 'amount': 1500.00},
    {'date': '2023-02-20', 'description': 'Bonus Received', 'type': 'Credit', 'amount': 375.00},
    {'date': '2023-02-20', 'description': 'Emergency funds', 'type': 'Debit', 'amount': 375.00},
    {'date': '2023-03-10', 'description': 'Freelance income', 'type': 'Credit', 'amount': 360.00},
    {'date': '2023-03-10', 'description': 'Withdrawal', 'type': 'Debit', 'amount': 360.00},
    {'date': '2023-04-05', 'description': 'Deposit', 'type': 'Credit', 'amount': 1650.00},
    {'date': '2023-04-05', 'description': 'Withdrawal', 'type': 'Debit', 'amount': 1650.00},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _methodController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedTab == 0) {
      return _allTransactions.where((t) => t['type'] == 'Debit').toList();
    } else if (_selectedTab == 1) {
      return _allTransactions.where((t) => t['type'] == 'Credit').toList();
    } else {
      return _allTransactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [

              Color(0xFF4A2F1E),
              Color(0xFF5C3520),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabs(),
              _buildBalanceCard(),
              _buildTransactionForm(),
              _buildActionButtons(),
              const SizedBox(height: 20),
              _buildTransactionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.green.shade700,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi. Good Morning',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                'Victor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildTab('WITHDRAWALS', 0),
          const SizedBox(width: 8),
          _buildTab('DEPOSITS', 1),
          const SizedBox(width: 8),
          _buildTab('TRANSACTIONS', 2),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB8860B) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFB8860B) : Colors.grey.shade700,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB8860B), Color(0xFF8B6914)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Cash Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'BWP ${totalBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 32),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedTab == 1) ...[
            const Text(
              'Select Method',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildTextField(_methodController, 'Orange'),
            const SizedBox(height: 16),
          ],
          Text(
            _selectedTab == 0 ? 'Enter Amount' : _selectedTab == 1 ? 'Description' : 'Filter',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            _selectedTab == 1 ? _descriptionController : _amountController,
            _selectedTab == 0 ? '\$200' : _selectedTab == 1 ? 'Salary Deposit' : 'Search...',
          ),
          if (_selectedTab != 2) ...[
            const SizedBox(height: 16),
            Text(
              _selectedTab == 0 ? 'Description' : 'Enter Amount',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              _selectedTab == 0 ? _descriptionController : _amountController,
              _selectedTab == 0 ? 'Emergency Funds' : '\$200',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6B4423).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_selectedTab == 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _amountController.clear();
                _descriptionController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'CLOSE',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Handle transaction
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_selectedTab == 0 ? 'Withdrawal processed' : 'Deposit processed'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8860B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selectedTab == 0 ? 'WITHDRAW' : 'DEPOSIT',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const Expanded(
                  flex: 3,
                  child: Text('Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                if (_selectedTab == 2)
                  const Expanded(
                    flex: 2,
                    child: Text('Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                const Expanded(
                  flex: 2,
                  child: Text('Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = _filteredTransactions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            transaction['date'],
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            transaction['description'],
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        if (_selectedTab == 2)
                          Expanded(
                            flex: 2,
                            child: Text(
                              transaction['type'],
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'BWP ${transaction['amount'].toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}