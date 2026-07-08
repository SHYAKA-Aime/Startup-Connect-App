import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/startup.dart';
import 'startup_providers.dart';

/// The founder's own startup profile tab: identity, verification status and
/// account actions. Mirrors the student profile but framed around the startup.
class StartupProfileScreen extends ConsumerWidget {
  const StartupProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider);
    final startupAsync = ref.watch(myStartupProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          startupAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ErrorView(e),
            data: (startup) {
              if (startup == null) {
                return _NoStartup(onCreate: () => context.push(Routes.startupSetup));
              }
              return _StartupHeader(startup: startup);
            },
          ),
          const SizedBox(height: 20),
          if (startupAsync.valueOrNull != null)
            _MenuItem(
              icon: Icons.edit_outlined,
              label: 'Edit startup profile',
              onTap: () => context.push(Routes.startupSetup),
            ),
          _MenuItem(
            icon: Icons.person_outline,
            label: 'Founder: ${user?.fullName ?? ''}',
            onTap: () {},
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
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}

class _StartupHeader extends StatelessWidget {
  const _StartupHeader({required this.startup});
  final Startup startup;

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (startup.status) {
      VerificationStatus.verified => (AppColors.success, 'Verified by ALU'),
      VerificationStatus.rejected => (AppColors.danger, 'Not verified'),
      VerificationStatus.pending => (AppColors.warning, 'Pending review'),
    };
    return Column(
      children: [
        InitialsAvatar(startup.name, size: 88),
        const SizedBox(height: 12),
        Text(startup.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(startup.tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (startup.isVerified)
              const Icon(Icons.verified, size: 18, color: AppColors.success),
            if (startup.isVerified) const SizedBox(width: 6),
            StatusBadge(text, color),
          ],
        ),
      ],
    );
  }
}

class _NoStartup extends StatelessWidget {
  const _NoStartup({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.rocket_launch_outlined,
            size: 56, color: AppColors.navy),
        const SizedBox(height: 12),
        const Text('No startup profile yet',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 12),
        ElevatedButton(
            onPressed: onCreate, child: const Text('Create startup profile')),
      ],
    );
  }
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
