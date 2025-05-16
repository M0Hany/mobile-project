import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../models/user.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_dropdown.dart';
import '../../widgets/auth/auth_radio.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/auth_title.dart';
import '../../services/auth_service.dart';
import '../../services/store_service.dart';
import '../../state/store_state.dart';
import '../stores/store_list_screen.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  final AuthService authService;

  const RegisterScreen({super.key, required this.authService});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedGender = "";
  String _selectedLevel = "";

  void _register() async {
    try {
      print('Starting registration process...');
      print('Name: ${_nameController.text}');
      print('Email: ${_emailController.text}');
      print('Gender: $_selectedGender');
      print('Level: $_selectedLevel');

      final user = User(
        name: _nameController.text,
        email: _emailController.text,
        gender: _selectedGender.isEmpty ? null : _selectedGender,
        level: _selectedLevel.isEmpty ? null : int.parse(_selectedLevel),
      );

      print('Attempting to register user with server...');
      await widget.authService.register(user, _passwordController.text);
      print('Registration successful!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            duration: Duration(seconds: 2),
          ),
        );

        // Wait for the snackbar to be visible before navigating
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(authService: widget.authService),
              ),
            );
          }
        });
      }
    } catch (e, stackTrace) {
      print('Registration error details:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        String errorMessage = 'Registration failed: ';
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection refused')) {
          errorMessage +=
              'Cannot connect to server. Please check if the server is running.';
        } else {
          errorMessage += e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers to free memory
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _register();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                AuthTitle(title: "Register"),
                SizedBox(height: 30),
                AuthTextField(
                  hintText: "Full Name*",
                  controller: _nameController,
                  validator: (value) =>
                      Validators.validateRequired(value, "Full name"),
                ),
                SizedBox(height: 30),

                /// Gender Selection
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select Gender:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    AuthRadio(
                      title: "Male",
                      value: "Male",
                      groupValue: _selectedGender,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedGender = newValue!;
                        });
                      },
                    ),
                    AuthRadio(
                      title: "Female",
                      value: "Female",
                      groupValue: _selectedGender,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedGender = newValue!;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 18),
                AuthTextField(
                  hintText: "Email*",
                  controller: _emailController,
                  validator: (value) => Validators.validateEmail(value),
                ),
                SizedBox(height: 18),
                AuthDropdown(
                  items: ["1", "2", "3", "4"],
                  hintText: "Select Your Level",
                  label: "Level",
                  onChanged: (newValue) {
                    setState(() {
                      _selectedLevel = newValue!;
                    });
                  },
                ),
                SizedBox(height: 18),
                AuthTextField(
                  hintText: "Password*",
                  isPassword: true,
                  controller: _passwordController,
                  validator: (value) => Validators.validatePassword(value),
                ),
                SizedBox(height: 18),
                AuthTextField(
                  hintText: "Confirm Password*",
                  isPassword: true,
                  controller: _confirmPasswordController,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                SizedBox(height: 40),
                AuthButton(label: "Register", onPressed: _submitForm),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  child: Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
