import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final firstNameC = TextEditingController();
  final lastNameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final confirmPassC = TextEditingController();

  bool loading = false;

  signup() async {
    if (passC.text.trim() != confirmPassC.text.trim()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Passwords do NOT match")));
      return;
    }

    try {
      setState(() => loading = true);

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailC.text.trim(),
        password: passC.text.trim(),
      );

      await FirebaseAuth.instance.currentUser?.updateDisplayName(
        "${firstNameC.text.trim()} ${lastNameC.text.trim()}",
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Signup Failed: $e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.4),
                radius: 1.0,
                colors: [
                  Color(0xFF1E3A8A),
                  Color(0xFF0F172A),
                  Colors.black,
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Light orb
          AnimatedPositioned(
            duration: const Duration(seconds: 20),
            curve: Curves.easeInOut,
            top: -100,
            left: -120,
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
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded,
                          size: 72, color: Colors.white),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      "Create Account",
                      style: GoogleFonts.inter(
                        fontSize: 38,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: -1.2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Join the Student Portal",
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w200,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Glass Card
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
                              _glassField(
                                  controller: firstNameC,
                                  label: "First Name",
                                  icon: Icons.person_outline),

                              const SizedBox(height: 24),

                              _glassField(
                                  controller: lastNameC,
                                  label: "Last Name",
                                  icon: Icons.person_outline),

                              const SizedBox(height: 24),

                              _glassField(
                                controller: emailC,
                                label: "Email Address",
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 24),

                              _glassField(
                                controller: passC,
                                label: "Password",
                                icon: Icons.lock_outline_rounded,
                                obscureText: true,
                              ),

                              const SizedBox(height: 24),

                              _glassField(
                                controller: confirmPassC,
                                label: "Confirm Password",
                                icon: Icons.lock_outline_rounded,
                                obscureText: true,
                              ),

                              const SizedBox(height: 36),

                              // Sign Up Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: loading ? null : signup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0A84FF),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: loading
                                      ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  )
                                      : const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text(
                        "Already have an account? Log In",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15.5,
                        ),
                      ),
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

  // Glass-style text field
  Widget _glassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 17),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
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
        contentPadding:
        const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      ),
    );
  }
}
