import 'package:flutter/material.dart';
import 'package:leetcode_ranking/login_field.dart';
import 'package:leetcode_ranking/registeration_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LoginField(
                icon: Icons.mail,
                hint: 'Mail Id',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LoginField(
                icon: Icons.password,
                hint: 'Password',
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
                    fixedSize: WidgetStatePropertyAll(
                        Size(MediaQuery.of(context).size.width * .5, 49))),
                onPressed: () {},
                child: Text(
                  'Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
