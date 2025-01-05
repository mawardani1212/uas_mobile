import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mawar_uas/screens/forgot_password_screen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import './reset_password_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './login_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final String verificationId;
  final int? resendToken;
  final String? expectedOTP;
  final bool isPasswordReset;
  


  OTPVerificationScreen({
    required this.phoneNumber,
    required this.email,
    required this.verificationId,
    this.resendToken,
    this.expectedOTP,
    this.isPasswordReset = false,
  });

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isResending = false;
  Timer? _timer;
  int _countdown = 60;
  final BehaviorSubject<String> _pinSubject = BehaviorSubject<String>();
  StreamController<ErrorAnimationType>? _errorController;
  final FocusNode _otpFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _errorController = StreamController<ErrorAnimationType>.broadcast();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _errorController?.close();
    _pinSubject.close();
    _otpFocus.dispose();
    super.dispose();
  }

  void startTimer() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> resendOTP() async {
    if (_isResending || _countdown > 0) return;

    if (!mounted) return;

    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      // Format untuk Firebase Auth (gunakan +62)
      String verificationPhone = widget.phoneNumber;
      if (widget.phoneNumber.startsWith('0')) {
        verificationPhone = '+62${widget.phoneNumber.substring(1)}';
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: verificationPhone,
        timeout: Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Failed to resend OTP';
            _isResending = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _isResending = false;
          });
          startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New OTP has been sent'),
              backgroundColor: Colors.green,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      print('Error in resendOTP: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to resend OTP';
        _isResending = false;
      });
    }
  }

  void _verifyOTP(String otp) async {
    if (otp.length != 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.expectedOTP != null) {
        if (otp == widget.expectedOTP) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'isPhoneVerified': true,
            });
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          throw 'Invalid OTP';
        }
      } else {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: otp,
        );

        if (widget.isPasswordReset) {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            // MaterialPageRoute(
            //   builder: (context) => ResetPasswordScreen(
            //     phoneNumber: widget.phoneNumber,
            //   ),
            // ),
            MaterialPageRoute(
  builder: (context) => ResetPasswordScreen(
    email: widget.email, 
    
  ),
),

          );
        } else {
          if (!mounted) return;
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      print('Error in _verifyOTP: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
      });
      _errorController?.add(ErrorAnimationType.shake);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verify',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/verifty.png',
                      height: 200,
                    ),
                    SizedBox(height: 40),
                    Text(
                      'Enter OTP',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'An 6 digit OTP has been sent to',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.phoneNumber,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PinCodeTextField(
                        appContext: context,
                        length: 6,
                        focusNode: _otpFocus,
                        obscureText: false,
                        animationType: AnimationType.fade,
                        controller: _otpController,
                        errorAnimationController: _errorController,
                        keyboardType: TextInputType.number,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(8),
                          fieldHeight: 50,
                          fieldWidth: 40,
                          activeFillColor: Colors.white,
                          inactiveFillColor: Colors.white,
                          selectedFillColor: Colors.white,
                          activeColor: Colors.grey[300]!,
                          inactiveColor: Colors.grey[300]!,
                          selectedColor: Colors.black,
                          errorBorderColor: Colors.red,
                        ),
                        animationDuration: Duration(milliseconds: 300),
                        enableActiveFill: true,
                        onCompleted: (value) {
                          _otpFocus.unfocus();
                          _verifyOTP(value);
                        },
                        onChanged: (value) {
                          if (mounted) {
                            _pinSubject.add(value);
                            setState(() {
                              _errorMessage = '';
                            });
                          }
                        },
                        beforeTextPaste: (text) => true,
                        errorAnimationDuration: 500,
                      ),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _verifyOTP(_otpController.text),
                        child: Text(
                          'Verify',
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
                        Text(
                          'Resend OTP',
                          style: TextStyle(color: Colors.grey),
                        ),
                        if (_countdown > 0)
                          Text(
                            ' (00:${_countdown.toString().padLeft(2, '0')})',
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                    TextButton(
                      onPressed:
                          _countdown == 0 && !_isResending ? resendOTP : null,
                      child: Text(
                        'Resend',
                        style: TextStyle(
                          color: _countdown == 0 ? Colors.black : Colors.grey,
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
