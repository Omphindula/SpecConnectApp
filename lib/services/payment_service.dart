import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

/// PaymentService
/// - Provides a mock payment implementation for local/demo use.
/// - Includes notes and a stub for Yoco integration. Yoco requires a server-side
///   payment creation step (to protect secret keys). The client should tokenize
///   card details or obtain a checkout key from the server and then confirm payment.

class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? error;

  PaymentResult({required this.success, this.paymentId, this.error});
}

class PaymentService {
  // Singleton
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // Optional server-side endpoint to verify Zapper payments. Configure with:
  // --dart-define=ZAPPER_VERIFY_ENDPOINT=https://your-server/verify_zapper
  // The server endpoint should accept a GET or POST with the payment link or
  // identifier and return a JSON payload {"status":"paid","paymentId":"..."}
  // Read build-time define. If not provided, in debug mode default to local server
  static final String _zapperVerifyEnv = const String.fromEnvironment('ZAPPER_VERIFY_ENDPOINT', defaultValue: '');
  static final String _zapperCreateEnv = const String.fromEnvironment('ZAPPER_CREATE_ENDPOINT', defaultValue: '');
  static String get zapperVerifyEndpoint {
    if (_zapperVerifyEnv.isNotEmpty) return _zapperVerifyEnv;
    // Prefer project config server base if set
    if (serverApiBase.isNotEmpty) return '${serverApiBase.replaceAll(RegExp(r'\/$'), '')}/verify_payment';
    // For convenience during local development, point to the local verification server
    // if no dart-define is given and we're running in debug mode.
    if (kDebugMode) return 'http://localhost:3030/verify_zapper';
    return '';
  }

  static String get zapperCreateEndpoint {
    if (_zapperCreateEnv.isNotEmpty) return _zapperCreateEnv;
    if (serverApiBase.isNotEmpty) return '${serverApiBase.replaceAll(RegExp(r'\/$'), '')}/create_payment';
    if (kDebugMode) return 'http://localhost:3030/create_zapper_payment';
    return '';
  }

  /// Process payment (mock)
  /// Simulates a 2s network call and returns a fake payment id on success.
  Future<PaymentResult> processPaymentMock({required double amount, String currency = 'ZAR'}) async {
    await Future.delayed(const Duration(seconds: 2));
    final id = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult(success: true, paymentId: id);
  }

  /// Yoco integration notes / stub
  /// For production use:
  ///  - Do not put Yoco secret keys in the mobile/web client.
  ///  - Create a server endpoint that calls Yoco to create a payment/charge and returns a token or checkout URL.
  ///  - From the client, obtain that token/checkout URL and complete the flow (redirect or SDK) and confirm payment on the server.
  /// This method is a stub showing where to hook real Yoco calls.
  Future<PaymentResult> processPaymentYoco({required double amount, String currency = 'ZAR', Map<String, dynamic>? metadata}) async {
    // Yoco flow is not implemented in this client. Use a server-side integration
    // for production. For now fall back to mock payment to keep the app working.
    debugPrint('Yoco flow not in use. Using mock payment flow.');
    return await processPaymentMock(amount: amount, currency: currency);
  }

  /// Verify a Zapper payment using an optional server endpoint. The client
  /// cannot and should not verify payments directly without a server because
  /// it would require secret keys. If `ZAPPER_VERIFY_ENDPOINT` is provided
  /// at build time, this method will query that endpoint with the provided
  /// payment link and interpret a successful response.
  Future<PaymentResult> verifyZapperPayment(String paymentLink, {int timeoutSeconds = 8}) async {
    // Quick path for mock links created by createPaymentLinkForAppointment
    if (paymentLink.trim().toLowerCase().startsWith('mock://')) {
      final id = paymentLink.split('://').length > 1 ? paymentLink.split('://')[1] : paymentLink;
      return PaymentResult(success: true, paymentId: id);
    }
    // Strategy:
    // 1) If a server-side ZAPPER_VERIFY_ENDPOINT is configured, use it (recommended).
    // 2) Otherwise attempt to probe the payment link directly and look for JSON
    //    responses or text indicating payment success. This is heuristics-friendly
    //    and may work with many checkout/QR flows that expose a status endpoint.

    // 1) Server-side verification: prefer the backend's /check-payment endpoint
    // If zapperVerifyEndpoint is explicitly provided (dart-define), prefer that.
    if (_zapperVerifyEnv.isNotEmpty) {
      try {
        final uri = Uri.parse(zapperVerifyEndpoint);
        final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'link': paymentLink})).timeout(Duration(seconds: timeoutSeconds));
        if (resp.statusCode != 200) {
          return PaymentResult(success: false, error: 'Verification failed (${resp.statusCode})');
        }

        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final status = (data['status'] as String?) ?? (data['paid'] == true ? 'paid' : null);
        final paymentId = data['paymentId']?.toString();
        if (status != null && status.toLowerCase() == 'paid') {
          return PaymentResult(success: true, paymentId: paymentId);
        }

