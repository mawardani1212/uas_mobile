import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:mawar_uas/home.dart';
import 'dart:convert';
import './login_screen.dart';
import './otp_verification_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

// import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
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

  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _validatePhone(String value) {
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

  Future<void> _signInWithApple() async {
    try {
      // final credential = await SignInWithApple.getAppleIDCredential(
      //   scopes: [
      //     AppleIDAuthorizationScopes.email,
      //     AppleIDAuthorizationScopes.fullName,
      //   ],
      // );

      // final oauthCredential = OAuthProvider("apple.com").credential(
      //   idToken: credential.identityToken,
      //   accessToken: credential.authorizationCode,
      // );

      // await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      // Navigate to home screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple Sign In failed: $e')),
      );
    }
  }

  // Fungsi untuk format nomor telepon
  String _formatPhoneNumber(String phone, String countryCode) {
    // Hapus semua karakter non-digit
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Jika dimulai dengan 0, gunakan langsung
    if (cleanPhone.startsWith('0')) {
      return cleanPhone; // Kembalikan format 08xx
    }

    // Jika tidak dimulai dengan 0, tambahkan 0
    return '0${cleanPhone}';
  }

  void _register() async {
    if (!_isValidPhone ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon isi semua field dengan benar')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Format nomor telepon
      String formattedPhone = _phoneController.text;
      if (!formattedPhone.startsWith('0')) {
        formattedPhone = '0${formattedPhone}';
      }

      String verificationPhone = '+62${formattedPhone.substring(1)}';

      // Cek apakah email sudah terdaftar di Firestore
      final emailSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (emailSnapshot.docs.isNotEmpty) {
        throw 'Email sudah terdaftar. Silakan gunakan email lain.';
      }

      // Cek apakah nomor telepon sudah terdaftar
      final phoneSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .get();

      if (phoneSnapshot.docs.isNotEmpty) {
        throw 'Nomor telepon sudah terdaftar. Silakan gunakan nomor lain.';
      }

      // Daftar nomor test
      Map<String, String> testNumbers = {
        '+6281356489030': '111111',
        // '+6281356489030': '654321',
      };

      try {
        // Buat user di Firebase Auth
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Simpan data di Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'phoneNumber': formattedPhone,
          'email': _emailController.text.trim(),
          'password': hashPassword(_passwordController.text),
          'createdAt': FieldValue.serverTimestamp(),
          'isPhoneVerified': false,
        });

        print('Data berhasil disimpan di Firestore');

        // Jika nomor test, arahkan ke OTP
        if (testNumbers.containsKey(verificationPhone)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                phoneNumber: verificationPhone,
                verificationId: 'test-verification-id',
                resendToken: null,
                expectedOTP: testNumbers[verificationPhone], email: '',
              ),
            ),
          );
        } else {
          // Untuk nomor non-test
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registrasi berhasil! Silakan login.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }

        // Sign out setelah registrasi
        await FirebaseAuth.instance.signOut();
      } catch (authError) {
        print('Error in Firebase Auth: $authError');
        if (authError is FirebaseAuthException) {
          if (authError.code == 'email-already-in-use') {
            throw 'Email sudah terdaftar. Silakan gunakan email lain.';
          }
        }
        throw authError.toString();
      }
    } catch (e) {
      print('Error during registration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeRegistration(
    PhoneAuthCredential? phoneCredential,
    String formattedPhone,
  ) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (phoneCredential != null) {
        await userCredential.user?.linkWithCredential(phoneCredential);
      }

      // Save user data to Firestore dengan format 08xx
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'phoneNumber': formattedPhone, // Simpan dalam format 08xx
        'email': _emailController.text.trim(),
        'password': hashPassword(_passwordController.text),
        'createdAt': FieldValue.serverTimestamp(),
        'isPhoneVerified': true,
      });

      // Sign out after registration
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi Berhasil Silahkan Login.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                              focusNode: _phoneFocus,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '81234567890',
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12),
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
                              onEditingComplete: () {
                                _phoneFocus.unfocus();
                                FocusScope.of(context)
                                    .requestFocus(_emailFocus);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Enter your email',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          hintText: 'abc123@gmail.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onEditingComplete: () {
                          _emailFocus.unfocus();
                          FocusScope.of(context).requestFocus(_passwordFocus);
                        },
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
                        focusNode: _passwordFocus,
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
                        onEditingComplete: () {
                          _passwordFocus.unfocus();
                          FocusScope.of(context)
                              .requestFocus(_confirmPasswordFocus);
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Re-Enter your password',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        obscureText: !_showConfirmPassword,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() =>
                                  _showConfirmPassword = !_showConfirmPassword);
                            },
                          ),
                        ),
                        onEditingComplete: () {
                          _confirmPasswordFocus.unfocus();
                          _register(); // Langsung register saat user selesai input
                        },
                      ),
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // onPressed: () {
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => OTPVerificationScreen(
                        //         verificationId: '123456',
                        //         phoneNumber: '082116196438',
                        //       ),
                        //     ),
                        //   );
                        // },
                        onPressed: _isLoading ? null : _register,
                        child: Text(
                          'Sign Up',
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
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Center(child: Text('or')),
                    SizedBox(height: 16),
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
                      onPressed: _signInWithApple,
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
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
