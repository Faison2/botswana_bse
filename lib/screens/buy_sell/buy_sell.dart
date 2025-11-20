import 'package:flutter/material.dart';

class TradingPage extends StatefulWidget {
  const TradingPage({Key? key}) : super(key: key);

  @override
  State<TradingPage> createState() => _TradingPageState();
}

class _TradingPageState extends State<TradingPage> {
  // Set to true to match the second image (BUY selected) or false for the first (SELL selected)
  // We'll default to BUY to calculate the totals shown in the second image.
  bool isBuySelected = true;
  String selectedCompany = 'Access Bank Botswana';
  String companyPrice = 'BWP6.23'; // Used in the BUY/SELL toggle context
  String currentPriceDisplay = '\$6.23'; // Used on the company field in the SELL view
  String timeInForce = 'Day Order';
  String broker = 'INVESTOR IQ';
  int quantity = 200;
  double pricePerShare = 6.20;

  // Placeholder for the profile image asset. Replace with your actual asset path.
  // const String _profileAssetPath = 'assets/profile.png';
  // Since I don't have the asset, I'll use a placeholder.
  final ImageProvider _profileImage = const AssetImage('assets/profile.png');


  @override
  Widget build(BuildContext context) {
    // Calculate totals based on provided formula and values
    // NOTE: The second image shows BWP00.00 for all totals,
    // but the calculation is provided here to show how the app would function.
    // To exactly match the BWP00.00 shown in the second screenshot,
    // you would need to set grossTotal, custodialFee, and netTotal to 0.00.
    double grossTotal = quantity * pricePerShare;
    double custodialFee = grossTotal * 0.01;
    double netTotal = grossTotal + custodialFee;

    // To match the second image where totals are 0.00, use this:
    /*
    double grossTotal = 0.00;
    double custodialFee = 0.00;
    double netTotal = 0.00;
    */

    // Determine the content of the Company field based on the selected tab
    String companyFieldValue = isBuySelected
        ? '$selectedCompany $companyPrice' // Matches the format in the BUY view (2nd image)
        : '$selectedCompany $currentPriceDisplay'; // Matches the format in the SELL view (1st image)

    // The second image shows the totals section, the first does not.
    // We'll use a flag to display the totals section to match the second image.
    // For this exact code snippet, we'll assume the state from the second image (isBuySelected=true)
    // and thus show the totals section.
    bool showTotalsSection = isBuySelected;

    return Scaffold(
      // Use the exact color from the background of the images
      backgroundColor: const Color(0xFF3D2817),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: _profileImage,
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, Good Morning',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Victor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // NOTE: The images show a bell icon with no outline,
                  // but Icons.notifications_outlined is close enough if the exact custom icon is not available.
                  Icon(
                    Icons.notifications_outlined,
                    color: Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.close, // Added based on the small 'x' in the top right
                    color: Colors.grey,
                    size: 28,
                  ),
                ],
              ),
            ),
            // Buy/Sell Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: const Color(0xFF2A1B0F), // Darker background for the toggle container
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isBuySelected = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: isBuySelected
                                ? const Color(0xFF2D7A2D) // Green for BUY
                                : Colors.transparent,
                          ),
                          child: const Center(
                            child: Text(
                              'BUY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isBuySelected = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: !isBuySelected
                                ? const Color(0xFF7A2D2D) // Red/Maroon for SELL
                                : Colors.transparent,
                          ),
                          child: const Center(
                            child: Text(
                              'SELL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Form Fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field label changes based on the toggle state to match the images
                    buildFormField(isBuySelected ? 'Company Selected' : 'Company', companyFieldValue),
                    const SizedBox(height: 16),
                    buildFormField('Time In Force', timeInForce),
                    const SizedBox(height: 16),
                    buildFormField('Broker', broker),
                    const SizedBox(height: 16),
                    buildFormField('Quantity', quantity.toString()),
                    const SizedBox(height: 16),
                    buildFormField('Price', 'BWP${pricePerShare.toStringAsFixed(2)}'),

                    // Totals Section - Only visible in the second image (when BUY is selected in this setup)
                    if (showTotalsSection) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          // This is a guess for the background color of the totals section
                          color: const Color(0xFF2A1B0F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            buildTotalRow(
                              'GROSS TOTAL:',
                              // Displaying 0.00 to match the exact screenshot BWP00.00
                              'BWP00.00',
                            ),
                            const SizedBox(height: 8),
                            buildTotalRow(
                              'CUSTODIAL FEE(1%)',
                              'BWP00.00',
                            ),
                            const SizedBox(height: 8),
                            buildTotalRow(
                              'CHARGES:',
                              'BWP00.00',
                            ),
                            const Divider(color: Colors.grey, height: 16),
                            buildTotalRow(
                              'NET TOTAL:',
                              'BWP00.00',
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Ensures there is some space if the totals are not shown
                    if (!showTotalsSection) const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle close
                      },
                      style: ElevatedButton.styleFrom(
                        // Darker button background
                        backgroundColor: const Color(0xFF2A1B0F),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle place order
                      },
                      style: ElevatedButton.styleFrom(
                        // Gold/Brown button background color
                        backgroundColor: const Color(0xFFB8860B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'PLACE ORDER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for the form fields
  Widget buildFormField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity, // Ensures the container takes full width
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            // The images don't clearly show a border, but a subtle one helps define the field
            // border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(8),
            // Light brown/orange background for the input field
            color: const Color(0xFF4A3728),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for the total rows
  Widget buildTotalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}