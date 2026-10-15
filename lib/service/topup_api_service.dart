import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class TopUpIntent {
  const TopUpIntent({required this.reference, required this.expiresAt});

  final String reference;
  final DateTime expiresAt;
}

class TopUpApiService {
  TopUpApiService._();

  static final instance = TopUpApiService._();

  static const _baseUrl = String.fromEnvironment('TOPUP_API_BASE_URL');

  Future<TopUpIntent> createIntent(int amountVnd) async {
    final body = await _request(
      'POST',
      '/topups',
      body: {'amountVnd': amountVnd},
    );
    final reference = body['reference'];
    final expiresAt = body['expiresAt'];
    if (reference is! String || expiresAt is! String) {
      throw const FormatException(
        'Phản hồi tạo yêu cầu nạp tiền không hợp lệ.',
      );
    }
    final parsedExpiry = DateTime.tryParse(expiresAt);
    if (parsedExpiry == null) {
      throw const FormatException('Thời hạn yêu cầu nạp tiền không hợp lệ.');
    }
    return TopUpIntent(reference: reference, expiresAt: parsedExpiry);
  }

  Future<String> getStatus(String reference) async {
    final body = await _request(
      'GET',
      '/topups/${Uri.encodeComponent(reference)}',
    );
    final status = body['status'];
    if (status is! String) {
      throw const FormatException('Phản hồi trạng thái nạp tiền không hợp lệ.');
    }
    if (status != 'pending' && status != 'paid' && status != 'expired') {
      throw FormatException('Trạng thái nạp tiền không được hỗ trợ: $status.');
    }
    return status;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object>? body,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const TopUpConfigurationException();
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Vui lòng đăng nhập trước khi nạp tiền.');
    }

    final token = await user.getIdToken();
    final baseUri = Uri.tryParse(_baseUrl);
    if (baseUri == null ||
        !baseUri.hasScheme ||
        !baseUri.hasAuthority ||
        (baseUri.scheme != 'https' && baseUri.scheme != 'http')) {
      throw const TopUpConfigurationException(
        'TOPUP_API_BASE_URL không phải URL hợp lệ.',
      );
    }
    final uri = baseUri.replace(
      path: '${baseUri.path.replaceFirst(RegExp(r'/+$'), '')}$path',
      query: null,
      fragment: null,
    );
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
    final response = switch (method) {
      'POST' =>
        await http
            .post(
              uri,
              headers: {...headers, 'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15)),
      'GET' =>
        await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15)),
      _ => throw ArgumentError.value(method, 'method', 'Unsupported method'),
    };

    Map<String, dynamic> decoded;
    try {
      final value = jsonDecode(response.body);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }
      decoded = value;
    } on FormatException {
      throw const FormatException(
        'Dịch vụ nạp tiền trả về dữ liệu không hợp lệ.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['error'];
      throw Exception(
        message is String ? message : 'Không thể kết nối dịch vụ nạp tiền.',
      );
    }
    return decoded;
  }
}

class TopUpConfigurationException implements Exception {
  const TopUpConfigurationException([
    this.message =
        'Chưa cấu hình URL Cloudflare Worker cho chức năng nạp tiền.',
  ]);

  final String message;

  @override
  String toString() => message;
}
