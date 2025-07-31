import 'package:flutter/material.dart';
import 'package:nrm_project_app/components/signing_button.dart';
import 'package:nrm_project_app/components/text_field.dart';

import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _uController = TextEditingController();
  final _pController = TextEditingController();
  final _pController1 = TextEditingController();

  void _signUp() async {
    final username = _uController.text.trim();
    final password = _pController.text;
    final confirmPass = _pController1.text;

    if (password != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lozinke se ne poklapaju!')),
      );
      return;
    }

    final response = await AuthSrv.register(username, password);

    if (response != null) {
      Navigator.pop(context, 'registered');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Korisnik vec postoji ili je dsolo do greske.')),
      );
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                // logo
                Icon(
                  Icons.chat_bubble_rounded,
                  size: 95,
                  color: Colors.blueGrey,
                ),

                //banner
                const Text(
                  "NRM Chat",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 50),

                // korisnicko ime
                MyTextField(
                  controller: _uController,
                  hintTxt: 'Korisnicko ime',
                  obscureTxt: false,
                ),
                const SizedBox(height: 25),

                //lozinka
                MyTextField(
                  controller: _pController,
                  hintTxt: 'Lozinka',
                  obscureTxt: true,
                ),

                const SizedBox(height: 25),

                //lozinka za proveru
                MyTextField(
                  controller: _pController1,
                  hintTxt: 'Potvrdi lozinku',
                  obscureTxt: true,
                ),

                const SizedBox(height: 20),


                SignInButton(txt: "Registruj se", onTap: _signUp),

                const SizedBox(height: 50),

                //precica za login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Vrati se na"),
                    const SizedBox(width: 3),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child:
                    const Text(
                      'Login stranicu',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ),
                  ],
                ),

                //new
              ],
            ),

            // logo
          ),
        ),
      ),
    );
  }
}
