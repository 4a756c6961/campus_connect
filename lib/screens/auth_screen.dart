import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthMode { Signup, Login }

class AuthScreen extends StatelessWidget {
  static const routeName = '/auth';

  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromRGBO(215, 117, 255, 1).withOpacity(0.5),
                  const Color.fromRGBO(255, 188, 117, 1).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0, 1],
              ),
            ),
          ),
          SingleChildScrollView(
            child: SizedBox(
              height: deviceSize.height,
              width: deviceSize.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20.0),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 94.0,
                      ),
                      transform: Matrix4.rotationZ(-8 * pi / 180)
                        ..translate(-10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.deepOrange.shade900,
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Campus Connect',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontFamily: 'Anton',
                          fontSize: 50,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: deviceSize.width > 600 ? 2 : 1,
                    child: const AuthCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCard extends StatefulWidget {
  const AuthCard({super.key});

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AuthMode _authMode = AuthMode.Login;

  final Map<String, String> _authData = {
    'email': '',
    'password': '',
    'firstname': '',
    'lastname': '',
  };

  bool _isLoading = false;
  final TextEditingController _passwordController = TextEditingController();
  void _switchAuthMode() {
    setState(() {
      _authMode =
          _authMode == AuthMode.Login ? AuthMode.Signup : AuthMode.Login;
    });
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final auth = FirebaseAuth.instance;

      if (_authMode == AuthMode.Login) {
        await auth.signInWithEmailAndPassword(
          email: _authData['email']!,
          password: _authData['password']!,
        );
      } else {
        await auth.createUserWithEmailAndPassword(
          email: _authData['email']!,
          password: _authData['password']!,
        );

        // Speichere vollständigen Namen im Firebase User-Profil
        await auth.currentUser!.updateDisplayName(
          '${_authData['firstname']} ${_authData['lastname']}',
        );
      }

      // Optional: Weiterleitung nach Login
      // Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      var message = 'Anmeldung fehlgeschlagen.';
      if (e.message != null) {
        message = e.message!;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ein unerwarteter Fehler ist aufgetreten.'),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 8.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
        height: _authMode == AuthMode.Signup ? 320 : 260,
        constraints: BoxConstraints(
          minHeight: _authMode == AuthMode.Signup ? 320 : 260,
        ),
        width: deviceSize.width * 0.75,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'E-Mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'E-Mail ist ungültig!';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _authData['email'] = value!;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Passwort'),
                  obscureText: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.length < 5) {
                      return 'Passwort ist zu kurz!';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _authData['password'] = value!;
                  },
                ),
                if (_authMode == AuthMode.Signup)
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Passwort bestätigen',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwörter stimmen nicht überein!';
                      }
                      return null;
                    },
                  ),

                if (_authMode == AuthMode.Signup)
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Vorname'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitte gib deinen Vornamen ein';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _authData['firstname'] = value!;
                    },
                  ),
                if (_authMode == AuthMode.Signup)
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nachname'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitte gib deinen Nachnamen ein';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _authData['lastname'] = value!;
                    },
                  ),

                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor:
                          Theme.of(context).primaryTextTheme.labelLarge?.color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30.0,
                        vertical: 8.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _authMode == AuthMode.Login ? 'LOGIN' : 'SIGN UP',
                    ),
                  ),
                TextButton(
                  onPressed: _switchAuthMode,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30.0,
                      vertical: 4,
                    ),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text(
                    '${_authMode == AuthMode.Login ? 'SIGNUP' : 'LOGIN'} INSTEAD',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
