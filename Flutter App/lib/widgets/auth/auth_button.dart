import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final int color;

  const AuthButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.color = 0xFF252EFF,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: const MaterialStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(vertical: 10, horizontal: 53),
        ),
        backgroundColor: MaterialStatePropertyAll<Color>(Color(color)),
      ),
      child: Text(label),
    );
  }
}
