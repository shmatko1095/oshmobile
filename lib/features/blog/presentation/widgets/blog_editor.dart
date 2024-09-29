import 'package:flutter/material.dart';

class BlogEditor extends StatelessWidget {
  final String? hintText;
  final TextEditingController controller;

  const BlogEditor({
    super.key,
    this.hintText,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hintText,
      ),
      controller: controller,
      maxLines: null,
      validator: (value) =>
          value!.trim().isEmpty ? "$hintText is missing" : null,
    );
  }
}
