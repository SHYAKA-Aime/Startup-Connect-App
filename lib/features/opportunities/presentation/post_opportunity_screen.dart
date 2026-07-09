import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../startups/presentation/startup_providers.dart';
import '../domain/opportunity.dart';
import 'opportunity_controller.dart';
import 'opportunity_providers.dart';

/// Create or edit an opportunity (prefills from the stream when editing).
class PostOpportunityScreen extends ConsumerStatefulWidget {
  const PostOpportunityScreen({super.key, this.opportunityId});

  final String? opportunityId;

  @override
  ConsumerState<PostOpportunityScreen> createState() =>
      _PostOpportunityScreenState();
}

class _PostOpportunityScreenState
    extends ConsumerState<PostOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _commitment = TextEditingController();
  final _skillInput = TextEditingController();
  final List<String> _skills = [];
  String _category = kCategories.first;
  RoleType _roleType = RoleType.partTime;
  LocationType _locationType = LocationType.onCampus;
  bool _init = false;

  bool get _isEdit => widget.opportunityId != null;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _commitment.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final startup = ref.read(myStartupProvider).valueOrNull;
    if (startup == null) return;

    final ok = await ref.read(opportunityControllerProvider.notifier).save(
          existingId: widget.opportunityId,
          startup: startup,
          title: _title.text,
          description: _desc.text,
          category: _category,
          roleType: _roleType,
          locationType: _locationType,
          commitment: _commitment.text,
          skills: _skills,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Opportunity updated' : 'Opportunity posted')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${ref.read(opportunityControllerProvider).error}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(opportunityControllerProvider).isLoading;

    // Prefill when editing.
    if (_isEdit && !_init) {
      final opp =
          ref.watch(opportunityByIdProvider(widget.opportunityId!)).valueOrNull;
      if (opp != null) {
        _title.text = opp.title;
        _desc.text = opp.description;
        _commitment.text = opp.commitment;
        _skills
          ..clear()
          ..addAll(opp.skillsRequired);
        _category =
            kCategories.contains(opp.category) ? opp.category : kCategories.first;
        _roleType = opp.roleType;
        _locationType = opp.locationType;
        _init = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Edit opportunity' : 'Post opportunity')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _label('Role title'),
            TextFormField(
              controller: _title,
              decoration:
                  const InputDecoration(hintText: 'e.g. Flutter Developer'),
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Required' : null,
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Type'),
                      DropdownButtonFormField<RoleType>(
                        initialValue: _roleType,
                        items: [
                          for (final r in RoleType.values)
                            DropdownMenuItem(value: r, child: Text(r.label)),
                        ],
                        onChanged: (v) =>
                            setState(() => _roleType = v ?? _roleType),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Location'),
                      DropdownButtonFormField<LocationType>(
                        initialValue: _locationType,
                        items: [
                          for (final l in LocationType.values)
                            DropdownMenuItem(value: l, child: Text(l.label)),
                        ],
                        onChanged: (v) =>
                            setState(() => _locationType = v ?? _locationType),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Time commitment'),
            TextFormField(
              controller: _commitment,
              decoration:
                  const InputDecoration(hintText: 'e.g. 8–10 hrs/week'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label('Description'),
            TextFormField(
              controller: _desc,
              maxLines: 5,
              decoration: const InputDecoration(
                  hintText: 'What will the student work on? What will they learn?'),
              validator: (v) =>
                  (v == null || v.trim().length < 20) ? 'Add more detail' : null,
            ),
            const SizedBox(height: 16),
            _label('Skills required'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillInput,
                    onSubmitted: (_) => _addSkill(),
                    decoration:
                        const InputDecoration(hintText: 'e.g. Dart'),
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
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Save changes' : 'Publish opportunity'),
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
