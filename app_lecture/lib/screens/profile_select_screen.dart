import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';
import 'profile_edit_screen.dart';
import 'home_screen.dart';

/// Écran de choix du profil (premier lancement ou depuis paramètres).
class ProfileSelectScreen extends StatefulWidget {
  /// Si true, on vient des paramètres : après sélection on revient en arrière.
  final bool fromSettings;

  const ProfileSelectScreen({super.key, this.fromSettings = false});

  @override
  State<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends State<ProfileSelectScreen> {
  final ProfileService _profileService = ProfileService.instance;
  List<Profile> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _profileService.ensureOpen();
    setState(() {
      _profiles = _profileService.getProfiles();
      _loading = false;
    });
  }

  Future<void> _selectProfile(Profile profile) async {
    await _profileService.setCurrentProfile(profile.keyAsId);
    if (!mounted) return;
    if (widget.fromSettings) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _addProfile() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => const ProfileEditScreen(profile: null),
      ),
    );
    if (result != null && result['name'] != null) {
      final p = await _profileService.addProfile(
        name: result['name'] as String,
        avatarId: result['avatarId'] as int? ?? 0,
      );
      await _profileService.setCurrentProfile(p.keyAsId);
      if (!mounted) return;
      if (widget.fromSettings) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      widget.fromSettings ? "Changer de profil" : "Qui joue ?",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006064),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: _profiles.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Aucun profil.\nCrée le premier !",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 18, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 24),
                                    _buildAddButton(),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: _profiles.length + 1,
                              itemBuilder: (context, i) {
                                if (i == _profiles.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                                    child: _buildAddButton(),
                                  );
                                }
                                final p = _profiles[i];
                                return _ProfileCard(
                                  profile: p,
                                  onTap: () => _selectProfile(p),
                                  onEdit: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProfileEditScreen(profile: p, profileService: _profileService),
                                      ),
                                    );
                                    _load();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return OutlinedButton.icon(
      onPressed: _addProfile,
      icon: const Icon(Icons.add_circle_outline),
      label: const Text("Ajouter un profil"),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF006064),
        side: const BorderSide(color: Color(0xFF006064)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.profile,
    required this.onTap,
    required this.onEdit,
  });

  static const List<IconData> _avatars = [
    Icons.face,
    Icons.face_2,
    Icons.face_3,
    Icons.child_care,
    Icons.emoji_emotions,
    Icons.person,
    Icons.person_outline,
    Icons.star,
  ];

  @override
  Widget build(BuildContext context) {
    final avatarIndex = profile.avatarId.clamp(0, _avatars.length - 1);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.shade100,
                child: Icon(_avatars[avatarIndex], size: 36, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  profile.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
