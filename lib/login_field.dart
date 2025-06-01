import 'package:flutter/material.dart';

class LoginField extends StatelessWidget {
  final IconData icon;
  final String hint;
  const LoginField({
    required this.icon,
    required this.hint,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        // height: 50,
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: Color(0xff1E1E1E),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              keyboardType: hint == 'Password'
                  ? TextInputType.visiblePassword
                  : TextInputType.emailAddress,
              obscureText: hint == 'Password' ? true : false,
              cursorColor: Colors.white,
              decoration: InputDecoration(
                prefixIcon: Icon(icon),
                hintText: hint,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xff1E1E1E),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xff1E1E1E),
                  ),
                ),
                enabled: true,
                focusColor: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
