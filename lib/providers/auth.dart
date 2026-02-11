import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Auth with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;

  bool get isLoggedIn => token != null;

  String? get token {
    if (_token == null || _expiryDate == null) return null;
    if (_expiryDate!.isBefore(DateTime.now())) return null;
    return _token;
  }

  String? get userId => _userId;

  Future<void> signup(String email, String password) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=DEIN_KEY',
    );

    final response = await http.post(
      url,
      body: json.encode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final responseData = json.decode(response.body) as Map<String, dynamic>;
    if (responseData['error'] != null) {
      throw Exception(responseData['error']['message']);
    }

    _token = responseData['idToken']?.toString();
    _userId = responseData['localId']?.toString();

    final expiresIn = int.tryParse(responseData['expiresIn'].toString()) ?? 0;
    _expiryDate = DateTime.now().add(Duration(seconds: expiresIn));

    notifyListeners();
  }
}
