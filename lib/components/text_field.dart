import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget{
  final TextEditingController controller;
  final String hintTxt;
  final bool obscureTxt;
  const MyTextField({
    super.key,
    required this.controller,
    required this.hintTxt,
    required this.obscureTxt
});

  @override
  Widget build(BuildContext context) {
    return TextField(
        controller: controller,
        obscureText: obscureTxt,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3.0),
            borderSide: BorderSide(color: Colors.blueGrey.shade100)
          ),
          fillColor: Colors.blueGrey,
          filled: true,
          hintText: hintTxt,
          hintStyle: const TextStyle(color: Colors.white70),
        ),
    );
  }
}


