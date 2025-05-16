import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../../services/store_service.dart';
import '../../state/store_state.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_title.dart';
import '../stores/store_list_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('LoginScreen: Attempting login');
      print('LoginScreen: Email: ${_emailController.text}');

      final user = await widget.authService.login(
        _emailController.text,
        _passwordController.text,
      );

      print('LoginScreen: Login successful');
      print('LoginScreen: User data: ${user?.toMap()}');

      if (mounted) {
        final storeService = StoreService(authService: widget.authService);
        final storeState = StoreState(storeService);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StoreListScreen(
              storeState: storeState,
              authService: widget.authService,
            ),
          ),
        );
      }
    } catch (e) {
      print('LoginScreen: Login failed');
      print('LoginScreen: Error: $e');

      if (mounted) {
        String errorMessage = 'Login failed: ';
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _login();
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
                const SizedBox(height: 150),
                const AuthTitle(title: "Login"),
                const SizedBox(height: 30),
                AuthTextField(
                  hintText: "Email*",
                  controller: _emailController,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 30),
                AuthTextField(
                  hintText: "Password*",
                  controller: _passwordController,
                  validator: Validators.validatePassword,
                  isPassword: true,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: AuthButton(
                    onPressed: _isLoading ? null : _submitForm,
                    label: _isLoading ? "Logging in..." : "Login",
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text("Register"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
