import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final errorMessage = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successful')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: $errorMessage')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    final Color primaryBlue = const Color(0xFF2B6CB0);
    final Color accentBlue = const Color(0xFF4299E1);
    final Color inputFill = const Color(0xFFF7FAFF);
    final Color errorRed = const Color(0xFFE53E3E);
    final Color darkText = const Color(0xFF1A365D);
    final Color lightGrey =
        const Color(0xFFE0E0E0); // Added a light grey for borders

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0F2F7),
              Color(0xFFB3E5FC)
            ], // Lighter, more inviting gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Animate(
              effects: [FadeEffect(duration: 700.ms, delay: 200.ms)],
              child: Container(
                width: double
                    .infinity, // Allow container to take full width within padding
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                      0.95), // Slightly transparent white for a modern feel
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(
                          0.15), // Adjusted shadow color and opacity
                      blurRadius: 25, // Increased blur radius
                      offset: const Offset(0, 15), // Adjusted offset
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment
                        .stretch, // Stretch children horizontally
                    children: [
                      // Title with emoji - Centered
                      Column(
                        children: [
                          Text(
                            '💡', // Use a simple text placeholder
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 300.ms)
                              .scale(
                                  duration: 600.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 10),
                          Text(
                            'Sensor Monitor App',
                            textAlign: TextAlign.center, // Center align text
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 400.ms)
                              .slideY(begin: 0.5, curve: Curves.easeOutCubic),
                          const SizedBox(height: 5),
                          Text(
                            'Login to your account', // Added a subtitle
                            textAlign: TextAlign.center, // Center align text
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: darkText.withOpacity(0.7),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 500.ms)
                              .slideY(begin: 0.5, curve: Curves.easeOutCubic),
                        ],
                      ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
                      const SizedBox(height: 40), // Increased spacing

                      // Username field
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(
                              color: darkText.withOpacity(0.6)), // Style label
                          prefixIcon: Icon(Icons.person_outline,
                              color: primaryBlue), // Use outline icon
                          filled: true,
                          fillColor: inputFill,
                          border: OutlineInputBorder(
                            // Default border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGrey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            // Enabled border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGrey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            // Focused border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: accentBlue,
                                width: 2), // Use accent blue for focus
                          ),
                          errorBorder: OutlineInputBorder(
                            // Error border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: errorRed, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            // Focused error border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: errorRed, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20), // Adjust padding
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 600.ms)
                          .slideY(begin: 0.5, curve: Curves.easeOutCubic),
                      const SizedBox(height: 20), // Adjusted spacing

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                              color: darkText.withOpacity(0.6)), // Style label
                          prefixIcon: Icon(Icons.lock_outline,
                              color: primaryBlue), // Use outline icon
                          filled: true,
                          fillColor: inputFill,
                          border: OutlineInputBorder(
                            // Default border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGrey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            // Enabled border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGrey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            // Focused border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: accentBlue,
                                width: 2), // Use accent blue for focus
                          ),
                          errorBorder: OutlineInputBorder(
                            // Error border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: errorRed, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            // Focused error border
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: errorRed, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20), // Adjust padding
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 700.ms)
                          .slideY(begin: 0.5, curve: Curves.easeOutCubic),
                      const SizedBox(height: 30), // Adjusted spacing

                      // Login button or loader
                      _isLoading
                          ? Center(
                              // Center the loader
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(primaryBlue),
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        12), // Slightly less rounded corners
                                  ),
                                  elevation: 8,
                                  shadowColor: primaryBlue
                                      .withOpacity(0.4), // Adjusted shadow
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15), // Adjusted padding
                                ),
                                onPressed: _login,
                                child: Text(
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 800.ms)
                                  .slideY(
                                      begin: 0.5, curve: Curves.easeOutCubic)
                                  .shimmer(
                                      duration: 1000.ms,
                                      delay: 1400.ms), // Add shimmer effect
                            ),
                      const SizedBox(height: 25),
                      // Register link - Centered
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: Text(
                            "Don't have an account? Register here",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: primaryBlue.withOpacity(0.8),
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 900.ms)
                            .slideY(begin: 0.5, curve: Curves.easeOutCubic),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
