import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mawar_uas/home.dart';
import 'package:mawar_uas/screens/reset_password_screen.dart';
import './register_screen.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import './forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String _selectedCountryCode = '+62';
  bool _isValidPhone = false;

  final List<String> _countryCodes = [
    '+62',
    '+60',
    '+65',
    '+66',
    '+84',
    '+63',
  ];

  void _validatePhone(String value) {
    // Validasi sederhana: minimal 10 digit, maksimal 13 digit
    setState(() {
      _isValidPhone = value.length >= 10 &&
          value.length <= 13 &&
          RegExp(r'^[0-9]+$').hasMatch(value);
    });
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in ke Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      try {
        // Cek apakah user sudah ada di Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Jika belum ada, buat dokumen baru
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName,
            'photoURL': userCredential.user!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'provider': 'google',
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } else {
          // Update lastLogin jika user sudah ada
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }

        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } catch (firestoreError) {
        print('Error with Firestore: $firestoreError');
        // Tetap lanjutkan ke home screen meskipun ada error Firestore
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      print('Error in Google Sign In: $e');
      String errorMessage = 'Google Sign In gagal';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            errorMessage = 'Akun ini sudah terdaftar dengan metode login lain';
            break;
          case 'invalid-credential':
            errorMessage = 'Kredensial tidak valid';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Login dengan Google tidak diizinkan';
            break;
          case 'user-disabled':
            errorMessage = 'Akun ini telah dinonaktifkan';
            break;
          case 'user-not-found':
            errorMessage = 'Akun tidak ditemukan';
            break;
          default:
            errorMessage = 'Error: ${e.message}';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _login() async {
    if (!_isValidPhone || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Mohon isi nomor telepon dan password dengan benar')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Format nomor telepon untuk query Firestore (format 08xx)
      String formattedPhone = _phoneController.text;
      if (!formattedPhone.startsWith('0')) {
        formattedPhone = '0${formattedPhone}';
      }

      // Cari user berdasarkan nomor telepon
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'Akun tidak ditemukan. Silakan register terlebih dahulu.';
      }

      final userData = querySnapshot.docs.first.data();
      final hashedPassword = hashPassword(_passwordController.text);

      // Verifikasi password
      if (userData['password'] != hashedPassword) {
        throw 'Password salah';
      }

      // Login dengan email (karena Firebase Auth menggunakan email)
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userData['email'],
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        // Login berhasil, navigasi ke home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan';
      if (e.code == 'user-not-found') {
        message = 'Akun tidak ditemukan';
      } else if (e.code == 'wrong-password') {
        message = 'Password salah';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,

        title: Text(
          'Login',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40),
                    Text(
                      'Enter your mobile number',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              underline: SizedBox(),
                              items: _countryCodes.map((code) {
                                return DropdownMenuItem<String>(
                                  value: code,
                                  child: Text(code),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCountryCode = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '81234567890',
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12),
                                // Tambahkan suffix icon untuk tanda centang
                                suffixIcon: _isValidPhone
                                    ? Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      )
                                    : null,
                              ),
                              keyboardType: TextInputType.phone,
                              onChanged: (value) {
                                _validatePhone(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Enter your password',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() => _showPassword = !_showPassword);
                            },
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // builder: (context) => ResetPasswordScreen(email: '',),
                              builder: (context) => ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'forgot password?',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Center(child: Text('or')),
                    SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: Image.network(
                        'https://www.google.com/favicon.ico',
                        height: 24,
                      ),
                      label: Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Implement Apple sign in
                      },
                      icon: Icon(
                        Icons.apple,
                        color: Colors.black,
                      ),
                      label: Text(
                        'Continue with Apple',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(child: Text("Or")),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Continue as Guest',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
