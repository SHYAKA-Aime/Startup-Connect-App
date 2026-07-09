import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../../applications/domain/application.dart';
import '../../applications/presentation/application_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import 'widgets/saved_opportunities_sheet.dart';

/// Student profile: identity, live application stats, and account actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider);
    final apps = ref.watch(myApplicationsProvider).valueOrNull ?? const [];

    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final shortlisted =
        apps.where((a) => a.status == ApplicationStatus.shortlisted).length;
    final accepted =
        apps.where((a) => a.status == ApplicationStatus.accepted).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(
            child: Column(
              children: [
                InitialsAvatar(user.fullName, size: 88),
                const SizedBox(height: 12),
                Text(user.fullName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                    user.headline.isEmpty
                        ? 'ALU Student'
                        : user.headline,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SoftCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('${apps.length}', 'Applications'),
                _divider(),
                _stat('$shortlisted', 'Shortlisted'),
                _divider(),
                _stat('$accepted', 'Accepted'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MenuItem(
            icon: Icons.person_outline,
            label: 'Edit profile & skills',
            onTap: () => context.push(Routes.editProfile),
          ),
          _MenuItem(
            icon: Icons.bookmark_outline,
            label: 'Saved opportunities',
            onTap: () => showSavedOpportunitiesSheet(context),
          ),
          if (user.isAdmin)
            _MenuItem(
              icon: Icons.verified_outlined,
              label: 'Startup verification (Admin)',
              onTap: () => context.push(Routes.adminVerify),
            ),
          _MenuItem(
            icon: Icons.help_outline,
            label: 'Help & support',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact ventures@alustudent.com')),
            ),
          ),
          const SizedBox(height: 8),
          _MenuItem(
            icon: Icons.logout,
            label: 'Log out',
            color: AppColors.danger,
            onTap: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      );

  Widget _divider() =>
      Container(width: 1, height: 34, color: AppColors.border);
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            side: const BorderSide(color: AppColors.border),
          ),
          leading: Icon(icon, color: c),
          title: Text(label,
              style: TextStyle(fontWeight: FontWeight.w600, color: c)),
          trailing:
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onTap: onTap,
        ),
      ),
    );
  }
}
