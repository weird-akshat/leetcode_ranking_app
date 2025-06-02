import 'package:flutter/material.dart';
import 'package:leetcode_ranking/login_field.dart';
import 'package:leetcode_ranking/registeration_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();

  final passWordController = TextEditingController();

  String? errorMessage;

  bool isLoading = false;

  Future<void> login() async {
    try {
      isLoading = true;
      setState(() {});
      await Supabase.instance.client.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passWordController.text.trim());
    } on AuthException catch (e) {
      isLoading = false;
      errorMessage = e.message;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LoginField(
                      icon: Icons.mail,
                      hint: 'Mail Id',
                      controller: emailController,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LoginField(
                      icon: Icons.password,
                      hint: 'Password',
                      controller: passWordController,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            return RegisterationPage();
                          }));
                        },
                        child: Text('Don\'t have an account? Register ')),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ButtonStyle(
                          fixedSize: WidgetStatePropertyAll(Size(
                              MediaQuery.of(context).size.width * .5, 49))),
                      onPressed: () async {
                        await login();

                        print(Supabase.instance.client.auth.currentUser?.id);
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  errorMessage != null ? Text(errorMessage!) : Text('')
                ],
              ),
            ),
          );
  }
}
