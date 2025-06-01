import 'package:flutter/material.dart';
import 'package:leetcode_ranking/login_field.dart';

class RegisterationPage extends StatelessWidget {
  const RegisterationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: LoginField(
              icon: Icons.mail,
              hint: 'Mail Id',
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: LoginField(
              icon: Icons.password,
              hint: 'Password',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LoginField(
              icon: Icons.computer_rounded,
              hint: 'Your leetcode ID',
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ButtonStyle(
                  fixedSize: WidgetStatePropertyAll(
                      Size(MediaQuery.of(context).size.width * .5, 49))),
              onPressed: () {},
              child: Text(
                'Register',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ]),
      ),
    );
  }
}
