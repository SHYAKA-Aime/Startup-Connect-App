import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Shown only while the router is still deciding where to send the user
/// (auth state / profile still resolving). It never navigates itself — the
/// router's redirect does that the instant state is known.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.navy,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Logo(),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'ALU',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 34,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Ventures',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 14),
        // ALU red accent — brings the second brand colour into the splash.
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
