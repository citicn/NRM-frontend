import 'package:flutter/material.dart';


class SignInButton extends StatelessWidget{
  final void Function()? onTap;
  final String txt;
  const SignInButton({
    super.key,
    required this.txt,
    required this.onTap,
});


  @override
  Widget build(BuildContext context) {
return GestureDetector(
  onTap: onTap,
  child: Container(
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.blueGrey[600],
      borderRadius: BorderRadius.circular(7),
    ),
    child: Center(
      child: Text(
          txt,
        style: TextStyle(
            color: Colors.white70,
        fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
);
  }
}