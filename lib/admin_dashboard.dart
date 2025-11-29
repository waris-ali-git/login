import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login/database.dart';
import 'dart:ui';

// Removed imagePath from SocietyEvent
class SocietyEvent {
  final String id;
  final String society;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final List<String> registeredStudents;

  SocietyEvent({
    required this.id,
    required this.society,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    this.registeredStudents = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'society': society,
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'location': location,
    'registeredStudents': registeredStudents,
  };

  factory SocietyEvent.fromJson(Map<String, dynamic> json) => SocietyEvent(
    id: json['id'],
    society: json['society'],
    title: json['title'],
    description: json['description'],
    date: DateTime.parse(json['date']),
    location: json['location'],
    registeredStudents: List<String>.from(json['registeredStudents'] ?? []),
  );
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late String _adminEmail;
  late String _societyName;
  bool _isLoading = true;
  List<SocietyEvent> _events = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adminEmail = ModalRoute.of(context)!.settings.arguments as String;
      _societyName = Database.adminSocieties[_adminEmail] ?? 'General';
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await _loadEvents();
    setState(() => _isLoading = false);
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('society_events') ?? [];
    final allEvents = data.map((s) => SocietyEvent.fromJson(jsonDecode(s))).toList();
    
    setState(() {
      // Filter events by society
      _events = allEvents.where((e) => e.society == _societyName).toList();
    });
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load all existing events first to avoid overwriting other societies' events
    final currentData = prefs.getStringList('society_events') ?? [];
    List<SocietyEvent> allEvents = currentData.map((s) => SocietyEvent.fromJson(jsonDecode(s))).toList();
    
    // Remove current society's old events
    allEvents.removeWhere((e) => e.society == _societyName);
    
    // Add current society's updated events
    allEvents.addAll(_events);
    
    final data = allEvents.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('society_events', data);
  }

  void _showAddEditEventDialog([SocietyEvent? event]) {
    final isEdit = event != null;
    final titleC = TextEditingController(text: isEdit ? event!.title : '');
    final descC = TextEditingController(text: isEdit ? event.description : '');
    final locC = TextEditingController(text: isEdit ? event.location : '');
    DateTime date = isEdit ? event.date : DateTime.now();
    // Society is fixed to the logged-in admin's society
    String society = _societyName;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isEdit ? "Edit Event" : "Create Event",
                          style: GoogleFonts.inter(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 32),
                      
                      // Displaying the society name (read-only)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Text(
                          "Society: $society",
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(controller: titleC, style: const TextStyle(color: Colors.white), decoration: _glassInput("Title")),
                      const SizedBox(height: 16),
                      TextField(controller: descC, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: _glassInput("Description")),
                      const SizedBox(height: 16),
                      TextField(controller: locC, style: const TextStyle(color: Colors.white), decoration: _glassInput("Location")),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text("Date: ${date.toLocal().toString().split(' ')[0]}", style: const TextStyle(color: Colors.white70)),
                        trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF0A84FF))),
                              child: child!,
                            ),
                          );
                          if (picked != null) setDialogState(() => date = picked);
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A84FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            onPressed: () {
                              if (titleC.text.isEmpty || descC.text.isEmpty || locC.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all fields")));
                                return;
                              }
                              final newEvent = SocietyEvent(
                                id: isEdit ? event!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                                society: society,
                                title: titleC.text,
                                description: descC.text,
                                date: date,
                                location: locC.text,
                                registeredStudents: isEdit ? event.registeredStudents : [],
                              );
                              setState(() {
                                if (isEdit) {
                                  _events = _events.map((e) => e.id == event.id ? newEvent : e).toList();
                                } else {
                                  _events.add(newEvent);
                                }
                              });
                              _saveEvents();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? "Event updated!" : "Event created!")));
                            },
                            child: Text(isEdit ? "Update" : "Create"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(SocietyEvent event) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.1),
        title: const Text("Delete Event?", style: TextStyle(color: Colors.white)),
        content: const Text("This cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() => _events.removeWhere((e) => e.id == event.id));
              _saveEvents();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event deleted")));
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  InputDecoration _glassInput(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.25))),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: Colors.white, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.4),
                radius: 1.0,
                colors: [Color(0xFF1E3A8A), Color(0xFF0F172A), Colors.black],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(seconds: 25),
            top: -120,
            left: -120,
            child: Container(
              width: 700,
              height: 700,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Colors.white.withOpacity(0.07), Colors.transparent]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
                  child: Row(
                    children: [
                      // Display dynamic title based on society
                      Text(_isLoading ? "Admin Portal" : "$_societyName Portal", style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w400, color: Colors.white, letterSpacing: -1.2)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.logout, color: Colors.white70), onPressed: () => Navigator.pushReplacementNamed(context, '/admin-login')),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF0A84FF),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: "Events"),
                    Tab(text: "Registrations"),
                    Tab(text: "AI Assist"),
                    Tab(text: "Notifications"),
                  ],
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A84FF)))
                      : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventsTab(),
                      _buildRegistrationsTab(),
                      _buildAIAssistTab(),
                      _buildNotificationsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _showAddEditEventDialog(),
              child: const Text("Add Event", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ),
        Expanded(
          child: _events.isEmpty
              ? Center(child: Text("No $_societyName events yet", style: const TextStyle(color: Colors.white60)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _events.length,
                  itemBuilder: (_, i) {
                    final e = _events[i];
                    return _glassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text("${e.date.toLocal().toString().split(' ')[0]} • ${e.location}", style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            Text(e.description, style: const TextStyle(color: Colors.white60)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.white70), onPressed: () => _showAddEditEventDialog(e)),
                                IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: () => _confirmDelete(e)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRegistrationsTab() {
    return _events.isEmpty
        ? const Center(child: Text("No events created yet", style: TextStyle(color: Colors.white70)))
        : ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _events.length,
      itemBuilder: (_, i) {
        final e = _events[i];
        return _glassCard(
          child: ExpansionTile(
            title: Text(e.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text("${e.registeredStudents.length} registered", style: const TextStyle(color: Colors.white60)),
            children: e.registeredStudents.isEmpty
                ? [const ListTile(title: Text("No registrations yet", style: TextStyle(color: Colors.white60)))]
                : e.registeredStudents
                .map((email) => ListTile(leading: const Icon(Icons.person, color: Colors.white70), title: Text(email, style: TextStyle(color: Colors.white))))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildAIAssistTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white.withOpacity(0.3))),
              child: const Icon(Icons.smart_toy_rounded, size: 80, color: Color(0xFF0A84FF)),
            ),
            const SizedBox(height: 32),
            Text("AI Assistant", style: GoogleFonts.inter(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Text("Ask about events, suggest new ones,\nor analyze attendance trends.", textAlign: TextAlign.center, style: GoogleFonts.lexend(fontSize: 17, color: Colors.white70)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("Start Chat", style: TextStyle(fontSize: 17)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A84FF), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI Chat coming soon!"))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    final titleC = TextEditingController();
    final messageC = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Send Notification", style: GoogleFonts.inter(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          _glassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: titleC,
                    style: const TextStyle(color: Colors.white),
                    decoration: _glassInput("Title"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageC,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: _glassInput("Message"),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text("Send to All Students", style: TextStyle(fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A84FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (titleC.text.isEmpty || messageC.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter both title and message")),
                          );
                          return;
                        }
                        // In a real app, this would send a push notification via FCM
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Notification '${titleC.text}' sent to all students!")),
                        );
                        titleC.clear();
                        messageC.clear();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text("Recent Notifications", style: GoogleFonts.inter(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          // Placeholder for recent notifications history
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "No recent notifications sent.",
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
