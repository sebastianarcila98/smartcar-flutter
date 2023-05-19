import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatelessWidget {
  const HomeScreen(this.accessToken, {super.key});

  final String accessToken;

  Future<void> getVehicle() async {
    final url = Uri.parse('https://api.smartcar.com/v2.0/vehicles');

    try {
      final response = await http
          .get(url, headers: {'Authorization': 'Bearer $accessToken'});
      print(json.decode(response.body));
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Telematics'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            getVehicle();
          },
          child: const Text('Get Vehicle info'),
        ),
      ),
    );
  }
}
