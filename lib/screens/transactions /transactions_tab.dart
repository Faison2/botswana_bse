import 'package:flutter/material.dart';

class TransactionsTab extends StatelessWidget {
  final bool isDark;

  const TransactionsTab({Key? key, required this.isDark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  children: [
                    _buildTableHeader('Date'),
                    _buildTableHeader('Description'),
                    _buildTableHeader('Type'),
                    _buildTableHeader('Amount'),
                  ],
                ),
                _buildTableRow('2023-01-15', 'Initial funding', 'Credit', 'BWP 1,500.00'),
                _buildTableRow('2023-02-20', 'Bonus Received', 'Credit', 'BWP 375.00'),
                _buildTableRow('2023-03-10', 'Freelance income', 'Credit', 'BWP 360.00'),
                _buildTableRow('2023-04-05', 'Deposit', 'Credit', 'BWP 1,650.00'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  TableRow _buildTableRow(String date, String description, String type, String amount) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            date,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            description,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            type,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            amount,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}