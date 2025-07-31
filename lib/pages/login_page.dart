import 'package:flutter/material.dart';
import 'package:nrm_project_app/components/signing_button.dart';
import 'package:nrm_project_app/components/text_field.dart';
import 'package:nrm_project_app/pages/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {
  final _uController = TextEditingController();
  final _pController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _uController.clear();
    _pController.clear();
  }

  //prijavljivanje
  void _signIn() async {
    final username = _uController.text.trim();
    final password = _pController.text;
    final response = await AuthSrv.login(username, password);
    if (response != null) {
      String token=response["access_token"];
      final shPreferances = await SharedPreferences.getInstance();
      await shPreferances.setString('token', token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      print('Token: ${response['access_token']}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pogresno korisnicko ime ili lozinka')),
      );
    }
  }

  //Preusmeravanje na stranicu za registraciju
  void _toRegisterP() async {
    final response = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(),
      ),
    );
    if (response == 'registered') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registracija uspesna! Prijavite se.')),
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

                //baner
                const Text(
                  "NRM Chat",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 50),

                // username
                MyTextField(
                  controller: _uController,
                  hintTxt: 'Korisnicko ime',
                  obscureTxt: false,
                ),
                const SizedBox(height: 25),

                //polje za lozinku
                MyTextField(
                  controller: _pController,
                  hintTxt: 'Lozinka',
                  obscureTxt: true,
                ),
                const SizedBox(height: 20),

                SignInButton(txt: "Prijavi se", onTap: _signIn),

                const SizedBox(height: 50),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Nemate nalog?"),
                    const SizedBox(width: 3),
                    GestureDetector(
                      onTap: _toRegisterP,
                      child:
                      const Text(
                        'Registuj se',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
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
