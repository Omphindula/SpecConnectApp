class CurrencyFormatter {
  static const String currencySymbol = 'R';
  static const String currencyName = 'South African Rand';
  static const String currencyCode = 'ZAR';

  /// Format a double amount as South African Rands
  /// Example: formatAmount(1500.50) returns "R1,500.50"
  static String formatAmount(double amount, {bool showDecimals = true}) {
    if (showDecimals) {
      return '$currencySymbol${_formatNumber(amount)}';
    } else {
      return '$currencySymbol${_formatNumber(amount.round())}';
    }
  }

  /// Format consultation fee for display
  /// Example: formatConsultationFee(600.0) returns "R600"
  static String formatConsultationFee(double fee) {
    return formatAmount(fee, showDecimals: false);
  }

  /// Format a price with currency symbol
  /// Example: formatPrice(250.75) returns "R250.75"
  static String formatPrice(double price) {
    return formatAmount(price, showDecimals: true);
  }

  /// Internal method to format numbers with thousands separators
  static String _formatNumber(num number) {
    final parts = number.toString().split('.');
    final wholePart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';
    
    // Add thousands separators
    String formatted = '';
    for (int i = 0; i < wholePart.length; i++) {
      if (i > 0 && (wholePart.length - i) % 3 == 0) {
        formatted += ',';
      }
      formatted += wholePart[i];
    }
    
    if (decimalPart.isNotEmpty) {
      formatted += '.$decimalPart';
    }
    
    return formatted;
  }

  /// Parse a currency string back to double
  /// Example: parseAmount("R1,500.50") returns 1500.50
  static double parseAmount(String currencyString) {
    try {
      // Remove currency symbol and spaces
      String cleanString = currencyString
          .replaceAll(currencySymbol, '')
          .replaceAll(',', '')
          .replaceAll(' ', '');
      
      return double.parse(cleanString);
    } catch (e) {
      return 0.0;
    }
  }

  /// Get currency info for display
  static Map<String, String> getCurrencyInfo() {
    return {
      'symbol': currencySymbol,
      'name': currencyName,
      'code': currencyCode,
    };
  }
}