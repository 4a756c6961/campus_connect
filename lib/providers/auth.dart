import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class Auth with ChangeNotifier{
String _token ;
DateTime _expiryDate;
String _userId;

Future<void> signup(String email, String password) async{

<<<<<<< HEAD
const url = 'https://identitytoolkit.googleapis.com/v1/
=======
const url = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key='
>>>>>>> 05c6b44 (Änderungen)
final response = await http.post(url, body:json.encode({
'email':email,
'password':password,
'returnSecureToken':true
}));
print(json.decode(response.body));
    }

}
