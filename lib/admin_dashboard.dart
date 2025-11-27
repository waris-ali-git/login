import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A simple data class for a lecture
class Lecture {
  final String name;
  final String description;
  final String filePath;

  Lecture({required this.name, required this.description, required this.filePath});

  // Methods to convert to/from JSON to store in SharedPreferences
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'filePath': filePath,
  };

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lectures.isEmpty
          ? const Center(child: Text('No lectures uploaded yet.'))
          : ListView.builder(
        itemCount: _lectures.length,
        itemBuilder: (context, index) {
          final lecture = _lectures[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(lecture.description),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.attach_file),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          lecture.filePath.split('/').last,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLectureDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}