        return PaymentResult(success: false, error: 'Not paid');
      } catch (e) {
        return PaymentResult(success: false, error: e.toString());
      }
    }

    // If no explicit verify endpoint was provided, try calling our backend's
    // /check-payment/:reference by extracting a reference/appointmentId from the
    // paymentLink (deep-link returnUrl typically includes appointmentId).
    if (serverApiBase.isNotEmpty) {
      try {
        String? ref;
        try {
          final uri = Uri.parse(paymentLink);
          // Common query names used by our server: appointmentId or reference
          ref = uri.queryParameters['appointmentId'] ?? uri.queryParameters['reference'];
          if (ref == null) {
            // If the link path ends with an id, use the last path segment
            final parts = uri.pathSegments;
            if (parts.isNotEmpty) ref = parts.last;
          }
        } catch (_) {
          // paymentLink may be a non-URL id; use it directly
          ref = paymentLink;
        }

        if (ref != null && ref.isNotEmpty) {
          final checkUri = Uri.parse('${serverApiBase.replaceAll(RegExp(r'\/$'), '')}/check-payment/${Uri.encodeComponent(ref)}');
          final resp = await http.get(checkUri).timeout(Duration(seconds: timeoutSeconds));
          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body) as Map<String, dynamic>;
            final found = data['found'] == true;
            final status = (data['status'] as String?) ?? null;
            final paymentId = data['paymentId']?.toString();
            if (found && status != null && status.toLowerCase() == 'paid') {
              return PaymentResult(success: true, paymentId: paymentId);
            }
            return PaymentResult(success: false, error: 'Not paid');
          }
        }
      } catch (_) {
        // fallback to probing below
      }
    }

    // 2) Direct probing: try the payment link and some common suffixes
    final candidates = <String>[paymentLink, paymentLink + '/status', paymentLink + '/verify', paymentLink + '/receipt'];
    for (final url in candidates) {
      try {
        final uri = Uri.parse(url);
        final resp = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));
        if (resp.statusCode != 200) continue;

        final contentType = resp.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final status = (data['status'] as String?) ?? (data['paid'] == true ? 'paid' : null);
          final paymentId = data['paymentId']?.toString();
          if (status != null && status.toLowerCase() == 'paid') {
            return PaymentResult(success: true, paymentId: paymentId);
          }
        } else {
          // Fallback: check response body for keywords
          final body = resp.body.toLowerCase();
          if (body.contains('paid') || body.contains('payment successful') || body.contains('payment confirmed') || body.contains('success')) {
            // No paymentId available when parsing raw HTML
            return PaymentResult(success: true, paymentId: null);
          }
        }
      } catch (_) {
        // ignore and try next
      }
    }

    return PaymentResult(success: false, error: 'Not verified');
  }

  /// Simulate a payout to the doctor's bank account (mock).
  /// For demo purposes this will wait briefly and return a fake payout id.
  Future<PaymentResult> processPayoutMock({required double amount, String currency = 'ZAR'}) async {
    await Future.delayed(const Duration(seconds: 2));
    final id = 'payout_${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult(success: true, paymentId: id);
  }

  /// Create or resolve a payment link for an appointment so a patient can pay.
  ///
  /// Preferred: if a server-side `ZAPPER_CREATE_ENDPOINT` is configured (via
  /// --dart-define) this method will POST appointment/doctor/amount and expect
  /// a JSON response {"paymentLink":"https://..."}.
  ///
  /// Fallback: if `doctorPaymentLink` is provided (doctor already configured a
  /// static payment link/account id), it will be returned.
  ///
  /// Returns `null` when no link could be created or resolved.
  Future<String?> createPaymentLinkForAppointment({String? doctorPaymentLink, String? doctorId, required String appointmentId, required double amount}) async {
    // 1) If server-side create endpoint is configured, call it
    if (zapperCreateEndpoint.isNotEmpty) {
      try {
        final uri = Uri.parse(zapperCreateEndpoint);
        // Build an optional returnUrl so PSP can redirect back to the app after
        // payment. The server may use/propagate this value. Keep the URL simple
        // and include the appointment id so the client can auto-verify.
        final returnUrl = '$appDeepLinkScheme://payment_return?appointmentId=$appointmentId';
        final body = jsonEncode({
          'doctorId': doctorId,
          'appointmentId': appointmentId,
          'amount': amount,
          'returnUrl': returnUrl,
        });
        final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final link = data['paymentLink'] as String?;
          if (link != null && link.isNotEmpty) return link;
        }
      } catch (e) {
        // ignore and fallback to doctorPaymentLink
      }
    }

    // 2) Fallback to doctor's configured static payment link
    if (doctorPaymentLink != null && doctorPaymentLink.trim().isNotEmpty) {
      try {
        // Best-effort: append returnUrl so some PSP pages may redirect back to the app.
        final returnUrl = '$appDeepLinkScheme://payment_return?appointmentId=$appointmentId';
        final uri = Uri.parse(doctorPaymentLink.trim());
        final params = Map<String, String>.from(uri.queryParameters);
        // Do not overwrite an explicit returnUrl if already present
        params.putIfAbsent('returnUrl', () => returnUrl);
        final newUri = uri.replace(queryParameters: params);
        return newUri.toString();
      } catch (_) {
        return doctorPaymentLink.trim();
      }
    }

    // 3) If we're running locally (no server, no doctor link), create a mock
    // payment link so the UI can simulate the flow end-to-end without a backend.
    // The PaymentSheet will detect mock:// links and the verifier below will
    // immediately return success for them.
    if (kDebugMode) {
      final id = 'mock_${DateTime.now().millisecondsSinceEpoch}';
      return 'mock://$id';
    }

    return null;
  }
}
