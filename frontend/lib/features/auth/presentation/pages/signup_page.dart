import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'verify_account_page.dart';
// Make sure to import your login page here so the bottom link works


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Added for the new UI

  // States for toggling password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white, // Match white background from image
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align text to left
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Lets Register\nAccount',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hello user, you have\na greatful journey',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 40),

                // Username Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Password Field with Eye Icon
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 16),

                // Confirm Password Field with Eye Icon
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }
                            try {
                              await auth.signUp(
                                fullName: _nameController.text.trim(),
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Account created. Verify OTP then log in.'),
                                ),
                              );
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => VerifyAccountPage(
                                    initialEmail: _emailController.text.trim(),
                                  ),
                                ),
                              );
                            } catch (_) {
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(auth.error ?? 'Sign up failed')),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D1C1), // Teal color from image
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Navigate back to login page
                      Navigator.of(context).pop(); 
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Already have an account ? ",
                        style: TextStyle(color: Colors.black87),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(color: Color(0xFF5AB2FF), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
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