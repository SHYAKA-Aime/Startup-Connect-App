import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';

/// Lets a student edit their identity and — importantly — their skills, which
/// feed the recommendation engine on Home. Skills are entered as chips so the
/// data stays a clean `List<String>` rather than free text.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _skillInput = TextEditingController();
  late List<String> _skills;
  bool _init = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _headline.dispose();
    _bio.dispose();
    _skillInput.dispose();
    super.dispose();
  }

  void _addSkill() {
    final s = _skillInput.text.trim();
    if (s.isEmpty) return;
    if (!_skills.any((e) => e.toLowerCase() == s.toLowerCase())) {
      setState(() => _skills.add(s));
    }
    _skillInput.clear();
  }

  Future<void> _save() async {
    final user = ref.read(appUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    final updated = user.copyWith(
      fullName: _name.text.trim(),
      headline: _headline.text.trim(),
      bio: _bio.text.trim(),
      skills: _skills,
    );
    try {
      await ref.read(authRepositoryProvider).updateProfile(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Seed controllers once from the loaded profile.
    if (!_init) {
      _name.text = user.fullName;
      _headline.text = user.headline;
      _bio.text = user.bio;
      _skills = [...user.skills];
      _init = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _label('Full name'),
          TextField(controller: _name),
          const SizedBox(height: 16),
          _label('Headline'),
          TextField(
            controller: _headline,
            decoration: const InputDecoration(
                hintText: 'e.g. Year 3 Software Engineering student'),
          ),
          const SizedBox(height: 16),
          _label('Bio'),
          TextField(
            controller: _bio,
            maxLines: 4,
            decoration:
                const InputDecoration(hintText: 'A short intro about you'),
          ),
          const SizedBox(height: 16),
          _label('Skills (power your recommendations)'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillInput,
                  onSubmitted: (_) => _addSkill(),
                  decoration:
                      const InputDecoration(hintText: 'e.g. Flutter'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addSkill,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    minimumSize: const Size(52, 52)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _skills)
                InputChip(
                  label: Text(s),
                  onDeleted: () => setState(() => _skills.remove(s)),
                ),
            ],
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      );
}
