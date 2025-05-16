import 'package:flutter/material.dart';

class AuthRadio extends StatelessWidget {
  final String title;
  final String value;
  final String groupValue;
  final ValueChanged<String?>? onChanged;

  const AuthRadio({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: Color(0xFF252EFF),
        ),
        Text(title, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}
