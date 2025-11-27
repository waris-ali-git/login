import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';

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

  factory Lecture.fromJson(Map<String, dynamic> json) => Lecture(
        name: json['name'],
        description: json['description'],
        filePath: json['filePath'],
      );
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Lecture> _lectures = [];
  late String _adminEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // We need to wait for the first build to get the adminEmail from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _adminEmail = ModalRoute.of(context)!.settings.arguments as String;
        _loadLectures();
      }
    });
  }

  // Load lectures from device storage
  Future<void> _loadLectures() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final lectureListString = prefs.getStringList('lectures_$_adminEmail') ?? [];
    if (mounted) {
      setState(() {
        _lectures = lectureListString
            .map((s) => Lecture.fromJson(jsonDecode(s)))
            .toList();
        _isLoading = false;
      });
    }
  }

  // Save a new lecture to device storage
  Future<void> _addLecture(
      String name, String description, PlatformFile file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${file.name}';
      final newFile = File(filePath);

      if (file.path != null) {
        final sourceFile = File(file.path!);
        await sourceFile.copy(filePath);
      } else if (file.bytes != null) {
        await newFile.writeAsBytes(file.bytes!);
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: Could not read file data.")),
          );
        }
        return;
      }

      final newLecture = Lecture(name: name, description: description, filePath: filePath);

      final prefs = await SharedPreferences.getInstance();
      final currentLecturesString = prefs.getStringList('lectures_$_adminEmail') ?? [];
      final currentLectures = currentLecturesString.map((s) => Lecture.fromJson(jsonDecode(s))).toList();
      
      final updatedLectures = [...currentLectures, newLecture];
      final lectureListString = updatedLectures.map((l) => jsonEncode(l.toJson())).toList();
      await prefs.setStringList('lectures_$_adminEmail', lectureListString);

      await _loadLectures();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving lecture: $e")),
        );
      }
    }
  }

  void _showAddLectureDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    PlatformFile? selectedFile;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Lecture'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Lecture Name'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'pdf', 'png'],
                        );
                        if (result != null) {
                          setDialogState(() {
                            selectedFile = result.files.first;
                          });
                        }
                      },
                      child: const Text('Select File'),
                    ),
                    const SizedBox(height: 10),
                    if (selectedFile != null)
                      Text('Selected: ${selectedFile!.name}', overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        descriptionController.text.isNotEmpty &&
                        selectedFile != null) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const Center(child: CircularProgressIndicator());
                        },
                      );

                      await _addLecture(
                        nameController.text,
                        descriptionController.text,
                        selectedFile!,
                      );
                      
                      if (mounted) {
                        Navigator.of(context).pop(); 
                        Navigator.of(context).pop();
                      }
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields and select a file.")),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/admin-login');
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
                      child: InkWell(
                        onTap: () async {
                          final result = await OpenFilex.open(lecture.filePath);
                          if (result.type != ResultType.done) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open file: ${result.message}')),
                            );
                          }
                        },
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
