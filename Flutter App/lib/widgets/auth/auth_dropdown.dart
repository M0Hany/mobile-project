
import 'package:flutter/material.dart';

class AuthDropdown extends StatelessWidget {
  final String? label;
  final String? hintText;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String? value;
  final bool? isEnabled;

  const AuthDropdown({
    super.key,
    this.onChanged,
    required this.items,
    this.label,
    this.hintText,
    this.value,
    this.isEnabled = true,
  });


  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hintText,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(40)),
            borderSide: BorderSide(
                color: isEnabled! ? Color(0xFF252EFF) : Color(0xFF808080),
                width: 2.0
            )
        ),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(40)),
            borderSide: const BorderSide(color: Color(0xFF252EFF), width: 2.0)
        ),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(40)),
            borderSide: const BorderSide(color: Color(0xFFed4337), width: 2.0)
        ),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(40)),
            borderSide: const BorderSide(color: Color(0xFFed4337), width: 2.0)
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
        value: item,
        child: Text("$label $item"),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
