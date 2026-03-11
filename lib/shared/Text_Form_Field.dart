import 'package:flutter/material.dart';

class CustumTextfield extends StatefulWidget {
  final String hint;
  final bool isPassword; 
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Color? fillColor; 
  final Color? textColor; 
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final int maxLines;
  final TextInputType? keyboardType; // إضافة هذا الحقل

  const CustumTextfield({
    super.key,
    required this.hint,
    required this.isPassword,
    required this.controller,
    this.validator,
    this.fillColor,
    this.textColor,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.maxLines = 1,
    this.keyboardType, // إضافته في الكونستراكتور
  });

  @override
  State<CustumTextfield> createState() => _CustumTextfieldState();
}

class _CustumTextfieldState extends State<CustumTextfield> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      validator: widget.validator,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType, // استخدامه هنا
      style: TextStyle(color: widget.textColor ?? Colors.black),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: widget.fillColor ?? Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 1),
        ),
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: widget.isPassword
            ? IconButton(
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
        )
            : widget.suffixIcon, 
      ),
    );
  }
}