import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../opportunities/domain/opportunity.dart' show kCategories;
import 'startup_controller.dart';
import 'startup_providers.dart';

/// Create-or-edit the founder's startup profile. Doubles as both the initial
/// onboarding step for a new startup account and the "edit" screen later, by
/// prefilling from [myStartupProvider] when a profile already exists.
class StartupSetupScreen extends ConsumerStatefulWidget {
  const StartupSetupScreen({super.key});

  @override
  ConsumerState<StartupSetupScreen> createState() => _StartupSetupScreenState();
}

class _StartupSetupScreenState extends ConsumerState<StartupSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _desc = TextEditingController();
  final _affiliation = TextEditingController();
  final _website = TextEditingController();
  String _category = kCategories.first;
  bool _init = false;

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _desc.dispose();
    _affiliation.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _submit(String? existingId) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(startupControllerProvider.notifier).createOrUpdate(
          existingId: existingId,
          name: _name.text,
          tagline: _tagline.text,
          description: _desc.text,
          category: _category,
          aluAffiliation: _affiliation.text,
          website: _website.text.isEmpty ? null : _website.text,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(existingId == null
            ? 'Startup submitted for ALU verification.'
            : 'Startup profile updated.'),
      ));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${ref.read(startupControllerProvider).error}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(myStartupProvider).valueOrNull;
    final loading = ref.watch(startupControllerProvider).isLoading;

    // Prefill once if editing.
    if (!_init && existing != null) {
      _name.text = existing.name;
      _tagline.text = existing.tagline;
      _desc.text = existing.description;
      _affiliation.text = existing.aluAffiliation;
      _website.text = existing.website ?? '';
      _category = kCategories.contains(existing.category)
          ? existing.category
          : kCategories.first;
      _init = true;
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(existing == null ? 'Set up your startup' : 'Edit startup')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (existing == null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.navy),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'New startups are reviewed by an ALU admin before they '
                        'can post opportunities. This keeps the platform trusted.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            _label('Startup name'),
            TextFormField(
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label('Tagline'),
            TextFormField(
              controller: _tagline,
              decoration: const InputDecoration(
                  hintText: 'One line on what you do'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label('Category'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: [
                for (final c in kCategories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            _label('Description'),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText: 'What is your startup building and why?'),
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? 'Tell us more' : null,
            ),
            const SizedBox(height: 16),
            _label('ALU affiliation / registration reference'),
            TextFormField(
              controller: _affiliation,
              decoration: const InputDecoration(
                  hintText: 'e.g. cohort, programme, or club under which you registered'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required for verification' : null,
            ),
            const SizedBox(height: 16),
            _label('Website (optional)'),
            TextFormField(
              controller: _website,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: loading ? null : () => _submit(existing?.id),
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(existing == null
                      ? 'Submit for verification'
                      : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      );
}
