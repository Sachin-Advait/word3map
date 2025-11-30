import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word3map/constants/api_constants.dart';
import 'package:word3map/modules/search_card.dart';
import 'package:word3map/routes/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final controller = TextEditingController();
  bool isLoading = false;

  Future<void> loginUser() async {
    final name = controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your name")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Save the returned user id
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', data['user']['id']); // <-- updated

        // Navigate to Home
        Navigator.pushReplacementNamed(context, AppRoutes.HOME);
      } else {
        throw Exception('Failed to login');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: .96),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 68),
          Center(
            child: Text(
              'Log in to get started',
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
          const SizedBox(height: 35),
          Container(
            alignment: Alignment.center,
            height: 150,
            width: 150,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
            child: Image.asset(
              'assets/images/logo.png',
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 65),
          SearchCard(
            searchController: controller,
            icon: Icons.person,
            hintText: 'Enter you name',
          ),

          const SizedBox(height: 56),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: OutlinedButton(
              onPressed: isLoading ? null : loginUser,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(12),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Login",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
