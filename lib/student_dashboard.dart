// lib/student_dashboard.dart
import 'dart:convert';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  List<SocietyEvent> _allEvents = [];
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('society_events') ?? [];
    final loaded = data
        .map((s) => SocietyEvent.fromJson(jsonDecode(s)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    setState(() => _allEvents = loaded);
  }

  Future<void> _unregister(SocietyEvent event) async {
    if (user?.email == null) return;

    final email = user!.email!;
    final updatedList = _allEvents.map((e) {
      if (e.id == event.id) {
        return SocietyEvent(
          id: e.id,
          society: e.society,
          title: e.title,
          description: e.description,
          date: e.date,
          location: e.location,
          registeredStudents: e.registeredStudents.where((r) => r != email).toList(),
        );
      }
      return e;
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'society_events', updatedList.map((e) => jsonEncode(e.toJson())).toList());

    setState(() => _allEvents = updatedList);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Unregistered successfully!"), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          _buildMyEventsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ==================== HOME TAB (Clean list only) ====================
  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        _buildSliverHeader(),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: _buildFeaturedCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Upcoming Events",
                    style: GoogleFonts.inter(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _allEvents.isEmpty
                    ? const Center(
                    child: Text("No events available",
                        style: TextStyle(color: Colors.grey)))
                    : Column(
                    children:
                    _allEvents.map((e) => _eventTileClean(e)).toList()),
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  // ==================== MY EVENTS TAB ====================
  Widget _buildMyEventsTab() {
    final myEvents = _allEvents
        .where((e) => e.registeredStudents.contains(user?.email))
        .toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: Colors.green[700],
          flexibleSpace: FlexibleSpaceBar(
            title: Text("My Events",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            background: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.green[900]!, Colors.green[700]!]))),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: myEvents.isEmpty
              ? SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Icon(Icons.event_busy,
                        size: 90, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text("No registered events",
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey[600])),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _selectedIndex = 0),
                      child: Text("Browse Events",
                          style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) => _eventTileWithUnregister(myEvents[i]),
              childCount: myEvents.length,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== EVENT CARDS ====================
  Widget _eventTileClean(SocietyEvent event) {
    final d = event.date;
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  EventDetailsScreen(event: event, onRegister: _loadEvents))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15)
            ]),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: Colors.blue[50], borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(d.month.toString().padLeft(2, '0'),
                      style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                  Text(d.day.toString(),
                      style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.society.toUpperCase(),
                      style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(event.title,
                      style: GoogleFonts.inter(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                      "${d.hour}:${d.minute.toString().padLeft(2, '0')} • ${event.location}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _eventTileWithUnregister(SocietyEvent event) {
    final d = event.date;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15)
          ]),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d.month.toString().padLeft(2, '0'),
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                    Text(d.day.toString(),
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.society.toUpperCase(),
                        style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(event.title,
                        style: GoogleFonts.inter(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                        "${d.hour}:${d.minute.toString().padLeft(2, '0')} • ${event.location}",
                        style:
                        TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _unregister(event),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text("Unregister",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM NAV ====================
  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1.5))),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_filled, "Home", 0),
                _navItem(Icons.event_available, "My Events", 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: isActive ? Colors.blue[50] : Colors.transparent,
                shape: BoxShape.circle),
            child: Icon(icon,
                color: isActive ? Colors.blue[700] : Colors.grey[600],
                size: 28)),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.blue[700] : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
      ]),
    );
  }

  // ==================== HEADER & FEATURED CARD ====================
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.black, Color(0xFF002366)]))),
            Positioned(
                top: -100,
                left: -100,
                child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.3)),
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                        child: Container(color: Colors.transparent)))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome back,",
                            style: GoogleFonts.inter(
                                color: Colors.blue[200], fontSize: 14)),
                        Text(
                            user?.displayName?.split(' ').first ?? "Student",
                            style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/login', (r) => false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.logout,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.white.withOpacity(0.18),
          Colors.white.withOpacity(0.08)
        ]),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 25,
              offset: const Offset(0, 12))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(10)),
                child: Text("LIVE NOW",
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white))),
            const SizedBox(height: 10),
            Text("Student Week 2025",
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text("Join the opening ceremony!",
                style: GoogleFonts.inter(color: Colors.blue[200], fontSize: 15)),
          ]),
          Container(
            width: 70,
            height: 70,
            decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Center(
                child: Text("GO",
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF002366)))),
          ),
        ],
      ),
    );
  }
}

// ==================== EVENT DETAILS SCREEN (FULLY WORKING) ====================
class EventDetailsScreen extends StatelessWidget {
  final SocietyEvent event;
  final VoidCallback onRegister;

  const EventDetailsScreen(
      {super.key, required this.event, required this.onRegister});

  Future<void> _register(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('society_events') ?? [];
    final events = data.map((s) => SocietyEvent.fromJson(jsonDecode(s))).toList();
    final index = events.indexWhere((e) => e.id == event.id);
    if (index != -1 && FirebaseAuth.instance.currentUser?.email != null) {
      final email = FirebaseAuth.instance.currentUser!.email!;
      if (!events[index].registeredStudents.contains(email)) {
        events[index] = SocietyEvent(
          id: events[index].id,
          society: events[index].society,
          title: events[index].title,
          description: events[index].description,
          date: events[index].date,
          location: events[index].location,
          registeredStudents: [...events[index].registeredStudents, email],
        );
        await prefs.setStringList('society_events',
            events.map((e) => jsonEncode(e.toJson())).toList());
        onRegister();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registered successfully!"), backgroundColor: Colors.green));
      }
    }
  }

  String _getMonth(int m) =>
      ["", "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"][m];

  @override
  Widget build(BuildContext context) {
    final d = event.date;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 320,
              child: Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF002366)])),
                  child: Center(
                      child: Icon(Icons.event,
                          size: 120, color: Colors.white.withOpacity(0.2))))),
          Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.white24)),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_month,
                            color: Colors.white),
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.white24)),
                  ])),
          Positioned.fill(
            top: 260,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(40))),
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(event.society,
                              style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12))),
                      const SizedBox(height: 16),
                      Text(event.title,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.2)),
                      const SizedBox(height: 30),
                      _row(Icons.calendar_today,
                          "${d.day} ${_getMonth(d.month)}, ${d.year}", "DATE", Colors.blue),
                      const SizedBox(height: 20),
                      _row(Icons.access_time,
                          "${d.hour}:${d.minute.toString().padLeft(2, '0')}",
                          "TIME", Colors.orange),
                      const SizedBox(height: 20),
                      _row(Icons.location_on, event.location, "VENUE", Colors.red),
                      const SizedBox(height: 30),
                      const Text("About Event",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(event.description,
                          style: TextStyle(
                              color: Colors.grey[700], height: 1.6, fontSize: 15)),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: () => _register(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF002366),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16))),
                          child: const Text("Register Now",
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                    ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, String label, Color color) {
    return Row(children: [
      Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 16),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16))
              ])),
    ]);
  }
}