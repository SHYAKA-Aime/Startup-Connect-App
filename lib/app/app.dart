import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

/// Root widget. A [ConsumerWidget] so it can read the router provider — this is
/// what connects Riverpod (state) to go_router (navigation) and Material (UI).
class AluVenturesApp extends ConsumerWidget {
  const AluVenturesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'ALU Ventures',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
