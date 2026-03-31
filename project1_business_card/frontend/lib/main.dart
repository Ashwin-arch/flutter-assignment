import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const BusinessCardApp());

class BusinessCardApp extends StatelessWidget {
  const BusinessCardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Digital Card',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
      ),
      home: const BusinessCardScreen(),
    );
  }
}

class ContactItem {
  final IconData icon;
  final String label;
  final String value;
  final String? url;
  const ContactItem({required this.icon, required this.label, required this.value, this.url});

  static IconData _getIcon(String name) {
    switch (name) {
      case 'phone_rounded': return Icons.phone_rounded;
      case 'email_rounded': return Icons.email_rounded;
      case 'code_rounded': return Icons.code_rounded;
      case 'location_on_rounded': return Icons.location_on_rounded;
      case 'flutter_dash': return Icons.flutter_dash;
      case 'bolt': return Icons.bolt;
      case 'hub_rounded': return Icons.hub_rounded;
      case 'palette_rounded': return Icons.palette_rounded;
      case 'local_fire_department': return Icons.local_fire_department;
      default: return Icons.help_outline;
    }
  }

  factory ContactItem.fromJson(Map<String, dynamic> json) {
    return ContactItem(
      icon: _getIcon(json['icon_name']),
      label: json['label'],
      value: json['value'],
      url: json['url'],
    );
  }
}

class SkillItem {
  final String label;
  final IconData icon;
  final int color;
  const SkillItem({required this.label, required this.icon, required this.color});

  static IconData _getIcon(String name) {
    switch (name) {
      case 'flutter_dash': return Icons.flutter_dash;
      case 'code': return Icons.code;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'bolt': return Icons.bolt;
      case 'hub_rounded': return Icons.hub_rounded;
      case 'palette_rounded': return Icons.palette_rounded;
      default: return Icons.code;
    }
  }

  factory SkillItem.fromJson(Map<String, dynamic> json) {
    return SkillItem(
      label: json['label'],
      icon: _getIcon(json['icon_name']),
      color: json['color'],
    );
  }
}

class Profile {
  final String name, role, location, aboutMe;
  final List<ContactItem> contacts;
  final List<SkillItem> skills;
  const Profile({required this.name, required this.role, required this.location, required this.aboutMe, required this.contacts, required this.skills});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'],
      role: json['role'],
      location: json['location'],
      aboutMe: json['about_me'],
      contacts: (json['contacts'] as List).map((e) => ContactItem.fromJson(e)).toList(),
      skills: (json['skills'] as List).map((e) => SkillItem.fromJson(e)).toList(),
    );
  }
}

class BusinessCardScreen extends StatefulWidget {
  const BusinessCardScreen({super.key});
  @override
  State<BusinessCardScreen> createState() => _BusinessCardScreenState();
}

class _BusinessCardScreenState extends State<BusinessCardScreen>
    with SingleTickerProviderStateMixin {
  bool _aboutMeVisible = false;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late Future<Profile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _profileFuture = _fetchProfile();
  }

  Future<Profile> _fetchProfile() async {
    // Change this IP to the backend IP. Using 10.0.2.2 for Android emulator. Use localhost for desktop.
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/v1/profile'));
      if (response.statusCode == 200) {
        return Profile.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      // Fallback for demo purposes if backend isn't running
      return const Profile(
        name: 'Argos Dev (Offline)',
        role: 'Flutter Developer',
        location: 'Bengaluru, Karnataka',
        aboutMe: 'Cannot connect to server. Please ensure the FastAPI backend is running.',
        contacts: [],
        skills: [],
      );
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _toggleAboutMe() {
    setState(() => _aboutMeVisible = !_aboutMeVisible);
    _aboutMeVisible ? _controller.forward() : _controller.reverse();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: FutureBuilder<Profile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No profile found', style: TextStyle(color: Colors.white)));
            }

            final profile = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Avatar ──
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3EC6E0)]),
                        ),
                        child: const CircleAvatar(
                          radius: 60,
                          backgroundColor: Color(0xFF1A1A2E),
                          child: Icon(Icons.person_rounded, size: 64, color: Color(0xFF6C63FF)),
                        ),
                      ),
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50), shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0F0F1A), width: 3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Name & Badge ──
                  Text(profile.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3EC6E0)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(profile.role, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 36),

                  // ── Section Divider ──
                  const _SectionDivider(label: 'CONTACT'),
                  const SizedBox(height: 12),

                  // ── Contact Tiles ──
                  ...profile.contacts.map((item) => Card(
                    color: const Color(0xFF1A1A2E),
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Icon(item.icon, color: const Color(0xFF6C63FF), size: 20),
                      ),
                      title: Text(item.label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                      subtitle: Text(item.value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      trailing: item.url != null ? const Icon(Icons.open_in_new_rounded, color: Color(0xFF3EC6E0), size: 18) : null,
                      onTap: item.url != null ? () => _launchURL(item.url!) : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                  )),
                  const SizedBox(height: 28),

                  // ── Reveal Button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleAboutMe,
                      icon: AnimatedRotation(
                        turns: _aboutMeVisible ? 0.5 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: const Icon(Icons.expand_more_rounded),
                      ),
                      label: Text(_aboutMeVisible ? 'Hide About Me' : 'Show About Me'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  // ── About Me (hidden section) ──
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: _aboutMeVisible
                        ? FadeTransition(
                            opacity: _fadeAnim,
                            child: Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(children: [
                                    Icon(Icons.auto_awesome_rounded, color: Color(0xFF6C63FF), size: 18),
                                    SizedBox(width: 8),
                                    Text('About Me', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 16, fontWeight: FontWeight.bold)),
                                  ]),
                                  const SizedBox(height: 12),
                                  Text(
                                    profile.aboutMe,
                                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('"Code is craft. Every widget is a brushstroke."',
                                      style: TextStyle(color: Color(0xFF3EC6E0), fontSize: 13, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),

                  // ── Skills ──
                  const _SectionDivider(label: 'SKILLS'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                    children: profile.skills.map<Widget>((skill) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Color(skill.color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Color(skill.color).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(skill.icon, color: Color(skill.color), size: 16),
                          const SizedBox(width: 6),
                          Text(skill.label, style: TextStyle(color: Color(skill.color), fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    const Expanded(child: Divider(color: Colors.white12)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(label, style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
    ),
    const Expanded(child: Divider(color: Colors.white12)),
  ]);
}
