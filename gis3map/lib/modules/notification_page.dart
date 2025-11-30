import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:word3map/constants/api_constants.dart';
import 'package:word3map/routes/routes.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  bool isReadLoading = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception("User not logged in");
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/notifications/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          notifications = data
              .map(
                (notif) => {
                  'id': notif['id'],
                  'senderName': notif['senderName'],
                  'message': notif['message'],
                  'createdAt': notif['createdAt'],
                  'read': notif['read'],
                },
              )
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch notifications");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> readNotifications(Map<String, dynamic> notif) async {
    setState(() {
      isReadLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception("User not logged in");
      }

      final response = await http.post(
        Uri.parse("$BASE_URL/notifications/${notif['id']}/read"),
      );

      debugPrint(response.body);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${responseData["message"]}')),
        );
      } else {
        throw Exception("Failed to fetch notifications");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        isReadLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("No notifications"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return ListTile(
                  leading: Icon(
                    notif['read']
                        ? Icons.mark_email_read
                        : Icons.mark_email_unread,
                    color: notif['read'] ? Colors.green : Colors.red,
                  ),
                  title: Text(notif['senderName']),
                  subtitle: Text(
                    notif['message'],
                    style: TextStyle(fontSize: 16),
                  ),
                  trailing: Text(
                    DateTime.parse(
                      notif['createdAt'],
                    ).toLocal().toString().split('.')[0],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    String message = notif['message'].toString();
                    String threeWord = message.split('///').last;

                    // Go back to Home and pass the 3-word address
                    readNotifications(notif).then((_) {
                      if (isReadLoading = false) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.HOME,
                          (route) => false,
                          arguments: threeWord,
                        );
                      }
                    });
                  },
                );
              },
            ),
    );
  }
}
