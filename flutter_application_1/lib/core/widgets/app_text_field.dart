import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;

  final bool obscure;
  final bool enabled;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  final String? Function(String?)? validator;

  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;

  final int maxLines;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.obscure = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.maxLines = 1,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureNow;

  @override
  void initState() {
    super.initState();
    _obscureNow = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final showPasswordToggle = widget.obscure && widget.suffixIcon == null;

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscureNow,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: showPasswordToggle
            ? IconButton(
                onPressed: () => setState(() => _obscureNow = !_obscureNow),
                icon: Icon(_obscureNow ? Icons.visibility : Icons.visibility_off),
              )
            : (widget.suffixIcon != null
                ? IconButton(
                    onPressed: widget.onSuffixPressed,
                    icon: Icon(widget.suffixIcon),
                  )
                : null),
      ),
    );
  }
}
