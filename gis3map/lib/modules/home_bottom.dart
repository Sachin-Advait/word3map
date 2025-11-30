import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:word3map/constants/api_constants.dart';

class HomeBottom extends StatelessWidget {
  const HomeBottom({
    super.key,
    required this.threeWordAddress,
    this.currentLocation,
  });

  final String threeWordAddress;
  final LatLng? currentLocation;

  Future<void> navigateToLocation(LatLng location) async {
    final url = Uri.parse(
      "http://maps.apple.com/?daddr=${location.latitude},${location.longitude}",
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      debugPrint(location.latitude.toString());
      debugPrint(location.longitude.toString());
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> saveLocation(LatLng location, String threeWord) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_locations') ?? [];
    saved.add("///$threeWord (${location.latitude}, ${location.longitude})");
    await prefs.setStringList('saved_locations', saved);
  }

  Future<void> shareViaWhatsApp(String threeWord) async {
    // Generate your fallback HTTPS link
    final fallbackUrl =
        "$BASE_URL/open?words=${Uri.encodeComponent(threeWord)}";

    // Put that inside WhatsApp share link
    final whatsappUrl = Uri.parse("whatsapp://send?text=$fallbackUrl");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      debugPrint(fallbackUrl.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(0, 15, 0, 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Text(
                    threeWordAddress,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  if (currentLocation != null) {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            "${currentLocation!.latitude}, ${currentLocation!.longitude}",
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Address copied to clipboard"),
                        backgroundColor: Colors.amber,
                      ),
                    );
                  }
                },
                child: const Icon(Icons.copy),
              ),
              const SizedBox(width: 20),
            ],
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  if (currentLocation != null) {
                    shareViaWhatsApp(threeWordAddress);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Image.asset("assets/images/whatsapp.png", height: 25),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (currentLocation != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InAppSharePage(
                          location: currentLocation!,
                          threeWordAddress: threeWordAddress,
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Image.asset("assets/images/share.png", height: 25),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (currentLocation != null) {
                    navigateToLocation(currentLocation!);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Image.asset("assets/images/navigate.png", height: 25),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (currentLocation != null) {
                    saveLocation(currentLocation!, threeWordAddress);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Location saved")),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Image.asset("assets/images/heart.png", height: 25),
                ),
              ),
            ],
          ),

          SizedBox(height: 5),
        ],
      ),
    );
  }
}

class InAppSharePage extends StatefulWidget {
  final LatLng location;
  final String threeWordAddress;

  const InAppSharePage({
    super.key,
    required this.location,
    required this.threeWordAddress,
  });

  @override
  State<InAppSharePage> createState() => _InAppSharePageState();
}

class _InAppSharePageState extends State<InAppSharePage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    fetchUsers();
    super.initState();
  }

  Future<void> fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId'); // Logged-in user

      final response = await http.get(Uri.parse('$BASE_URL/users'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          users = data
              .where(
                (user) => user['id'] != currentUserId,
              ) // 🚀 filter out self
              .map(
                (user) => {
                  'id': user['id'],
                  'name': user['name'],
                  'selected': false,
                },
              )
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching users: $e')));
    }
  }

  Future<void> sendNotification() async {
    final selectedUsers = users.where((user) => user['selected']).toList();

    if (selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one user")),
      );
      return;
    }

    final userIds = selectedUsers.map((user) => user['id']).toList();

    // Replace with your actual sender ID
    final prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? "";

    final message = "Shared location ///${widget.threeWordAddress}";

    try {
      final response = await http.post(
        Uri.parse("$BASE_URL/notifications"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "senderId": userId,
          "userIds": userIds,
          "message": message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Shared ///${widget.threeWordAddress} with ${selectedUsers.map((u) => u['name']).join(', ')}",
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        throw Exception("Failed to send notification");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Users")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return CheckboxListTile(
                        title: Text(
                          users[index]['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: users[index]['selected'],
                        onChanged: (val) {
                          setState(() {
                            users[index]['selected'] = val!;
                          });
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  width: MediaQuery.of(context).size.width,
                  child: OutlinedButton(
                    onPressed: () => sendNotification(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(12),
                    ),
                    child: Text(
                      "In-App Share",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}
