import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';

/// Création ou édition d'un profil (nom + avatar).
class ProfileEditScreen extends StatefulWidget {
  final Profile? profile;
  final ProfileService? profileService;

  const ProfileEditScreen({super.key, this.profile, this.profileService});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  late int _avatarId;
  bool get _isNew => widget.profile == null;

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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _avatarId = widget.profile?.avatarId ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entre un prénom.")),
      );
      return;
    }
    if (_isNew) {
      if (!mounted) return;
      Navigator.of(context).pop({'name': name, 'avatarId': _avatarId});
    } else {
      widget.profile!.name = name;
      widget.profile!.avatarId = _avatarId;
      await widget.profile!.save();
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer ce profil ?"),
        content: const Text(
          "Toute la progression de ce profil sera effacée. Cette action est irréversible.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && mounted && widget.profile != null && widget.profileService != null) {
      await widget.profileService!.deleteProfile(widget.profile!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? "Nouveau profil" : "Modifier le profil"),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  "Prénom",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Ex. Léa",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Avatar",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(_avatars.length, (i) {
                    final selected = i == _avatarId;
                    return GestureDetector(
                      onTap: () => setState(() => _avatarId = i),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: selected ? Colors.blue : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.blue : Colors.grey.shade300,
                            width: selected ? 3 : 1,
                          ),
                        ),
                        child: Icon(
                          _avatars[i],
                          size: 32,
                          color: selected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006064),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_isNew ? "Créer le profil" : "Enregistrer"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
