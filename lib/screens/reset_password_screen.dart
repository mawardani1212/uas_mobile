// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:crypto/crypto.dart';
// import 'dart:convert';
// import './login_screen.dart';

// class ResetPasswordScreen extends StatefulWidget {
//   final String phoneNumber;

//   ResetPasswordScreen({required this.phoneNumber});

//   @override
//   _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
// }

// class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
//   final _newPasswordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   bool _isLoading = false;
//   bool _showNewPassword = false;
//   bool _showConfirmPassword = false;

//   String hashPassword(String password) {
//     final bytes = utf8.encode(password);
//     final hash = sha256.convert(bytes);
//     return hash.toString();
//   }

//   void _resetPassword() async {
//     if (_newPasswordController.text.isEmpty ||
//         _confirmPasswordController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please fill all fields')),
//       );
//       return;
//     }

//     if (_newPasswordController.text != _confirmPasswordController.text) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Passwords do not match')),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       // Find user by phone number
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .where('phoneNumber', isEqualTo: widget.phoneNumber)
//           .limit(1)
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         throw 'User not found';
//       }

//       final userDoc = querySnapshot.docs.first;
//       final userData = userDoc.data();

//       // Update password in Firebase Auth
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await user.updatePassword(_newPasswordController.text);

//         // Update password hash in Firestore
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(userDoc.id)
//             .update({
//           'password': hashPassword(_newPasswordController.text),
//         });

//         // Sign out after password reset
//         await FirebaseAuth.instance.signOut();

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Password reset successful! Please login again.'),
//             backgroundColor: Colors.green,
//           ),
//         );

//         // Navigate to login screen
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => LoginScreen()),
//           (route) => false,
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Reset Password',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Enter new password',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                     SizedBox(height: 8),
//                     Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey[300]!),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: TextField(
//                         controller: _newPasswordController,
//                         obscureText: !_showNewPassword,
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               _showNewPassword
//                                   ? Icons.visibility
//                                   : Icons.visibility_off,
//                             ),
//                             onPressed: () {
//                               setState(
//                                   () => _showNewPassword = !_showNewPassword);
//                             },
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     Text(
//                       'Confirm new password',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                     SizedBox(height: 8),
//                     Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey[300]!),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: TextField(
//                         controller: _confirmPasswordController,
//                         obscureText: !_showConfirmPassword,
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               _showConfirmPassword
//                                   ? Icons.visibility
//                                   : Icons.visibility_off,
//                             ),
//                             onPressed: () {
//                               setState(() =>
//                                   _showConfirmPassword = !_showConfirmPassword);
//                             },
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 40),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : _resetPassword,
//                         child: Text('Reset Password'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.black,
//                           padding: EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             if (_isLoading)
//               Container(
//                 color: Colors.black54,
//                 child: Center(child: CircularProgressIndicator()),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import './login_screen.dart';

// class ResetPasswordScreen extends StatefulWidget {
//   final String email;

//   ResetPasswordScreen({required this.email});

//   @override
//   _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
// }

// class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
//   final _emailController = TextEditingController();
//   bool _isLoading = false;

//   void _sendPasswordResetEmail() async {
//     if (_emailController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please enter your email')),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       // Send password reset email
//       await FirebaseAuth.instance.sendPasswordResetEmail(
//         email: _emailController.text.trim(),
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//               'Password reset email sent! Please check your email inbox.'),
//           backgroundColor: Colors.green,
//         ),
//       );

//       // Navigate to login screen
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => LoginScreen()),
//         (route) => false,
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Reset Password',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Enter your email to reset your password',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                     SizedBox(height: 8),
//                     Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey[300]!),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: TextField(
//                         controller: _emailController,
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 40),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : _sendPasswordResetEmail,
//                         child: Text('Send Reset Email'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.black,
//                           padding: EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             if (_isLoading)
//               Container(
//                 color: Colors.black54,
//                 child: Center(child: CircularProgressIndicator()),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  ResetPasswordScreen({required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // Fungsi untuk mengirim email reset password
  void _sendPasswordResetEmail() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kirim email reset password
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP for password reset sent to your email.'),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke layar login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reset Password',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your email to reset your password',
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
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendPasswordResetEmail,
                        child: Text('Send Reset Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
