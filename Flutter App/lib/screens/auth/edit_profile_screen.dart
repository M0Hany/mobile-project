import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_dropdown.dart';
import '../../widgets/auth/auth_radio.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/auth_title.dart';
import 'login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final AuthService authService;

  const EditProfileScreen({super.key, required this.authService});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AuthService _authService;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedGender = '';
  String? _selectedLevel;

  bool inEdit = false;
  User? user;
  Uint8List? _newProfileImage;

  @override
  void dispose() {
    // Dispose controllers to free memory
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _authService = widget.authService;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final email = await _authService.getStoredEmail();
      if (email != null) {
        user = await _authService.getUser(email);
        if (user != null) {
          setState(() {
            _nameController.text = user!.name;
            _emailController.text = user!.email;
            _selectedGender = user!.gender ?? '';
            _selectedLevel = user!.level?.toString();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
      }
    }
  }

  void _logout() {
    _authService.logout();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Logged out!")));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(authService: _authService)),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800, // Limit image size
        maxHeight: 800,
        imageQuality: 85, // Compress image
      );
      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _newProfileImage = imageBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _showImageSourceSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take a Photo"),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      final updatedUser = User(
        email: _emailController.text,
        name: _nameController.text,
        gender: _selectedGender.isEmpty ? null : _selectedGender,
        level: _selectedLevel != null ? int.parse(_selectedLevel!) : null,
        profilePicture: user?.profilePicture,
        profilePictureData: _newProfileImage,
      );

      await _authService.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() {
          inEdit = false;
          _newProfileImage = null;
        });
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 50),
                GestureDetector(
                  onTap: inEdit ? _showImageSourceSelection : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _newProfileImage != null
                            ? MemoryImage(_newProfileImage!)
                            : user?.profilePicture != null
                                ? NetworkImage(
                                    'http://10.0.2.2:3000${user!.profilePicture!}',
                                  ) as ImageProvider
                                : null,
                        child: (_newProfileImage == null &&
                                user?.profilePicture == null)
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      if (inEdit)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  isEnabled: false,
                  controller: _emailController,
                  hintText: "Email",
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  isEnabled: inEdit,
                  controller: _nameController,
                  hintText: "Name",
                ),
                const SizedBox(height: 18),
                const Align(
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
                      onChanged: inEdit
                          ? (newValue) {
                              setState(() {
                                _selectedGender = newValue!;
                              });
                            }
                          : null,
                    ),
                    AuthRadio(
                      title: "Female",
                      value: "Female",
                      groupValue: _selectedGender,
                      onChanged: inEdit
                          ? (newValue) {
                              setState(() {
                                _selectedGender = newValue!;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select Level:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                AuthDropdown(
                  isEnabled: inEdit,
                  items: ['1', '2', '3', '4'],
                  value: _selectedLevel,
                  label: "Level",
                  onChanged: inEdit
                      ? (newValue) {
                          setState(() {
                            _selectedLevel = newValue;
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 18),
                Visibility(
                  visible: !inEdit,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AuthButton(
                        color: 0xFFFF0000,
                        onPressed: _logout,
                        label: "Logout",
                      ),
                      AuthButton(
                        onPressed: () {
                          setState(() {
                            inEdit = !inEdit;
                          });
                        },
                        label: "Edit",
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: inEdit,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AuthButton(
                        color: 0xFFFF0000,
                        onPressed: () {
                          setState(() {
                            inEdit = !inEdit;
                          });
                          _loadUserData();
                        },
                        label: "Cancel",
                      ),
                      AuthButton(onPressed: _updateProfile, label: "Confirm"),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: AuthButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/change_password");
                    },
                    label: "Change Password",
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
