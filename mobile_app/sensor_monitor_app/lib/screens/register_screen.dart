import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart'; // Import LoginScreen
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final errorMessage = await authProvider.register(
        _usernameController.text,
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (errorMessage == null) {
        // Registration successful, navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful. Please login.')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        // Registration failed, show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Failed: $errorMessage')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors (Matching LoginScreen)
    final Color primaryBlue = const Color(0xFF2B6CB0);
    final Color accentBlue = const Color(0xFF4299E1);
    final Color inputFill = const Color(0xFFF7FAFF);
    final Color errorRed = const Color(0xFFE53E3E);
    final Color darkText = const Color(0xFF1A365D);
    final Color lightGrey = const Color(0xFFE0E0E0);

    return Scaffold(
      // Remove AppBar to match LoginScreen
      // appBar: AppBar(
      //   title: const Text('Register'),
      //   centerTitle: true,
      //   elevation: 0,
      // ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40), // Adjusted padding
            child: Animate(
              effects: [FadeEffect(duration: 700.ms, delay: 200.ms)], // Entrance fade animation
              child: Container(
                 width: double.infinity, // Allow container to take full width within padding
                padding: const EdgeInsets.all(30), // Adjusted padding
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95), // Slightly transparent white
                  borderRadius: BorderRadius.circular(24), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(0.15), // Shadow
                      blurRadius: 25,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children
                    children: <Widget>[
                      // Title and Subtitle with animation
                       Column(
                         children: [
                           Text(
                             '✍️', // Registration icon
                              style: TextStyle(fontSize: 60), // Larger icon
                           )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 300.ms)
                              .scale(duration: 600.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 10),
                           Text(
                            'Create Account',
                             textAlign: TextAlign.center,
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
                              'Join the Sensor Monitor Community', // Subtitle
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
                      const SizedBox(height: 40), // Spacing

                      // Username field with animation
                      TextFormField(
                        controller: _usernameController,
                         decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(color: darkText.withOpacity(0.6)), // Style label
                          prefixIcon: Icon(Icons.person_outline, color: primaryBlue), // Icon
                          filled: true,
                          fillColor: inputFill,
                           border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGrey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGrey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accentBlue, width: 2),
                          ),
                           errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: errorRed, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: errorRed, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Adjust padding
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 600.ms)
                          .slideY(begin: 0.5, curve: Curves.easeOutCubic),
                      const SizedBox(height: 20), // Spacing

                      // Password field with animation
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                         decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: darkText.withOpacity(0.6)), // Style label
                          prefixIcon: Icon(Icons.lock_outline, color: primaryBlue), // Icon
                          filled: true,
                          fillColor: inputFill,
                           border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGrey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGrey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accentBlue, width: 2),
                          ),
                           errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: errorRed, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: errorRed, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Adjust padding
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                           if (value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 700.ms)
                          .slideY(begin: 0.5, curve: Curves.easeOutCubic),
                       const SizedBox(height: 20), // Spacing
                      // Confirm Password field with animation
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                         decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(color: darkText.withOpacity(0.6)), // Style label
                          prefixIcon: Icon(Icons.lock_open_outlined, color: primaryBlue), // Icon
                          filled: true,
                          fillColor: inputFill,
                           border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGrey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGrey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accentBlue, width: 2),
                          ),
                           errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: errorRed, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: errorRed, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Adjust padding
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 800.ms)
                          .slideY(begin: 0.5, curve: Curves.easeOutCubic),
                      const SizedBox(height: 30), // Spacing

                      // Register button with animation
                      _isLoading
                          ? const Center(child: CircularProgressIndicator()) // Center the loader
                          : SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12), // Slightly less rounded corners
                                  ),
                                  elevation: 8,
                                  shadowColor: primaryBlue.withOpacity(0.4),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                                onPressed: _register,
                                child: Text(
                                  'Register',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 900.ms)
                                  .slideY(begin: 0.5, curve: Curves.easeOutCubic)
                                  .shimmer(duration: 1000.ms, delay: 1500.ms), // Add shimmer
                            ),
                      const SizedBox(height: 20), // Spacing

                      // Login link with animation
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: Text(
                            'Already have an account? Login here',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: primaryBlue.withOpacity(0.8),
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 1000.ms)
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