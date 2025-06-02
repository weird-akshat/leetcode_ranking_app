import 'package:flutter/material.dart';
import 'package:leetcode_ranking/leaderboard_page.dart';
import 'package:leetcode_ranking/login_field.dart';
import 'package:leetcode_ranking/main_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterationPage extends StatefulWidget {
  const RegisterationPage({super.key});

  @override
  State<RegisterationPage> createState() => _RegisterationPageState();
}

class _RegisterationPageState extends State<RegisterationPage> {
  final emailController = TextEditingController();
  final passWordController = TextEditingController();
  final leetcodeController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> signIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passWordController.text.trim(),
      );

      final user = response.user;

      try {
        await Supabase.instance.client
            .from('details')
            .insert({'leetcode_id': leetcodeController.text.trim()});
      } catch (e) {}

      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      try {
        await Supabase.instance.client.from('user_leetcode_map').insert({
          'user_id': user.id,
          'leetcode_id': leetcodeController.text.trim(),
        });
      } catch (e) {}

      final signInResponse =
          await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passWordController.text.trim(),
      );

      if (signInResponse.user == null) {
        setState(() {
          errorMessage = 'Sign-in failed after registration.';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Navigate to HomePage after successful sign-in
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainDashboard()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.message;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    checkUser('roonil03');
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
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
                      child: LoginField(
                        icon: Icons.computer_rounded,
                        hint: 'Your leetcode ID',
                        controller: leetcodeController,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                            fixedSize: MaterialStateProperty.all(Size(
                                MediaQuery.of(context).size.width * .5, 49))),
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          bool exists =
                              await checkUser(leetcodeController.text.trim());

                          if (!exists) {
                            setState(() {
                              isLoading = false;
                              errorMessage = 'Leetcode ID doesn\'t exist';
                            });
                          } else {
                            await signIn();
                          }
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    errorMessage == null
                        ? const SizedBox()
                        : Text(errorMessage!)
                  ]),
            ),
          );
  }
}

// Simple HomePage to navigate to after successful registration
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: const Center(
          child: Text('Welcome! Registration and sign-in successful.')),
    );
  }
}

Future<bool> doesLeetCodeUserExist(String username) async {
  final url = Uri.parse('https://leetcode.com/graphql');
  final headers = {'Content-Type': 'application/json'};

  final body = jsonEncode({
    'query': '''
      query getUserProfile(\$username: String!) {
        matchedUser(username: \$username) {
          username
        }
      }
    ''',
    'variables': {'username': username},
  });

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['data']['matchedUser'] != null;
  } else {
    throw Exception('Failed to fetch data: ${response.statusCode}');
  }
}

Future<bool> checkUser(String inputUsername) async {
  try {
    bool exists = await doesLeetCodeUserExist(inputUsername);
    return exists;
  } catch (e) {
    print('⚠️ Error: $e');
    return false;
  }
}
