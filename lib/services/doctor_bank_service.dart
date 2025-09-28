import 'package:http/http.dart' as http;
import 'dart:convert';

class DoctorBankService {
  Future<bool> saveBankDetails({
    required String doctorId,
    required String accountHolder,
    required String bankName,
    required String accountNumber,
    required String branchCode,
  }) async {
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'doctorId': doctorId,
        'accountHolder': accountHolder,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'branchCode': branchCode,
      }),
    );
    return response.statusCode == 200;
  }
  static const String backendUrl = 'http://localhost:3000/doctor/bank-details';

  Future<Map<String, String>?> fetchBankDetails(String doctorId) async {
    final response = await http.get(Uri.parse('$backendUrl/$doctorId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'bankName': data['bankName'],
        'accountHolder': data['accountHolder'],
        'accountNumber': data['accountNumber'],
        'branchCode': data['branchCode'],
      };
    }
    return null;
  }
}
