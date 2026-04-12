import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'language_selection_page.dart';
import '../providers/auth_provider.dart';

class VerifyAccountPage extends StatefulWidget {
  const VerifyAccountPage({
    super.key,
    this.initialEmail,
  });

  final String? initialEmail;

  @override
  State<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends State<VerifyAccountPage> {
  final _formKey = GlobalKey<FormState>();
  
  // We need 6 controllers and 6 focus nodes for the individual boxes
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Helper method to combine the 6 boxes into one string
  String get _currentOtp => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayEmail = widget.initialEmail?.isNotEmpty == true ? widget.initialEmail! : 'your email';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verify Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    text: 'Enter 6 - digits code we send you on email\n',
                    style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
                    children: [
                      TextSpan(
                        text: displayEmail,
                        style: const TextStyle(color: Color(0xFF5AB2FF)), // Blue color
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Enter Your OTP',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                
                // 6 OTP Input Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      height: 55,
                      width: 45,
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: "",
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA), // Very light grey fill
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF00D1C1)), // Teal border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF00D1C1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF00D1C1), width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          // Auto-focus logic
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                
                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            final otp = _currentOtp;
                            if (otp.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter all 6 digits')),
                              );
                              return;
                            }

                            if (widget.initialEmail == null || widget.initialEmail!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error: Email is missing')),
                              );
                              return;
                            }

                            try {
                              await auth.verifyAccount(
                                email: widget.initialEmail!.trim(),
                                otpCode: otp,
                              );
                              
                              if (!context.mounted) return;
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Account verified. You can now log in.'),
                                ),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LanguageSelectionPage(),
                                ),
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(auth.error ?? 'OTP verification failed')),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D1C1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 30),

                // Footer Text with Links
                RichText(
                  text: const TextSpan(
                    text: "if you don't find the OTP code that we\nsent try ",
                    style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
                    children: [
                      TextSpan(
                        text: 'Checking Spam',
                        style: TextStyle(color: Color(0xFF5AB2FF), fontWeight: FontWeight.w500),
                      ),
                      TextSpan(text: ' or '),
                      TextSpan(
                        text: 'Send Code\nAgain',
                        style: TextStyle(color: Color(0xFF5AB2FF), fontWeight: FontWeight.w500),
                      ),
                    ],
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