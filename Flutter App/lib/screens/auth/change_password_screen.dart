import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../models/user.dart';
import 'edit_profile_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/auth_title.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChangePasswordScreen extends StatefulWidget {
  final AuthService authService;

  const ChangePasswordScreen({super.key, required this.authService});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassowrdController = TextEditingController();
  final _newPassowrdController = TextEditingController();
  final _confirmPassowrdController = TextEditingController();
  late final AuthService _authService;
  User? user;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService;
  }

  @override
  void dispose() {
    // Dispose controllers to free memory
    _oldPassowrdController.dispose();
    _newPassowrdController.dispose();
    _confirmPassowrdController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      bool isOldPasswordValid = await _authService.validateOldPassword(
        _oldPassowrdController.text,
      );

      if (!isOldPasswordValid) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Old password is incorrect')));
        return;
      }

      try {
        // Get current user data
        final email = await _authService.getStoredEmail();
        if (email == null) {
          throw Exception('No user email found');
        }

        final currentUser = await _authService.getUser(email);
        if (currentUser == null) {
          throw Exception('Failed to get current user data');
        }

        // Update user with new password but keep other details the same
        await _authService.updateProfileDetails(
          name: currentUser.name,
          email: currentUser.email,
          gender: currentUser.gender,
          level: currentUser.level,
          password: _newPassowrdController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfileScreen(authService: _authService),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update password: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 150),
                AuthTitle(title: "Change Password"),
                SizedBox(height: 30),
                AuthTextField(
                  isPassword: true,
                  hintText: "Enter Your Current Password",
                  controller: _oldPassowrdController,
                  validator: (value) => Validators.validateRequired(
                    value,
                    "Current Password",
                  ),
                ),
                SizedBox(height: 18),
                AuthTextField(
                  isPassword: true,
                  hintText: "Enter Your New Password",
                  controller: _newPassowrdController,
                  validator: (value) => Validators.validatePassword(value),
                ),
                SizedBox(height: 18),
                AuthTextField(
                  isPassword: true,
                  hintText: "Confirm Your New Password",
                  controller: _confirmPassowrdController,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _newPassowrdController.text,
                  ),
                ),
                SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AuthButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        ); // Use this to pop the screen when the button is pressed
                      },
                      label: "Cancel",
                      color: 0xFFFF0000,
                    ),
                    AuthButton(onPressed: _submitForm, label: "Confirm"),
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
