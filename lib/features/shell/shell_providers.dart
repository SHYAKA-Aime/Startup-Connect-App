import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The selected tab of the student shell. Held in Riverpod (not just local
/// widget state) so other screens — e.g. the Home category shortcuts — can
/// programmatically switch tabs, like tapping "Design" jumping to Explore
/// with the filter pre-applied.
final studentTabProvider = StateProvider<int>((ref) => 0);
