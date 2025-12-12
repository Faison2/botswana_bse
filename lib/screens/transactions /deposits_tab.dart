import 'package:flutter/material.dart';

class DepositsTab extends StatefulWidget {
  final bool isDark;

  const DepositsTab({Key? key, required this.isDark}) : super(key: key);

  @override
  State<DepositsTab> createState() => _DepositsTabState();
}

class _DepositsTabState extends State<DepositsTab> {
  final TextEditingController _amountController = TextEditingController(text: '\$200');
  final TextEditingController _descriptionController = TextEditingController(text: 'Salary Deposit');
  final TextEditingController _methodController = TextEditingController(text: 'Orange');

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _methodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Method',
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _methodController,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontSize: 20,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Description',
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontSize: 20,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Enter Amount',
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontSize: 20,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDark ? Colors.black45 : Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'CLOSE',
                      style: TextStyle(
                        color: widget.isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'DEPOSIT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildTransactionTable([
              {'date': '2023-01-15', 'description': 'Initial funding', 'amount': 'BWP 1,500.00'},
              {'date': '2023-02-20', 'description': 'Bonus Received', 'amount': 'BWP 375.00'},
              {'date': '2023-03-10', 'description': 'Freelance income', 'amount': 'BWP 360.00'},
              {'date': '2023-04-05', 'description': 'Deposit', 'amount': 'BWP 1,650.00'},
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTable(List<Map<String, String>> transactions) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          children: [
            _buildTableHeader('Date'),
            _buildTableHeader('Description'),
            _buildTableHeader('Amount'),
          ],
        ),
        for (var transaction in transactions)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  transaction['date']!,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  transaction['description']!,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  transaction['amount']!,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}