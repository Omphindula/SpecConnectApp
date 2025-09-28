import 'package:flutter/material.dart';
import '../services/yoco_service.dart';
import '../services/doctor_bank_service.dart';

class PatientPaymentPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  const PatientPaymentPage({super.key, required this.doctorId, required this.doctorName});

  @override
  State<PatientPaymentPage> createState() => _PatientPaymentPageState();
}

class _PatientPaymentPageState extends State<PatientPaymentPage> {
  final _amountController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _isLoading = false;
  String? _paymentStatus;
  Map<String, String>? doctorBankDetails;

  Future<void> _pay() async {
    setState(() { _isLoading = true; _paymentStatus = null; });
    // Fetch doctor banking details from backend
    doctorBankDetails = await DoctorBankService().fetchBankDetails(widget.doctorId);
    if (doctorBankDetails == null) {
      setState(() {
        _isLoading = false;
        _paymentStatus = 'Could not fetch doctor banking details.';
      });
      return;
    }
    // Simulate Yoco card tokenization (replace with real Yoco widget integration)
    String cardNumber = _cardNumberController.text.trim();
    String expiry = _expiryController.text.trim();
    String cvc = _cvcController.text.trim();
    if (cardNumber.isEmpty || expiry.isEmpty || cvc.isEmpty) {
      setState(() {
        _isLoading = false;
        _paymentStatus = 'Please enter all card details.';
      });
      return;
    }
    // TODO: Integrate Yoco card widget for real token
    String cardToken = 'test_card_token';
    int amount = int.tryParse(_amountController.text) ?? 0;
    bool success = await YocoService().processPayment(
      cardToken: cardToken,
      amount: amount,
      currency: 'ZAR',
      doctorBankDetails: doctorBankDetails!,
    );
    setState(() {
      _isLoading = false;
      _paymentStatus = success ? 'Payment successful!' : 'Payment failed.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pay Dr. ${widget.doctorName}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter amount to pay:'),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'Amount (ZAR)'),
              ),
              SizedBox(height: 20),
              Text('Card Details:'),
              TextField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'Card Number'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _expiryController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(hintText: 'Expiry (MM/YY)'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _cvcController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'CVC'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _pay,
                child: _isLoading ? CircularProgressIndicator() : Text('Pay with Card'),
              ),
              if (_paymentStatus != null) ...[
                SizedBox(height: 20),
                Text(_paymentStatus!, style: TextStyle(color: Colors.green)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
