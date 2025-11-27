import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    if (emailC.text.trim().isEmpty || passC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailC.text.trim(),
        password: passC.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/student-dashboard');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = e.code == 'user-not-found' || e.code == 'wrong-password'
          ? 'Invalid email or password'
          : 'Login failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Soft animated gradient background (pure Apple aesthetic)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.4),
                radius: 1.0,
                colors: [
                  Color(0xFF1E3A8A), // Deep indigo
                  Color(0xFF0F172A), // Almost black
                  Colors.black,
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Subtle moving light orb effect (very Apple)
          AnimatedPositioned(
            duration: const Duration(seconds: 20),
            curve: Curves.easeInOut,
            top: -100,
            left: -100,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Logo
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.school_rounded, size: 72, color: Colors.white),
                    ),

                    const SizedBox(height: 32),

                     Text(
                      "Student Portal",
                      style: GoogleFonts.inter(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        letterSpacing: -1.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Sign in to continue",
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w200,
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Glassmorphic Form Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Email Field
                              _glassTextField(
                                controller: emailC,
                                label: "Email Address",
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 24),

                              // Password Field
                              _glassTextField(
                                controller: passC,
                                label: "Password",
                                icon: Icons.lock_outline_rounded,
                                obscureText: true,
                                onSubmitted: (_) => login(),
                              ),

                              const SizedBox(height: 36),

                              // Sign In Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: loading ? null : login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0A84FF), // Apple Blue
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: loading
                                      ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                      : const Text(
                                    "Sign In",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 23),

                    // Footer Links
                    Column(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signup'),
                          child: const Text(
                            "Don't have an account? Sign Up",
                            style: TextStyle(color: Colors.white70, fontSize: 15.5),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/admin-login'),
                          child: const Text(
                            "Admin Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: obscureText ? TextInputAction.done : TextInputAction.next,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 17),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 17),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      ),
    );
  }
}