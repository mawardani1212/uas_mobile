// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
// import 'package:auth_app/providers/auth_provider.dart';

// class VerifyOTPScreen extends ConsumerStatefulWidget {
//   final String verificationId;
//   final String phoneNumber;
//   final bool isRegistration;
//   final String? name;
//   final String? password;

//   const VerifyOTPScreen({
//     super.key,
//     required this.verificationId,
//     required this.phoneNumber,
//     this.isRegistration = false,
//     this.name,
//     this.password,
//   });

//   @override
//   ConsumerState<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
// }

// class _VerifyOTPScreenState extends ConsumerState<VerifyOTPScreen> {
//   String currentText = "";

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Verify OTP')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Enter OTP sent to ${widget.phoneNumber}'),
//             const SizedBox(height: 20),
//             PinCodeTextField(
//               appContext: context,
//               length: 6,
//               onChanged: (value) {
//                 setState(() {
//                   currentText = value;
//                 });
//               },
//               onCompleted: _verifyOTP,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _verifyOTP(String otp) async {
//     final success = await ref.read(authProvider).verifyOTP(
//           widget.verificationId,
//           otp,
//         );

//     if (success) {
//       if (mounted) {
//         // Navigate to home screen
//         Navigator.of(context).popUntil((route) => route.isFirst);
//       }
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Invalid OTP')),
//         );
//       }
//     }
//   }
// }