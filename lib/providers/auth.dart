import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http_parser/http_parser.dart' as http;

class Auth with ChangeNotifier{
String _token ;
DateTime _expiryDate;
String _userId;


Future<void> signup(String email, String password) async{

const url = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyBftaIJkMor8rYDZ4-fZRLzEW-gkhcEUQ4
final response = await http.post(url, body:json.encode({
'email':email,
'password':password,
'returnSecureToken':true
}));
print(json.decode(response.body));
    }

}
